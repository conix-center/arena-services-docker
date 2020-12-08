#!/bin/bash
# usage: ./dev.sh [docker-compose SUBCOMMAND: up, down, ...]

# make sure ARENA-core/conf folder exists
[ ! -d "ARENA-core/conf" ] && mkdir ARENA-core/conf

# copy arena client defaults
cp ./conf/arena-web-conf/arena-defaults-dev.js ./conf/arena-web-conf/defaults.js

docker-compose -f docker-compose.override.yaml $@ # = docker-compose $@
