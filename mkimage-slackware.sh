#!/bin/bash
# Generate a very minimal filesystem from slackware,
# and load it into the local docker under the name "slackware".

set -e

IMG_NAME="slackware"
RELEASE=${RELEASE:-"slackware64-14.1"}
MIRROR=${MIRROR:-"http://slackware.osuosl.org"}
CACHEFS=${CACHEFS:-"/tmp/slackware/${RELEASE}"}
ROOTFS=${ROOTFS:-"/tmp/rootfs-${IMG_NAME}-$$-${RANDOM}"}

mkdir -p $ROOTFS $CACHEFS

function cacheit() {
	file=$1
	if [ ! -f "${CACHEFS}/${file}"  ] ; then
		mkdir -p $(dirname ${CACHEFS}/${file})
		echo "Fetching $file" 1>&2
		curl -o "${CACHEFS}/${file}" "${MIRROR}/${RELEASE}/${file}"
	fi
	echo "${CACHEFS}/${file}"
}

cacheit "isolinux/initrd.img"

cd $ROOTFS
# extract the initrd to the current rootfs
zcat "${CACHEFS}/isolinux/initrd.img" | cpio -idvm --null --no-absolute-filenames
touch etc/resolv.conf

relbase=$(echo ${RELEASE} | cut -d- -f1)
#for pkg in $(curl -s ${MIRROR}/${RELEASE}/${RELBASE}/a/tagfile | grep REC$ | cut -d : -f 1)
#do
	#l_pkg=$(cacheit ${RELBASE}/${pkg}-*.t?z)
	#echo $l_pkg
	#tar xf ${l_pkg}
#done
for pkg in \
	a/pkgtools-14.1-noarch-2.tgz \
	a/tar-1.26-x86_64-1.tgz \
	a/xz-5.0.5-x86_64-1.tgz \
	n/wget-1.14-x86_64-2.txz \
	a/elvis-2.2_0-x86_64-2.txz \
	ap/slackpkg-2.82.0-noarch-12.tgz \
	a/aaa_terminfo-5.8-x86_64-1.txz \
	a/acpid-2.0.19-x86_64-1.txz \
	a/apmd-3.2.2-x86_64-3.txz \
	a/btrfs-progs-20130418-x86_64-1.txz \
	a/cups-1.5.4-x86_64-3.txz \
	a/dbus-1.6.12-x86_64-1.txz \
	a/dialog-1.2_20130523-x86_64-1.txz \
	a/dosfstools-3.0.22-x86_64-1.txz \
	a/ed-1.9-x86_64-1.txz \
	a/eject-2.1.5-x86_64-4.txz \
	a/file-5.14-x86_64-1.txz \
	a/gettext-0.18.2.1-x86_64-2.txz \
	a/inotify-tools-3.14-x86_64-1.txz \
	a/kbd-1.15.3-x86_64-2.txz \
	a/kernel-generic-3.10.17-x86_64-3.txz \
	a/lha-114i-x86_64-1.txz \
	a/libcgroup-0.38-x86_64-2.txz \
	a/lvm2-2.02.100-x86_64-1.txz \
	a/mcelog-1.0pre3-x86_64-1.txz \
	a/minicom-2.6.2-x86_64-1.txz \
	a/mtx-1.3.12-x86_64-1.txz \
	a/ncompress-4.2.4.3-x86_64-1.txz \
	a/patch-2.7-x86_64-2.txz \
	a/pciutils-3.2.0-x86_64-1.txz \
	a/pcmciautils-017-x86_64-1.txz \
	a/rpm2tgz-1.2.2-x86_64-1.txz \
	a/splitvt-1.6.5-x86_64-1.txz \
	a/sysfsutils-2.1.0-x86_64-1.txz \
	a/tcsh-6.18.01-x86_64-2.txz \
	a/time-1.7-x86_64-1.txz \
	a/tree-1.6.0-x86_64-1.txz \
	a/udisks-1.0.4-x86_64-2.txz \
	a/udisks2-2.1.0-x86_64-1.txz \
	a/unarj-265-x86_64-1.txz \
	a/upower-0.9.17-x86_64-1.txz \
	a/utempter-1.1.5-x86_64-1.txz \
	a/which-2.20-x86_64-1.txz \
	a/zoo-2.10_22-x86_64-1.txz
do
	l_pkg=$(cacheit $relbase/$pkg)
	./usr/lib/setup/installpkg --root $(pwd) --terse ${l_pkg}
	#tar xf ${l_pkg}
done


tar --numeric-owner -cf- . | docker import - ${IMG_NAME}
docker run -i -u root ${IMG_NAME} /bin/echo Success.
