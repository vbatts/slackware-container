LATEST := 14.2
VERSION := $(LATEST)
VERSIONS := 13.37 14.0 14.1 14.2 current
RELEASE := slackware64-$(VERSION)
MIRROR := http://slackware.osuosl.org
CACHEFS := /tmp/slackware/$(RELEASE)
ROOTFS := /tmp/rootfs-slackware

image: mkimage-slackware.sh
	sudo \
		VERSION="$(VERSION)" \
		RELEASE="$(RELEASE)" \
		MIRROR="$(MIRROR)" \
		CACHEFS="$(CACHEFS)" \
		ROOTFS="$(ROOTFS)" \
		bash $<

all: mkimage-slackware.sh
	for version in $(VERSIONS) ; do \
		$(MAKE) VERSION=$${version} image && \
		$(MAKE) VERSION=$${version} clean && \
		docker tag $(USER)/slackware-base:$${version} $(USER)/slackware:$${version} ;\
	done && \
	docker tag $(USER)/slackware-base:$(LATEST) $(USER)/slackware:latest

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

