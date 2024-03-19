#!/bin/sh

MODE="NOT_SET"
FILE="NOT_SET"
TYPE="NOT_SET"

usage()
{
	echo "eepflash: Writes or reads .eep binary image to/from HAT EEPROM on a Raspberry Pi"
	echo ""
	echo "./eepflash.sh"
	echo "	-h --help: display this help message"
	echo "	-r --read: read .eep from the eeprom"
	echo "	-w --write: write .eep to the eeprom"
	echo "	-f=file_name --file=file_name: binary .eep file to read to/from"
	echo "	-t=eeprom_type --type=eeprom_type: eeprom type to use"
	echo "		We support the following eeprom types:"
	echo "		-24c32"
	echo "		-24c64"
	echo "		-24c128"
	echo "		-24c256"
	echo "		-24c512"
	echo "		-24c1024"
	echo ""
}

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

ADDRESS=50
 
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
	case $PARAM in
		-h | --help)
			usage
			exit
			;;
		-r | --read)
			MODE="read"
			;;
		-w | --write)
			MODE="write"
			;;
                --writeread)
                        MODE="writeread"
                        ;;
		-t | --type)
			if [ "$VALUE" = "24c32" ] || [ "$VALUE" = "24c64" ] || [ "$VALUE" = "24c128" ] ||
				[ "$VALUE" = "24c256" ] || [ "$VALUE" = "24c512" ] || [ "$VALUE" = "24c1024" ]; then
					TYPE=$VALUE
			else
				echo "ERROR: Unrecognised eeprom type. Try -h for help"
				exit 1
			fi
			;;
		-f | --file)
			FILE=$VALUE
			;;
	        -a | --address)
			ADDRESS=$VALUE
			;;
		*)
			echo "ERROR: unknown parameter \"$PARAM\""
			usage
			exit 1
			;;
    esac
    shift
done
 
if [ "$MODE" = "NOT_SET" ]; then
	echo "You need to set mode (read or write). Try -h for help."
	exit 1
elif [ "$FILE"  = "NOT_SET" ]; then
	echo "You need to set binary .eep file to read to/from. Try -h for help."
	exit 1
elif [ "$TYPE" = "NOT_SET" ]; then
	echo "You need to set eeprom type. Try -h for help."
	exit 1
fi

echo "This script comes with ABSOLUTELY no warranty. Continue only if you know what you are doing."

modprobe i2c_dev
#dtoverlay i2c-gpio i2c_gpio_sda=0 i2c_gpio_scl=1
rc=$?
if [ $rc != 0 ]; then
	echo "Loading of i2c-gpio dtoverlay failed. Do an rpi-update (and maybe apt-get update; apt-get upgrade)."
	exit $rc
fi
modprobe at24
rc=$?

# Bus number is not fixed, correct I2C adapter is iden
for i in $(seq 1 30); do
  if [ -d /sys/class/i2c-adapter/i2c-$i ]; then
    I2C=`ls -l /sys/class/i2c-adapter/i2c-$i | grep "platform/ffff"`
    if [ "$I2C" != "" ]; then 
      DEVID=$i
      break
    fi
  fi
done


if [ $rc != 0 ]; then
	echo "Modprobe of at24 failed. Do an rpi-update."
	exit $rc
fi

if [ ! -d "/sys/class/i2c-adapter/i2c-$DEVID/$DEVID-00$ADDRESS" ]; then
	echo "$TYPE 0x$ADDRESS" > /sys/class/i2c-adapter/i2c-$DEVID/new_device
fi


if [ "$MODE" = "write" ]
 then
	echo "Writing..."
	dd if=$FILE of=/sys/class/i2c-adapter/i2c-$DEVID/$DEVID-00$ADDRESS/eeprom
	rc=$?
elif [ "$MODE" = "read" ]
 then
	echo "Reading..."
	dd if=/sys/class/i2c-adapter/i2c-$DEVID/$DEVID-00$ADDRESS/eeprom of=$FILE
	rc=$?
elif [ "$MODE" = "writeread" ]
 then
        echo "Writing..."
        dd if=$FILE of=/sys/class/i2c-adapter/i2c-$DEVID/$DEVID-00$ADDRESS/eeprom
        dd if=/sys/class/i2c-adapter/i2c-$DEVID/$DEVID-00$ADDRESS/eeprom of=/tmp/eeprom.$$
        SIZEORIG=`wc -c $FILE | awk '{print $1}'`
        truncate -s $SIZEORIG /tmp/eeprom.$$
        diff $FILE /tmp/eeprom.$$
        rc=$?
fi

if [ $rc != 0 ]; then
	echo "Error doing I/O operation."
	exit $rc
else
	echo "Done."
fi
