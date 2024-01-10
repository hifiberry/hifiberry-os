#!/bin/bash

ACTION="$1"
if [[ -z ${ACTION} ]]; then
 exit 1
fi

DEV="/dev/sr*"
MPC="/usr/bin/mpc"

do_mount() {
	NUM_TRACK=$(/usr/bin/udevadm info --query=property ${DEV} | /bin/grep ID_CDROM_MEDIA_TRACK_COUNT_AUDIO | /usr/bin/awk -F= '{ print $2 }')
	/bin/echo "cd with ${NUM_TRACK} tracks detected"
 
	/bin/echo "clearing mpd queue"
	${MPC} clear

	for i in $(/usr/bin/seq 1 ${NUM_TRACK}); do
		${MPC} add cdda:///${i}
	done

	${MPC} play
}

do_unmount() {
	${MPC} -f "%position% %file%" playlist | /bin/grep cdda:// | /usr/bin/awk '{ print $1 }' | ${MPC} del
}

case "${ACTION}" in
	add)
	do_mount
	;;
	remove)
	do_unmount
	;;
esac
