
DOCKER		?= $(shell which docker)
FROM_IMAGE	?= vbatts/slackware
FROM_TAG	?= current
FROM		?= $(FROM_IMAGE):$(FROM_TAG)
REPO		?= http://slackware.osuosl.org/slackware64-current/
NAME		?= $(USER)/$(shell basename $(FROM_IMAGE))-dev:$(FROM_TAG)

default: build

build: .build

.build: Dockerfile
	$(DOCKER) build --pull \
		-t "$(NAME)" \
		--build-arg=REPO="$(REPO)" \
		--build-arg=FROM_IMAGE="$(FROM)" \
		--build-arg=DEV_USER="$(USER)" \
		. && \
	touch $@

clean:
	rm -rf .build .pull Dockerfile *~

