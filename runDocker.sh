#!/bin/bash
# docker-compose run --rm env
docker build -t mirnafinderenv .
docker run -v $PWD/mirna/:/mirna -u `id -u`:`id -g` -it mirnafinderenv
