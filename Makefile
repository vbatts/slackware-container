RELEASE := slackware64-14.1
MIRROR := http://slackware.osuosl.org
CACHEFS := /tmp/slackware/$(RELEASE)
ROOTFS := /tmp/rootfs-slackware

image: mkimage-slackware.sh
	sudo \
		RELEASE=$(RELEASE) \
		MIRROR=$(MIRROR) \
		CACHEFS=$(CACHEFS) \
		ROOTFS=$(ROOTFS) \
		sh $<

.PHONY: clean
clean:
	@sudo umount $(ROOTFS)/cdrom || :
	@sudo umount $(ROOTFS)/dev || :
	@sudo umount $(ROOTFS)/sys || :
	@sudo umount $(ROOTFS)/proc || :
	sudo rm -rf $(ROOTFS)

.PHONY: dist-clean
dist-clean: clean
	sudo rm -rf $(CACHEFS)

