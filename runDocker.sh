#!/bin/bash
set -e
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t mirnafinderenv .
docker run -v $PWD/mirna/:/mirna -u `id -u`:`id -g` -it mirnafinderenv
# docker run -v $PWD/mirna/:/mirna -it mirnafinderenv
