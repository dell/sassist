This is 'sassist', Dell SupportAssist log collector agent for Linux.

## What is 'sassist'?
Dell SupportAssist embedded in Dell iDRAC helps with troubleshooting/debugging issues with Dell PowerEdge Server hardware/OS.

'sassist' is an agent that runs on the Linux Operating System to work with Dell iDRAC enabling log and configuration collection. It uses native log/configuration collection tools like [sos](https://github.com/sosreport/sos) and [supportconfig](https://www.suse.com/c/free_tools/supportconfig-linux/) available in popular Linux distributions.

'sassist' requires Dell [iDRAC 9](https://www.dell.com/support/article/us/en/19/sln308699/idrac-9-versions-and-release-notes) or later.

## Working
 - User initiates SupportAssist Collection from Dell iDRAC through any
	of the available interfaces (Web UI, wsman, redfish, racadm)
 - 'sassist' collects system logs/configuration and packages it for use by Dell iDRAC.
 - Dell iDRAC aggregates OS/firmware/hardware logs and makes it available via the requested method.

## Download
- 'sassist' is available in Fedora 29, openSUSE Leap 15.4 and Tumbleweed. It can be installed from the default repository. On SUSE Linux Enterprise Server 15 SP4 it is available via [SUSE PackageHub](https://packagehub.suse.com/packages/sassist/).
- Pre-built packages for RHEL (CentOS, Fedora) and SLES (OpenSUSE) based distributions are available [here](https://github.com/dell/sassist/releases)

## Build
### rpm:
- Download the [tarball](https://github.com/dell/sassist/releases/latest).
- `tar xf <VERSION>.tar.gz`
- `make`

### deb:
- TODO

## Installation:
- Install package
  - `$ sudo yum install sassist-<version>.rpm`

  OR
  - `$ sudo zypper in sassist-<version>.rpm`
- Start sassist
  - `$ sudo systemctl enable --now sassist`

## Usage:
### Create a SupportAssist collection from Dell racadm cli:
- `racadm supportassist accepteula`
- `racadm supportassist collect -t sysinfo,osAppAll -f <REPORT_LOCATION>`
- Report will be saved in REPORT_LOCATION
- More details [here](https://www.dell.com/support/manuals/us/en/04/idrac9-lifecycle-controller-v3.00.00.00/idrac_3.00.00.00_racadm/supportassist?guid=guid-c7de9746-8581-4994-8dfe-1804237a10e3&lang=en-us)

### Create a SupportAssist collection from Dell iDRAC Web UI:
- Navigate to Maintenance -> SupportAssist
- At the “SupportAssist Registration” screen, click "Cancel" (The support to automatically/periodically collect and upload logs to Dell Support sites is still not available with ‘sassist’. Until then, the log collection can only be initiated manually).
- Click “Start a Collection”
- Check “OS and Application Data” and click “Collect”
- Accept EULA and click “Continue”
- Monitor Progress. The process would take a couple of minutes.
- On completion, click “Ok” and save the “zip” archive. This can be used for analysis/debugging.
- More details [here](https://www.dell.com/support/article/dm/en/dmdhs1/sln306670/how-to-manually-create-the-supportassist-collection-with-idrac-9-?lang=en)

## Notes
- Do not run SupportAssist Collection while updating system firmware components with [Dell DSU](https://linux.dell.com/repo/hardware/dsu/).

Send patches and suggestions to the following mailing list with "sassist: " in the subject line:
[mailing list](https://lists.us.dell.com/mailman/listinfo/linux-poweredge)
