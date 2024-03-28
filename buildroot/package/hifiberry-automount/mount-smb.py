#!/bin/python

import os
import subprocess

# Define the base directory
base_dir = "/data/library/music"

# Read and process smbmounts.conf
with open("/etc/smbmounts.conf", "r") as f:
    for line in f:
        if not line.startswith("#"):
            parts = line.strip().split(";")
            if len(parts)<4:
                continue
            # Adjust unpacking to handle optional mount_opts
            mount_id, share, user, password, *rest = parts[:5] + [""] * (5 - len(parts))
            print(share)
            mount_opts = rest[0].strip() or "rw" if rest else "rw"

            # Ensure mount directory exists
            mount_dir = os.path.join(base_dir, mount_id)
            os.makedirs(mount_dir, exist_ok=True)

            # Resolve .local hostnames
            host = share.split('/')[2]
            ip = ""
            if host.endswith(".local"):
                result = subprocess.run(["avahi-resolve-host-name", "-4", host], stdout=subprocess.PIPE)
                ip = result.stdout.decode().split()[1].strip() if result.returncode == 0 else ""

            # Try to resolve using nmblookup
            if not ip:
                tmp_file = f"/tmp/{os.getpid()}"
                with open(tmp_file, "w+") as tmp_f:
                    subprocess.run(["nmblookup", host], stdout=tmp_f)
                    tmp_f.seek(0)
                    output = tmp_f.read()
                    if "0" in output:
                        ip = output.split()[-1]

            # Replace host in share with IP if resolved
            if ip:
                share = share.replace(host, ip)

            # Prepare and execute the mount command
            mount_cmd = f"mount -t cifs -o user={user},password={password},{mount_opts} {share} {mount_dir}"
            print(mount_cmd)
            subprocess.run(mount_cmd, shell=True)

            # Report activation
            if os.access("/opt/hifiberry/bin/report-activation", os.X_OK):
                subprocess.run(["/opt/hifiberry/bin/report-activation", "mount_smb"])

