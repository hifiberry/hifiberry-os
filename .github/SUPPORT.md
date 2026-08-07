# Getting help

## Questions, setup problems, hardware advice

Please use [HiFiBerry support](https://support.hifiberry.com). The issue
tracker is for reproducible defects and feature requests in HiFiBerryOS, not
for individual support cases.

## Reporting a bug

Open a [bug report](https://github.com/hifiberry/hifiberry-os/issues/new?template=01-bug-report.yml).
The form asks for the output of:

```
config-supportinfo
```

That command ships with `hifiberry-configurator` and collects the hardware,
package versions, service state and recent errors we need. It removes
passwords, keys and tokens before printing, and it does not include your
device UUID or hostname.

## A note on older HiFiBerryOS versions

HiFiBerryOS has been rewritten and is now based on Debian. Issues about the
older, Buildroot-based images cannot be carried over and are closed as
outdated. If you still see a problem on the current version, please open a new
bug report.
