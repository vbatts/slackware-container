LATEST		:= 14.2
VERSION		:= $(LATEST)
VERSIONS	:= 13.37 14.0 14.1 14.2 current
NAME		:= slackware
RELEASE		:= slackware64-$(VERSION)
MIRROR		:= http://slackware.osuosl.org
CACHEFS		:= /tmp/$(NAME)/$(RELEASE)
ROOTFS		:= /tmp/rootfs-$(NAME)

image: slackware64-$(LATEST).tar

slackware64-%.tar: mkimage-slackware.sh
	sudo \
		VERSION="$*" \
		USER="$(USER)" \
		bash $<

all: mkimage-slackware.sh
	for version in $(VERSIONS) ; do \
		$(MAKE) slackware64-$${version}.tar && \
		$(MAKE) VERSION=$${version} clean && \
		cat slackware64-$${version}.tar | docker import -c "CMD [\"sh\"]"  - $(USER)/$(NAME):$${version} && \
		docker run -i --rm $(USER)/$(NAME):$${version} /usr/bin/echo "$(USER)/$(NAME):$${version} :: Success." ; \
	done && \
	docker tag $(USER)/$(NAME):$(LATEST) $(USER)/$(NAME):latest

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

