#!/usr/bin/env bash

ACTION="$1"
if [[ -z ${ACTION} ]]; then
	exit 1
fi

MPC="/usr/bin/mpc"
WRITE_CD_XSPF="/usr/bin/write-cd-xspf"
XSPF_PATH="/library/music/playlists/cd.xspf"

do_mount() {
	/bin/echo "fetching metadata"
	${WRITE_CD_XSPF}

	/bin/echo "loading playlist into mpd"
	${MPC} update -w
	${MPC} clear
	${MPC} load ${XSPF_PATH}

	${MPC} play
}

do_unmount() {
	${MPC} stop
	${MPC} clear
	/bin/rm ${XSPF_PATH}
	${MPC} update
}

case "${ACTION}" in
add)
	do_mount
	;;
remove)
	do_unmount
	;;
esac
