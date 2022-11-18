# Enabling power management

Sound card power management sometimes creates problems with some devices (e.g. pop sounds). Therefore, HiFiBerryOS completely disables power management 
for audio devices (the impact on overall power consumption is negligible).

If you want to re-enable it for some reason, you can edit the file /etc/modprobe.d/snd_soc_core_disable_pm.conf
