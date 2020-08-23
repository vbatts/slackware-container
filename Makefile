LATEST		:= 14.2
VERSION		:= $(LATEST)
VERSIONS	:= 13.0 13.1 13.37 14.0 14.1 14.2 current
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
RELEASENAME	?= slackware$(ARCH)
RELEASE		:= $(RELEASENAME)-$(VERSION)
CACHEFS		:= /tmp/$(NAME)/$(RELEASE)
ROOTFS		:= /tmp/rootfs-$(RELEASE)
#CRT		?= podman
CRT		?= docker

ifeq ($(CRT), podman)
CRTCMD         := CMD=/bin/sh
else
CRTCMD         := CMD /bin/sh
endif

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
		$(CRT) import -c '$(CRTCMD)' $(RELEASENAME)-$${version}.tar $(USER)/$(NAME):$${version} && \
		$(CRT) run -i --rm $(USER)/$(NAME):$${version} /usr/bin/echo "$(USER)/$(NAME):$${version} :: Success." ; \
	done && \
	$(CRT) tag $(USER)/$(NAME):$(LATEST) $(USER)/$(NAME):latest

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

.PHONY: clean-all
clean-all:
	for version in $(VERSIONS) ; do \
		$(MAKE) VERSION=$${version} clean ; \
	done

.PHONY: dist-clean
dist-clean: clean-all
	sudo rm -rf $(CACHEFS)

