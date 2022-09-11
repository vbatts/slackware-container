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
MINIMAL=${MINIMAL:-yes}
CWD=$(pwd)

base_pkgs="a/aaa_base \
	a/aaa_elflibs \
	a/aaa_libraries \
	a/coreutils \
	a/glibc-solibs \
	a/aaa_glibc-solibs \
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
	a/acl \
	l/pcre \
	l/gmp \
 	a/attr \
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
	a/elogind \
	l/libseccomp \
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
root_flag=""
if [ -f ./sbin/upgradepkg ] && grep -qw -- '"--root"' ./sbin/upgradepkg ; then
	root_flag="--root /mnt"
elif [ -f ./usr/lib/setup/installpkg ] && grep -qw -- '"-root"' ./usr/lib/setup/installpkg ; then
	root_flag="-root /mnt"
fi
if [ "$VERSION" = "current" ] || [ "${VERSION}" = "15.0" ]; then
	root_env='ROOT=/mnt'
	root_flag=''
fi

relbase=$(echo ${RELEASE} | cut -d- -f1)
if [ ! -f ${CACHEFS}/paths ] ; then
	bash ${CWD}/get_paths.sh -r ${RELEASE} > ${CACHEFS}/paths
fi
if [ ! -f ${CACHEFS}/paths-patches ] ; then
	bash ${CWD}/get_paths.sh -r ${RELEASE} -m ${MIRROR} -p > ${CACHEFS}/paths-patches
fi
if [ ! -f ${CACHEFS}/paths-extra ] ; then
	bash ${CWD}/get_paths.sh -r ${RELEASE} -m ${MIRROR} -e > ${CACHEFS}/paths-extra
fi
for pkg in ${base_pkgs}
do
	path=$(grep "^packages/$(basename "${pkg}")-" ${CACHEFS}/paths-patches | cut -d : -f 1)
	if [ ${#path} -eq 0 ] ; then
		path=$(grep ^${pkg}- ${CACHEFS}/paths | cut -d : -f 1)
		if [ ${#path} -eq 0 ] ; then
			path=$(grep "^$(basename "${pkg}")/$(basename "${pkg}")-" ${CACHEFS}/paths-extra | cut -d : -f 1)
			if [ ${#path} -eq 0 ] ; then
				echo "$pkg not found"
				continue
			else
				l_pkg=$(cacheit extra/$path)
			fi
		else
			l_pkg=$(cacheit $relbase/$path)
		fi
	else
		l_pkg=$(cacheit patches/$path)
	fi
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

PATH=/bin:/sbin:/usr/bin:/usr/sbin \
chroot . /bin/sh -c '/sbin/ldconfig'

# slackpkg would normally do this on first invocation
if [ ! -e ./root/.gnupg ] ; then
	cacheit "GPG-KEY"
	cp ${CACHEFS}/GPG-KEY .
	echo PATH=/bin:/sbin:/usr/bin:/usr/sbin \
	chroot . /usr/bin/gpg --import GPG-KEY
	PATH=/bin:/sbin:/usr/bin:/usr/sbin \
	chroot . /usr/bin/gpg --import GPG-KEY
	rm GPG-KEY
fi

set -x
if [ "$MINIMAL" = "yes" ] || [ "$MINIMAL" = "1" ] ; then
	echo "export TERM=linux" >> etc/profile.d/term.sh
	chmod +x etc/profile.d/term.sh
	echo ". /etc/profile" > .bashrc
fi
if [ -e etc/slackpkg/mirrors ] ; then
	echo "${MIRROR}/${RELEASE}/" >> etc/slackpkg/mirrors
	sed -i 's/DIALOG=on/DIALOG=off/' etc/slackpkg/slackpkg.conf
	sed -i 's/POSTINST=on/POSTINST=off/' etc/slackpkg/slackpkg.conf
	sed -i 's/SPINNING=on/SPINNING=off/' etc/slackpkg/slackpkg.conf
fi
if [ ! -f etc/rc.d/rc.local ] ; then
	mkdir -p etc/rc.d
	cat >> etc/rc.d/rc.local <<EOF
#!/bin/sh
#
# /etc/rc.d/rc.local:  Local system initialization script.

EOF
	chmod +x etc/rc.d/rc.local
fi

# now some cleanup of the minimal image
set +x
if [ "$MINIMAL" = "yes" ] || [ "$MINIMAL" = "1" ] ; then
	rm -rf usr/share/locale/*
	rm -rf usr/man/*
	find usr/share/terminfo/ -type f ! -name 'linux' -a ! -name 'xterm' -a ! -name 'screen.linux' -exec rm -f "{}" \;
fi
umount $ROOTFS/dev
rm -f dev/* # containers should expect the kernel API (`mount -t devtmpfs none /dev`)

tar --numeric-owner -cf- . > ${CWD}/${RELEASE}.tar
ls -sh ${CWD}/${RELEASE}.tar

for dir in cdrom dev sys proc ; do
	if mount | grep -q $ROOTFS/$dir  ; then
		umount $ROOTFS/$dir
	fi
done


