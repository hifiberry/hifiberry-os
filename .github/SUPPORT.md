# Getting help

## Questions, setup problems, hardware advice

Please use [HiFiBerry support](https://support.hifiberry.com/forum/c/software).
The issue tracker is for reproducible defects and feature requests in
HiFiBerryOS, not for individual support cases.

## Reporting a bug

Open a [bug report](https://github.com/hifiberry/hifiberry-os/issues/new?template=01-bug-report.yml).
The form asks for the output of:

```
config-supportinfo
```

If the command is not found, update the package first:

```
sudo apt update && sudo apt install --only-upgrade hifiberry-configurator
```

That command ships with `hifiberry-configurator` and collects the hardware,
package versions, service state and recent errors we need. It removes
passwords, keys and tokens before printing, and it does not include your
device UUID or hostname — review the output before posting it anyway.

No terminal access? The same report is available from the web interface,
under Settings → System Tools → Support Report. It shows the report on the
page for copying, and a "Download as file" button saves it so you can attach
it to the issue directly. Since the endpoint is authenticated, you will be
asked for the device password.

## A note on older HiFiBerryOS versions

HiFiBerryOS has been rewritten and is now based on Debian. Issues about the
older, Buildroot-based images cannot be carried over and are closed as
outdated. If you still see a problem on the current version, please open a new
bug report.
