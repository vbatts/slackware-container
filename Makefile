LATEST		:= 14.2
VERSION		:= $(LATEST)
VERSIONS	:= 13.37 14.0 14.1 14.2 current
NAME		:= slackware
# If SW_ARCH unset, set to default of "64"
ifeq "${TARGET_ARCH}" "i586"
	SW_ARCH	:= 
else ifeq "${TARGET_ARCH}" "i486"
	SW_ARCH	:= 
else
	SW_ARCH	:= 64
endif
#SW_ARCH		:= $(shell if [ -z $${TARGET_ARCH+x} ] || [ "$${TARGET_ARCH}" = "x86_64" ]; then echo 64; else echo 32; fi )
TMP		:= $(shell if [ -z $${TMP+x} ]; then echo /tmp; else echo $${TMP}; fi )
RELEASE		:= slackware$(SW_ARCH)-$(VERSION)
MIRROR		:= http://slackware.osuosl.org
CACHEFS		:= $(TMP)/$(NAME)/$(RELEASE)
ROOTFS		:= $(TMP)/rootfs-$(NAME)

image: slackware$(SW_ARCH)-$(LATEST).tar

slackware$(SW_ARCH)-$(VERSION).tar: mkimage-slackware.sh
	sudo \
		VERSION="$(VERSION)" \
		USER="$(USER)" \
		SW_ARCH="$(SW_ARCH)" \
		bash $<

all: mkimage-slackware.sh
	for version in $(VERSIONS) ; do \
		$(MAKE) slackware$(SW_ARCH)-$${version}.tar && \
		$(MAKE) VERSION=$${version} clean && \
		cat slackware$(SW_ARCH)-$${version}.tar | docker import -c "ENTRYPOINT [\"sh\"]"  - $(USER)/$(NAME):$${version} && \
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

