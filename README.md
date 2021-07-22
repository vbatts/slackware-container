slackware-container
===============

build scripts for a slackware container image

Overview
========

The Dockerfile is incomplete so far, since it expects a base image to be used.
It would be possible and understandable to use the 'busybox' image, and build
from there, but also to have a mkimage-slackware.sh to build the base image.

build
=====

Currently, using the installer bootstrap, the mkimage-slackware can create an
ultra-minimal slackware filesystem. (does not even include pkgtools)

If you have [podman](https://github.com/containers/libpod/tree/master/cmd/podman) installed (the is an [SBo build](https://slackbuilds.org/repository/14.2/system/podman/)):

	$> CRT="sudo podman" make image

Then you will be able to run:

	$> sudo podman run -i -t $USER/slackware-base /bin/sh

_(this also can be built and run with docker as well. If you build with one, you'll have to push your container build to a container registry before you can pull and run with the other)_

(This will be the environment to build out the Dockerfile from)
(( see http://docs.docker.com/reference/builder/ for more info on that ))


To build alternate versions of slackware, pass gnu-make the RELEASE variable, like:

	$> make image RELEASE=slackware64-13.37 IMG_NAME=$HOME/my_slackware:13.37

To build and test say slackware64-current in a docker container:

```shell
make run-current
```

Index
=====

This is this build process used to be the base of 'vbatts/slackware' on the
http://index.docker.io/

Just running:


	$> sudo podman run -i -t vbatts/slackware /bin/sh
 
 or

	$> sudo docker run -i -t vbatts/slackware /bin/sh

Will pull down this image for testing.

Contributing
============
please hack on this and send feedback!

License
=======

Copyright (c) 2013, Vincent Batts <vbatts@hashbangbash.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
