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

if [ ! -f "${CACHEFS}/initrd.img"  ] ; then
	curl -o "${CACHEFS}/initrd.img" "${MIRROR}/${RELEASE}/isolinux/initrd.img"
fi

cd $ROOTFS

zcat "${CACHEFS}/initrd.img" | cpio -idvm --null --no-absolute-filenames

touch etc/resolv.conf

tar --numeric-owner -cf- . | docker import - ${IMG_NAME}
docker run -i -u root ${IMG_NAME} /bin/echo Success.
