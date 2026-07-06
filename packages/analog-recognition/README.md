# analog-recognition

Builds `hifiberry-analog-recognition` from
[github.com/hifiberry/analog-recognition](https://github.com/hifiberry/analog-recognition).

Analog-input song recognition (songrec) plus VU-meter-based play/stop state,
published into AudioControl as a generic player named `analog`.

The package registers itself as a HiFiBerryOS player plugin from its
`postinst` (webui `players.d`, configserver permission, ACR `players.d`), so it
appears under "3rd Party Players" in the web UI with an enable/disable toggle
and a "Recognize tracks" (songrec) setting. Runs as a `--user` systemd service.

`build.sh` clones the upstream repo (tracking `main`) and builds with sbuild;
the upstream repo ships its own `debian/`, so there is no local overlay here.
