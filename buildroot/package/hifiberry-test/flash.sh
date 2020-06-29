#!/bin/bash

GPIO_DRIVER_LOADED=`cat /boot/config.txt | grep i2c-gpio`

if [ "$GPIO_DRIVER_LOADED" == "" ]; then
  mount -o remount,rw /boot 
  echo "Need to modify config.txt and reboot"
  echo "dtoverlay=i2c-gpio" >> /boot/config.txt
  echo "dtparam=i2c_gpio_sda=0" >> /boot/config.txt
  echo "dtparam=i2c_gpio_scl=1" >> /boot/config.txt
  echo "Rebooting in 5 seconds"
  sync
  sleep 5
  reboot
fi

if [ -f "/opt/hifiberry/contrib/$1.eep" ]; then 
  /opt/hifiberry/contrib/hbflash.sh -w -f=/opt/hifiberry/contrib/$1.eep -t=24c32
else
  echo "EEPROM file /opt/hifiberry/contrib/$1.eep does not exist, aborting ..."
  exit 1
fi

exit 0
# Leave config.txt as it is for now
echo "Cleaning up /boot/config.txt again"
cat /boot/config.txt | grep -v i2c_gpio | grep -v i2c-gpio > /tmp/x.conf
mv /tmp/x.conf /boot/config.txt
echo "Rebooting in 5 seconds"
sync
sleep 5
reboot

