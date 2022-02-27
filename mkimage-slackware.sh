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
CACHEFS=${CACHEFS:-"/tmp/${BUILD_NAME}/${RELEASE}"}
ROOTFS=${ROOTFS:-"/tmp/rootfs-${RELEASE}"}
CWD=$(pwd)

base_pkgs="a/aaa_base \
	a/aaa_libraries \
	a/coreutils \
	a/glibc-solibs \
	a/aaa_terminfo \
	a/pam \
	a/cracklib \
	a/libpwquality \
	a/e2fsprogs \
	a/nvi \
	a/pkgtools \
	a/shadow \
	a/tar \
	a/xz \
	a/bash \
	a/etc \
	a/gzip \
	l/pcre2 \
	l/libpsl \
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

base_pkgs_legacy="a/aaa_elflibs \
	a/glibc-solibs"
base_pkgs_15_0="a/aaa_libraries \
	a/aaa_glibc-solibs"
base_pkgs_current="a/aaa_libraries \
	a/aaa_glibc-solibs"

if [[ "$VERSION" == "current" ]]; then
  base_pkgs="$base_pkgs_current \
	$base_pkgs"
elif [[ "$VERSION" == "15.0" ]]; then
  base_pkgs="$base_pkgs_15_0 \
	$base_pkgs"
else
  base_pkgs="$base_pkgs_legacy \
	$base_pkgs"
fi

function cacheit() {
	file=$1
	if [ ! -f "${CACHEFS}/${file}"  ] ; then
		mkdir -p $(dirname ${CACHEFS}/${file})
		echo "Fetching ${MIRROR}/${RELEASE}/${file}" >&2
		curl -s -o "${CACHEFS}/${file}" "${MIRROR}/${RELEASE}/${file}"
	fi
	echo "/cdrom/${file}"
}

mkdir -p $ROOTFS $CACHEFS

cacheit "isolinux/initrd.img"

cd $ROOTFS
# extract the initrd to the current rootfs
## ./slackware64-14.2/isolinux/initrd.img:    gzip compressed data, last modified: Fri Jun 24 21:14:48 2016, max compression, from Unix, original size 68600832
## ./slackware64-current/isolinux/initrd.img: XZ compressed data
if $(file ${CACHEFS}/isolinux/initrd.img | grep -wq XZ) ; then
	xzcat "${CACHEFS}/isolinux/initrd.img" | cpio -idvm --null --no-absolute-filenames
else
	zcat "${CACHEFS}/isolinux/initrd.img" | cpio -idvm --null --no-absolute-filenames
fi

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

# older versions than 13.37 did not have certain flags
install_args=""
if [ -f ./sbin/upgradepkg ] &&  grep -qw terse ./sbin/upgradepkg ; then
	install_args="--install-new --reinstall --terse"
elif [ -f ./usr/lib/setup/installpkg ] &&  grep -qw terse ./usr/lib/setup/installpkg ; then
	install_args="--terse"
fi

# an update in upgradepkg during the 14.2 -> 15.0 cycle changed/broke this
root_env=""
root_flag="--root /mnt"
if [ "$VERSION" = "15.0" ] || [ "$VERSION" = "current" ] ; then
	root_env='ROOT=/mnt'
	root_flag=''
fi

relbase=$(echo ${RELEASE} | cut -d- -f1)
if [ ! -f ${CACHEFS}/paths ] ; then
	bash ${CWD}/get_paths.sh -r ${RELEASE} > ${CACHEFS}/paths
fi
for pkg in ${base_pkgs}
do
	path=$(grep ^${pkg} ${CACHEFS}/paths | cut -d : -f 1)
	if [ ${#path} -eq 0 ] ; then
		echo "$pkg not found"
		continue
	fi
	l_pkg=$(cacheit $relbase/$path)
	if [ -e ./sbin/upgradepkg ] ; then
		echo PATH=/bin:/sbin:/usr/bin:/usr/sbin \
		ROOT=/mnt \
		chroot . /sbin/upgradepkg ${root_flag} ${install_args} ${l_pkg}
		PATH=/bin:/sbin:/usr/bin:/usr/sbin \
		ROOT=/mnt \
		chroot . /sbin/upgradepkg ${root_flag} ${install_args} ${l_pkg}
	else
		echo PATH=/bin:/sbin:/usr/bin:/usr/sbin \
		ROOT=/mnt \
		chroot . /usr/lib/setup/installpkg ${root_flag} ${install_args} ${l_pkg}
		PATH=/bin:/sbin:/usr/bin:/usr/sbin \
		ROOT=/mnt \
		chroot . /usr/lib/setup/installpkg ${root_flag} ${install_args} ${l_pkg}
	fi
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

if [ ! -f etc/rc.d/rc.local ] ; then
	mkdir -p etc/rc.d
	cat >> etc/rc.d/rc.local <<EOF
#!/bin/sh
#
# /etc/rc.d/rc.local:  Local system initialization script.

EOF
	chmod +x etc/rc.d/rc.local
fi

mount --bind /etc/resolv.conf etc/resolv.conf
PATH=/bin:/sbin:/usr/bin:/usr/sbin \
chroot . /bin/bash -c 'yes y | /usr/sbin/slackpkg -batch=on -default_answer=y update'
PATH=/bin:/sbin:/usr/bin:/usr/sbin \
# handle new exit codes from slackpkg in 15.0 and newer
chroot . /bin/bash -c 'EXIT_CODE=0 && { /usr/sbin/slackpkg -batch=on -default_answer=y upgrade-all || EXIT_CODE=$? ; } && if [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 20 ] ; then exit $EXIT_CODE ; fi'

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


