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

can_do_sassist()
{
	if [ -x "$sos_cleaner" ]; then
		FILTER="yes"
		$can_filter
	else
		FILTER="no"
		$cannot_filter
	fi
	return $?
}

# prepare <input_file> <output_file>
prepare()
{
	DIR=$(dirname ${1})
	SRC=$(basename ${2} .zip)
	TEMP="${DIR}/${SRC}"

	mkdir ${TEMP}
	tar --strip-components=1 -xf ${1} -C ${TEMP}

	# Windows does not like long filenames
	find ${TEMP} -name "modinfo_*" -execdir mv '{}' modinfo \;
	find ${TEMP} -name "find_*" -execdir rm -r '{}' \;
	find ${TEMP} -name "*:*" -execdir rm -rf '{}' \;

	$(cd ${TEMP}; zip -y -q -r ${2} . )

	sha256sum ${2}| cut -d' ' -f1| sed 's/.\{2\}/& /g'
}

do_sosreport()
{
	if $(findmnt | grep -q "$MEDIA_DIR") && ! $supported; then
		$do_fail
	fi

	SVCTAG=$(cat /sys/devices/virtual/dmi/id/product_serial)
	OUTFILE_F="OSC-FR-Report-${SVCTAG}.zip"
	OUTFILE_P="OSC-PR-Report-${SVCTAG}.zip"

	TMP_DIR=$(mktemp -d)
	/usr/sbin/sosreport --batch -o ${SOS_PLUGINS} -k ${SOS_OPTIONS} \
		--tmp-dir ${TMP_DIR} --quiet --name OSC-FR-Report-${SVCTAG}

	if [ $? -ne 0 ]; then
		$do_fail
		return 1
	fi

	SHA_F=$(prepare ${TMP_DIR}/sosreport*xz ${TMP_DIR}/${OUTFILE_F} \
		2> /dev/null)

	if [ $FILTER = "yes" ]; then
		$sos_cleaner -q ${TMP_DIR}/sosreport*xz -r ${TMP_DIR} && \
		SHA_P=$(prepare ${TMP_DIR}/soscleaner*gz \
			${TMP_DIR}/${OUTFILE_P} 2> /dev/null)
	fi

	cp -f ${TMP_DIR}/OSC-*zip ${MEDIA_DIR}/
	umount -r ${MEDIA_DIR}

	# Close connection with checksum
	$end_full "${SHA_F}"
	[ $FILTER = "yes" ] && $end_partial "${SHA_P}"

	$do_close

	rm -rf ${TMP_DIR}
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
		do_sosreport
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
