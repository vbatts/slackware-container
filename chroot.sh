#!/bin/bash

rootfs="${1}"
shift

xx=$(mktemp)

cat > "${xx}" <<EOM
#!/bin/bash

export rootfs="\$1"
shift

if [ -e \$rootfs/etc/resolv.conf ] ; then
  rm -f \$rootfs/etc/resolv.conf
fi

cp /etc/resolv.conf \$rootfs/etc/
export LC_ALL="en_US.UTF-8"

mount -t proc proc \$rootfs/proc || exit 1
mount -t devtmpfs none \$rootfs/dev || exit 1
mount -t sysfs sysfs \$rootfs/sys || exit 1

chroot "\$rootfs" \$@

rm -f \$rootfs/etc/resolv.conf
EOM
chmod +x "${xx}"

unshare -muipCf "${xx}" "${rootfs}" $@
rm -rf "${xx}"
