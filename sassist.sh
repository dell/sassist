#!/bin/sh
#
# sassist.sh
#
# Export sosreport to Dell PowerEdge Server iDRAC for out-of-band access.
#
# v0.7.0
#
# Usage:
#	Invoked by sassist.service when SupportAssist USB block device
#	is attached.
#
#
# Copyright 2017 Charles Rose, Dell Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.


# User configurable options
SOS_PLUGINS="block,boot,devices,devicemapper,dmraid,filesys,firewalld,\
general,grub2,hardware,kernel,kvm,last,logs,lsbrelease,lvm2,md,\
megacli,memory,multipath,networking,pci,process,rpm,services,\
scsi,systemd,sysvipc,teamd,usb,udev,x11,xfs"
SCONFIG_PLUGINS="BOOT,BTRFS,CRASH,DISK,IB,ISCSI,LVM,MEM,MOD,MPIO,NET,SRAID,SYSCONFIG,SYSFS,UDEV,X"
SOS_OPTIONS="services.servicestatus=on"
sos_cleaner="/usr/bin/soscleaner"
#--------------------------------------------------------------
ipmi()
{
	OUT=$(/usr/sbin/ipmi-raw 0 30 a8 $@)
	if [ $? -eq 0 ]; then
		return $(printf "$OUT"| cut -c14)
	fi
	return 1
}

can_filter="ipmi 0 1 3 0 0"
cannot_filter="ipmi 0 1 1 0 0"
supported="ipmi 1 0 0"
end_full="ipmi 2 0 3"
end_partial="ipmi 2 1 3"
do_close="ipmi 2 2 0"
do_fail="ipmi 2 3 0"

SVCTAG=$(cat /sys/devices/virtual/dmi/id/product_serial)
OUTFILE_F="${TMP_DIR}/OSC-FR-Report-${SVCTAG}.zip"
# Partial Report - TODO
OUTFILE_P="${TMP_DIR}/OSC-PR-Report-${SVCTAG}.zip"
TMP_DIR=$(mktemp -d)

can_do_sassist()
{
	#TODO: until tools like soscleaner become in-distro
	$cannot_filter
	return $?
}

# Run sosreport and zip results
do_sosreport()
{
	/usr/sbin/sosreport --batch -o ${SOS_PLUGINS} -k ${SOS_OPTIONS}\
		--tmp-dir ${TMP_DIR} --build --quiet \
		--name ${SVCTAG}
	# Windows does not like some filenames
	find ${TMP_DIR} -name "modinfo_*" -execdir mv '{}' modinfo \;
	find ${TMP_DIR} -name "find_*" -execdir rm -r '{}' \;
	find ${TMP_DIR} -name "*:*" -execdir rm -rf '{}' \;

	$(cd ${TMP_DIR}/sosreport-*; zip -y -q -r ${OUTFILE_F} . )
}

# Run supportconfig and zip results
do_supportconfig()
{
	/sbin/supportconfig -Q -d -k -t ${TMP_DIR} \
		-i ${SCONFIG_PLUGINS} -B ${SVCTAG}
	$(cd ${TMP_DIR}/nts_${SVCTAG}; zip -q -r ${OUTFILE_F} . )
}

do_report()
{
	if $(findmnt | grep -q "$MEDIA_DIR") && ! $supported; then
		$do_fail
	fi

	if [ -x /usr/sbin/sosreport ]; then
		do_sosreport >/dev/null 2>&1
	elif [ -x /sbin/supportconfig ]; then
		do_supportconfig >/dev/null 2>&1
	else
		do_stop
	fi

	SHA_F=$(sha256sum ${OUTFILE_F}| cut -d' ' -f1| sed 's/.\{2\}/& /g')

	cp -f ${TMP_DIR}/OSC-*zip ${MEDIA_DIR}/ >/dev/null 2>&1
	umount -r ${MEDIA_DIR}
	rm -rf ${TMP_DIR}

	# Close connection with checksum
	$end_full "${SHA_F}"
	$do_close
}

do_stop()
{
	$do_close
	$do_fail
}

# Main
case $1 in
	enable)
		can_do_sassist
		exit $?
	;;
	start)
		can_do_sassist && \
		do_report
		exit $?
	;;
	stop)
		do_stop
	;;
	*)
		printf "Usage: %s <enable|start|stop>\n" $0
		exit 0
	;;
esac
