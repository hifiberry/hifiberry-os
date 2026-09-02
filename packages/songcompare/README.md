# songcompare

Builds `hifiberry-songcompare` from
[github.com/hifiberry/songcompare](https://github.com/hifiberry/songcompare).

Interactive A/B comparison of different renderings of the same recording:
lossy against lossless, one master against another, a filter change against
the unprocessed source. It level-matches the files, optionally aligns them by
cross-correlation, and crossfades the switch so only the difference under test
is audible. An anonymous mode hides the filenames until the comparison ends.

The package installs a single binary, `/usr/bin/songcompare`. It is a
listening-test tool run by hand, not a service, so it is in no `hbos-*`
meta-package; install it on demand.

`build.sh` clones the upstream repo (tracking `master`) and builds with sbuild;
the upstream repo ships its own `debian/`, so there is no local overlay here.
The build needs network access because cargo fetches the crate dependencies.
