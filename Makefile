VERSION := 14.1
#RELEASE := slackware64-$(VERSION)
#MIRROR := http://slackware.osuosl.org
#CACHEFS := /tmp/slackware/$(RELEASE)
#ROOTFS := /tmp/rootfs-slackware

default: image

farts:
		RELEASE="$(RELEASE)" \
		MIRROR="$(MIRROR)" \
		CACHEFS="$(CACHEFS)" \
		ROOTFS="$(ROOTFS)"

image: mkimage-slackware.sh
	sudo \
		VERSION="$(VERSION)" \
		bash $<

.PHONY: umount
umount:
	@sudo umount $(ROOTFS)/cdrom || :
	@sudo umount $(ROOTFS)/dev || :
	@sudo umount $(ROOTFS)/sys || :
	@sudo umount $(ROOTFS)/proc || :
	@sudo umount $(ROOTFS)/etc/resolv.conf || :

.PHONY: clean
clean: umount
	sudo rm -rf $(ROOTFS) $(CACHEFS)/paths

.PHONY: dist-clean
dist-clean: clean
	sudo rm -rf $(CACHEFS)

