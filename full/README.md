This will build a container with the full install of slackware, from one of the minimal container images up on the docker hub.


## build

```shell
sudo make
```

Will do a default build of current. User `limited` of uid 1000 (though it does have sudo rights).

### More advanced

Use a different repo than slackware.osuosl.org:

```shell
sudo make build \
  REPO=http://my.mirror.local/slackware.osuosl.org/slackware/slackware64-current/ \
  USER=$USER
```


### skip `Makefile`

Using something like `docker` (though `buildah` ought to work fine too)

```shell
sudo docker build \
  --build-arg=REPO=http://my.mirror.local/slackware.osuosl.org/slackware/slackware64-14.2/ \
  --build-arg=DEV_USER=$USER \
  --build-arg=FROM_IMAGE="vbatts/slackware:14.2" \
  -t vbatts/slackware-dev:14.2 \
  .
```
