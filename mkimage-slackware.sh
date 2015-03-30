#!/bin/bash
# Generate a very minimal filesystem from slackware,
# and load it into the local docker under the name "slackware".

set -e
user=${SUDO_USER:-${USER}}
IMG_NAME=${IMG_NAME:-"${user}/slackware-base"}
VERSION=${VERSION:="14.1"}
RELEASE=${RELEASE:-"slackware64-${VERSION}"}
MIRROR=${MIRROR:-"http://slackware.osuosl.org"}
CACHEFS=${CACHEFS:-"/tmp/slackware/${RELEASE}"}
#ROOTFS=${ROOTFS:-"/tmp/rootfs-${IMG_NAME}-$$-${RANDOM}"}
ROOTFS=${ROOTFS:-"/tmp/rootfs-${IMG_NAME}"}
CWD=$(pwd)

base_pkgs="a/aaa_base \
	a/aaa_elflibs \
	a/coreutils \
	a/glibc-solibs \
	a/aaa_terminfo \
	a/pkgtools \
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
#mount --bind /dev ${ROOTFS}/dev
mount --bind /sys ${ROOTFS}/sys
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
cp -a ../dev/* dev/
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
set +x
rm -rf var/lib/slackpkg/*
umount etc/resolv.conf

tar --numeric-owner -cf- . > ${CWD}/${USER}-${RELEASE}.tar
cat ${CWD}/${USER}-${RELEASE}.tar | docker import - ${IMG_NAME}:${VERSION}
docker run -i -u root ${IMG_NAME}:${VERSION} /bin/echo "${IMG_NAME}:${VERSION} :: Success."
ls -sh ${CWD}/${USER}-${RELEASE}.tar

for dir in cdrom dev sys proc ; do
	if mount | grep -q $ROOTFS/$dir  ; then
		umount $ROOTFS/$dir
	fi
done


