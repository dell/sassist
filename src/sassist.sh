#!/bin/sh
#
# sassist.sh
#
# Export sosreport to Dell PowerEdge Server iDRAC for out-of-band access.
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
SOS_PLUGINS="grub2,iscsi,cman,pacemaker,named"
SOS_PROFILES="system,storage,network,hardware,services"
SCONFIG_PLUGINS="BOOT,BTRFS,CRASH,DISK,IB,ISCSI,LVM,MEM,MOD,MPIO,NET,SRAID,SYSCONFIG,SYSFS,UDEV,X"
SOSREPORT="/usr/sbin/sosreport"
SUPPORTCONFIG="/sbin/supportconfig"

#--------------------------------------------------------------
ipmi()
{
	RET=$(/usr/sbin/ipmi-raw 0 30 a8 $@ | awk '{print $4}')
	if [ $? -eq 0 -a "$RET" -ne 1 ]; then
		return 0
	fi
	return 1
}

sa_can_filter="ipmi 0 1 3 0 0"
sa_cannot_filter="ipmi 0 1 1 0 0"
sa_started="ipmi 1 0 0"
sa_end_full="ipmi 2 0 3"
sa_end_partial="ipmi 2 1 3"
sa_do_close="ipmi 2 2 0"
sa_do_fail="ipmi 2 3 0"

can_do_sassist()
{
	$sa_cannot_filter
}

# Run sosreport and zip results
do_sosreport()
{
	$SOSREPORT --batch -o ${SOS_PLUGINS} -p ${SOS_PROFILES}\
		--tmp-dir ${TMP_DIR} --build --quiet \
		--name ${SVCTAG} || return 1

	find ${TMP_DIR} -type s -exec rm -f '{}' \;
	$(cd ${TMP_DIR}/sosreport-* && zip -y -q -r ${OUTFILE_F} . )
}

# Run supportconfig and zip results
do_supportconfig()
{
	$SUPPORTCONFIG -Q -d -k -t ${TMP_DIR} \
		-i ${SCONFIG_PLUGINS} -B ${SVCTAG} || return 1

	$(cd ${TMP_DIR}/*_${SVCTAG} && zip -q -r ${OUTFILE_F} . )
}

do_report()
{
	TMP_DIR=$(mktemp -d)
	SVCTAG=$(cat /sys/devices/virtual/dmi/id/product_serial)
	OUTFILE_F="${TMP_DIR}/OSC-FR-Report-${SVCTAG}.zip"

	if $(findmnt | grep -q "$MEDIA_DIR") && ! $sa_started; then
		RETVAL=3
		do_stop
	fi

	if [ -x "$SOSREPORT" ]; then
		do_sosreport >/dev/null 2>&1
	elif [ -x "$SUPPORTCONFIG" ]; then
		do_supportconfig >/dev/null 2>&1
	else
		RETVAL=5
		do_stop
	fi

	if [ $? -ne 0 ]; then
		RETVAL=6
		do_stop
	fi

	SHA_F=$(sha256sum ${OUTFILE_F}| cut -d' ' -f1| sed 's/.\{2\}/& /g')

	cp -f ${TMP_DIR}/OSC-*zip ${MEDIA_DIR}/ >/dev/null 2>&1
	umount -r ${MEDIA_DIR}
	if [ $? -ne 0 ]; then
		RETVAL=1
		do_stop
	fi

	# Close connection with checksum
	$sa_end_full "${SHA_F}"
	if [ $? -ne 0 ]; then
		RETVAL=1
	fi
	do_stop
}

do_stop()
{
	if [ $RETVAL -eq 0 ]; then
		$sa_do_close
	else
		$sa_do_fail
	fi
	rm -rf ${TMP_DIR}
	exit $RETVAL
}

# Main
RETVAL=0

case $1 in
	enable)
		can_do_sassist
	;;
	start)
		do_report
	;;
	stop)
		do_stop
	;;
	*)
		printf "Usage: %s <enable|start|stop>\n" $0
		exit 0
	;;
esac
