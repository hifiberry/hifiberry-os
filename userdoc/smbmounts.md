# Edit Samba mounts

If adding SAMBA shares via the UI isn't working correctly, you can tweak mount options of SAMBA shares via the /etc/smbmounts.conf file.

The format is as follows:
```
id;smbshare;user;password;mount-options
```
e.g.
```
1;\\192.168.99.1\music;music;music;vers=2
```

Id is just any unique ID you want to give to this share.

After editing the file, run
```
/opt/hifiberry/bin/mount-smb.sh
```
