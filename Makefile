LATEST		:= 14.2
VERSION		:= $(LATEST)
VERSIONS	:= 13.37 14.0 14.1 14.2 current
NAME		:= slackware
MIRROR		:= http://slackware.osuosl.org
ifeq ($(shell uname -m),x86_64)
ARCH := 64
else ifeq ($(patsubst i%86,x86,$(shell uname -m)),x86)
ARCH :=
else ifeq ($(shell uname -m),armv6l)
ARCH := arm
else ifeq ($(shell uname -m),aarch64)
ARCH := arm64
else
ARCH := 64
endif
RELEASENAME	:= slackware$(ARCH)
RELEASE		:= $(RELEASENAME)-$(VERSION)
CACHEFS		:= /tmp/$(NAME)/$(RELEASE)
ROOTFS		:= /tmp/rootfs-$(RELEASE)

image: $(RELEASENAME)-$(LATEST).tar

arch:
	@echo $(ARCH)
	@echo $(RELEASE)

$(RELEASENAME)-%.tar: mkimage-slackware.sh
	sudo \
		VERSION="$*" \
		USER="$(USER)" \
		BUILD_NAME="$(NAME)" \
		bash $<

all: mkimage-slackware.sh
	for version in $(VERSIONS) ; do \
		$(MAKE) $(RELEASENAME)-$${version}.tar && \
		$(MAKE) VERSION=$${version} clean && \
		cat $(RELEASENAME)-$${version}.tar | docker import -c 'CMD /bin/sh' - $(USER)/$(NAME):$${version} && \
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

