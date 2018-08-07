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


## run

Since the username and UID can match with my user on the host, the workflow I prefer is to wrap my $HOME directory.
This way all my cloned sources, bashrc, etc. are all the way I would expect.
A build can be tested from one version to the next fairly straightforward like:

```shell
sudo docker run \
  -it \
  --rm \
  -v $HOME:$HOME \
  -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK \
  --env SSH_AUTH_SOCK=$SSH_AUTH_SOCK \
  vbatts/slackware-dev:14.2
```

This enters an interactive shell, where you everything outside of $HOME is garbage-collected after the shell exits.
So you can `installpkg`, `upgradepkg`, etc. and not affect your host outside the container.


## disk usage

Since these are full installs, they are not small.
At the time of writing this:
```shell
docker.usersys/vbatts/slackware-dev   14.2                7f9328de56c8        14 minutes ago      7.13GB
docker.usersys/vbatts/slackware-dev   current             fc2e36e407ec        3 days ago          9.46GB
```
