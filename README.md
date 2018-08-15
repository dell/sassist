This is sassist, Dell SupportAssist log collector for Linux.

## What is sassist?
Dell SupportAssist helps with troubleshooting/debugging issues with
Dell PowerEdge Server hardware/OS.

'sassist' assists Dell iDRAC by collecting OS configuration and logs and saving it to iDRAC. it uses native log collection tools like sos and supportconfig depending on the distribution.

'sassist' works with Dell [iDRAC 9](https://www.dell.com/support/article/us/en/19/sln308699/idrac-9-versions-and-release-notes) and later.

This package contains the following files:
 - sassist.sh
	helper script called by sassist.service and sassist-enable.service.
 - systemd/sassist.service
	run at system start-up to enable SupportAssist functionality
	in Dell iDRAC.
 - systemd/media-NATOSC.mount
	mount NATOSC automatically and call sassist.service.
 - systemd/sassist-collect.service
	invoked by media-NATOSC to do the log collection.
 - sassist.spec
	RPM spec file.

## Working
Here is the typical usage/flow:
 - User initiates SupportAssist log collection from Dell iDRAC through any
	of the available interfaces (Web UI, wsman, redfish, racadm)
 - USB Block device is exposed to the OS.
 - systemd mounts it and calls sassist.service
 - sassist.service collects OS logs with sosreport/supportutil
 - After collection, sassist.service unmounts the block device and signals
	log collection to Dell iDRAC.
 - Dell iDRAC aggregates OS and hardware logs and presents to user.

## Build
### RPM:
- Copy sassist.spec to $RPMBUILD/SPEC directory
- Create sassist-<version>.tar.gz in $RPMBUILD/SOURCES directory
- `rpmbuild -ba $RPMBUILD/SPEC/sassist.spec`

### DEB:
- TODO

### Travis:
- Travis builds are available [here](https://github.com/dell/sassist/releases)

## Installation:
- Install package
	`$ sudo yum install sassist`
		OR
	`$ sudo zypper in sassist`
- `$ sudo systemctl enable --now sassist`

Send patches and suggestions to the following mailing list with "sassist:" in the subject line:
[mailing list](https://lists.us.dell.com/mailman/listinfo/linux-poweredge)
