LATEST		= 15.0
VERSION		= $(LATEST)
VERSIONS	= 13.0 13.1 13.37 14.0 14.1 14.2 15.0 current
NAME		= slackware
MIRROR		= http://slackware.mirrors.tds.net/pub/slackware/
ifeq ($(shell uname -m),x86_64)
ARCH = 64
else ifeq ($(patsubst i%86,x86,$(shell uname -m)),x86)
ARCH =
else ifeq ($(shell uname -m),armv6l)
ARCH = arm
else ifeq ($(shell uname -m),aarch64)
ARCH = arm64
else
ARCH = 64
endif
RELEASENAME	?= slackware$(ARCH)
RELEASE		= $(RELEASENAME)-$(VERSION)
CACHEFS		= $PWD/tmp/$(NAME)/$(RELEASE)
ROOTFS		= $PWD/tmp/rootfs-$(RELEASE)
#CRT		?= podman
CRT		?= docker

ifeq ($(CRT), podman)
CRTCMD         := CMD=/bin/sh
else
CRTCMD         := CMD /bin/sh
endif

image: $(RELEASENAME)-$(VERSION).tar

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
		$(MAKE) import-$${version} && \
		$(MAKE) run-test-$${version} ; \
	done && \
	$(CRT) tag $(USER)/$(NAME):$(LATEST) $(USER)/$(NAME):latest

import-%: $(RELEASENAME)-%.tar
	$(CRT) import -c '$(CRTCMD)' $(RELEASENAME)-$*.tar $(USER)/$(NAME):$*

run-%: import-%
	$(CRT) run -it --rm $(USER)/$(NAME):$*

run-test-%:
	$(CRT) run -i --rm $(USER)/$(NAME):$* /usr/bin/echo "$(USER)/$(NAME):$* :: Success."

.PHONY: umount
umount:
	@sudo umount $(ROOTFS)/etc/resolv.conf || :
	@sudo umount $(ROOTFS)/mnt/etc/resolv.conf || :
	@sudo umount $(ROOTFS)/cdrom || :
	@sudo umount $(ROOTFS)/dev || :
	@sudo umount $(ROOTFS)/sys || :
	@sudo umount $(ROOTFS)/proc || :

.PHONY: clean
clean: umount
	sudo rm -rf $(ROOTFS) $(CACHEFS)/paths

.PHONY: clean-all
clean-all:
	for version in $(VERSIONS) ; do \
		$(MAKE) VERSION=$${version} clean ; \
	done

.PHONY: dist-clean
dist-clean: clean-all
	sudo rm -rf $(CACHEFS)

