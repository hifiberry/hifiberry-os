# Configuring WiFi

Create a file named wpa_supplicant.conf on the FAT partition of the SD card as follows:

    ctrl_interface=/var/run/wpa_supplicant
    ap_scan=1

    network={
        ssid="my_network_name"
        psk="my_network_password"
    }
    
If the system can connect to the network on boot, you should hear the system saying the IP address assigned to it by DHCP.

If you run a WiFi-only setup, it is recommended to remove the eth0 block from /etc/network/interfaces. This will speed up
the boot process as the system won't try to configure the Ethernet interface.
