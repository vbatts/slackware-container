#!/bin/bash
# Generate a very minimal filesystem from slackware,
# and load it into the local docker under the name "slackware".

set -e

IMG_NAME=slackware
RELEASE="slackware64-14.1"
MIRROR="http://slackware.osuosl.org"

CACHEFS="/tmp/slackware/${RELEASE}"
ROOTFS=/tmp/rootfs-${IMG_NAME}-$$-$RANDOM

mkdir -p $ROOTFS $CACHEFS

if [ ! -f "${CACHEFS}/initrd.img"  ] ; then
	curl -o "${CACHEFS}/initrd.img" "${MIRROR}/${RELEASE}/isolinux/initrd.img"
fi

echo "${CACHEFS}/initrd.img"  
exit 1
cd $ROOTFS

mkdir bin etc dev dev/pts lib proc sys tmp
touch etc/resolv.conf
cp /etc/nsswitch.conf etc/nsswitch.conf
echo root:x:0:0:root:/:/bin/sh > etc/passwd
echo root:x:0: > etc/group
ln -s lib lib64
ln -s bin sbin
cp $BUSYBOX bin
for X in $(busybox --list)
do
    ln -s busybox bin/$X
done
rm bin/init
ln bin/busybox bin/init
cp /lib/x86_64-linux-gnu/lib{pthread,c,dl,nsl,nss_*}.so.* lib
cp /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 lib
for X in console null ptmx random stdin stdout stderr tty urandom zero
do
    cp -a /dev/$X dev
done

tar --numeric-owner -cf- . | docker import - ${IMG_NAME}
docker run -i -u root ${IMG_NAME} /bin/echo Success.
