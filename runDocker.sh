#!/bin/bash
set -e
docker build -t mirnafinderenv .
# docker run -v $PWD/mirna/:/mirna -u `id -u`:`id -g` -it mirnafinderenv
docker run -v $PWD/mirna/:/mirna -it mirnafinderenv
