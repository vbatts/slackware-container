#!/bin/bash
# Generate a very minimal filesystem from slackware

set -e

if [ -z "$ARCH" ]; then
  case "$( uname -m )" in
    i?86) ARCH="" ;;
    arm*) ARCH=arm ;;
       *) ARCH=64 ;;
  esac
fi

BUILD_NAME=${BUILD_NAME:-"slackware"}
VERSION=${VERSION:="current"}
RELEASENAME=${RELEASENAME:-"slackware${ARCH}"}
RELEASE=${RELEASE:-"${RELEASENAME}-${VERSION}"}
MIRROR=${MIRROR:-"http://slackware.osuosl.org"}
CACHEFS=${CACHEFS:-"/tmp/slackware/${RELEASE}"}
ROOTFS=${ROOTFS:-"/tmp/rootfs-${BUILD_NAME}"}
CWD=$(pwd)

base_pkgs="a/aaa_base \
	a/aaa_elflibs \
	a/coreutils \
	a/glibc-solibs \
	a/aaa_terminfo \
	a/pkgtools \
	a/shadow \
	a/tar \
	a/xz \
	a/bash \
	a/etc \
	a/gzip \
	n/wget \
	n/gnupg \
	a/elvis \
	ap/slackpkg \
	l/ncurses \
	a/bin \
	a/bzip2 \
	a/grep \
	a/sed \
	a/dialog \
	a/file \
	a/gawk \
	a/time \
	a/gettext \
	a/libcgroup \
	a/patch \
	a/sysfsutils \
	a/time \
	a/tree \
	a/utempter \
	a/which \
	a/util-linux \
	l/mpfr \
	l/libunistring \
	ap/diffutils \
	a/procps \
	n/net-tools \
	a/findutils \
	n/iproute2 \
	n/openssl"

function cacheit() {
	file=$1
	if [ ! -f "${CACHEFS}/${file}"  ] ; then
		mkdir -p $(dirname ${CACHEFS}/${file})
		echo "Fetching $file" 1>&2
		curl -s -o "${CACHEFS}/${file}" "${MIRROR}/${RELEASE}/${file}"
	fi
	echo "/cdrom/${file}"
}

mkdir -p $ROOTFS $CACHEFS

cacheit "isolinux/initrd.img"

cd $ROOTFS
# extract the initrd to the current rootfs
zcat "${CACHEFS}/isolinux/initrd.img" | cpio -idvm --null --no-absolute-filenames

if stat -c %F $ROOTFS/cdrom | grep -q "symbolic link" ; then
	rm $ROOTFS/cdrom
fi
mkdir -p $ROOTFS/{mnt,cdrom,dev,proc,sys}

for dir in cdrom dev sys proc ; do
	if mount | grep -q $ROOTFS/$dir  ; then
		umount $ROOTFS/$dir
	fi
done

mount --bind $CACHEFS ${ROOTFS}/cdrom
mount -t devtmpfs none ${ROOTFS}/dev
mount --bind -o ro /sys ${ROOTFS}/sys
mount --bind /proc ${ROOTFS}/proc

mkdir -p mnt/etc
cp etc/ld.so.conf mnt/etc

relbase=$(echo ${RELEASE} | cut -d- -f1)
if [ ! -f ${CACHEFS}/paths ] ; then
	ruby ${CWD}/get_paths.rb ${RELEASE} > ${CACHEFS}/paths
fi
for pkg in ${base_pkgs}
do
	path=$(grep ^${pkg} ${CACHEFS}/paths | cut -d : -f 1)
	if [ ${#path} -eq 0 ] ; then
		echo "$pkg not found"
		continue
	fi
	l_pkg=$(cacheit $relbase/$path)
	PATH=/bin:/sbin:/usr/bin:/usr/sbin \
	chroot . /usr/lib/setup/installpkg --root /mnt --terse ${l_pkg}
done

cd mnt
set -x
touch etc/resolv.conf
echo "export TERM=linux" >> etc/profile.d/term.sh
chmod +x etc/profile.d/term.sh
echo ". /etc/profile" > .bashrc
echo "${MIRROR}/${RELEASE}/" >> etc/slackpkg/mirrors
sed -i 's/DIALOG=on/DIALOG=off/' etc/slackpkg/slackpkg.conf
sed -i 's/POSTINST=on/POSTINST=off/' etc/slackpkg/slackpkg.conf
sed -i 's/SPINNING=on/SPINNING=off/' etc/slackpkg/slackpkg.conf

mount --bind /etc/resolv.conf etc/resolv.conf
chroot . sh -c 'slackpkg -batch=on -default_answer=y update && slackpkg -batch=on -default_answer=y upgrade-all'

# now some cleanup of the minimal image
set +x
rm -rf var/lib/slackpkg/*
rm -rf usr/share/locale/*
rm -rf usr/man/*
find usr/share/terminfo/ -type f ! -name 'linux' -a ! -name 'xterm' -a ! -name 'screen.linux' -exec rm -f "{}" \;
umount $ROOTFS/dev
rm -f dev/* # containers should expect the kernel API (`mount -t devtmpfs none /dev`)
umount etc/resolv.conf

tar --numeric-owner -cf- . > ${CWD}/${RELEASE}.tar
ls -sh ${CWD}/${RELEASE}.tar

for dir in cdrom dev sys proc ; do
	if mount | grep -q $ROOTFS/$dir  ; then
		umount $ROOTFS/$dir
	fi
done


