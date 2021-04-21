#!/bin/bash
# usage: ./staging.sh [docker-compose SUBCOMMAND: up, down, ...]

# make sure ARENA-core/conf folder exists
[ ! -d "ARENA-core/conf" ] && mkdir ARENA-core/conf

# copy arena client defaults
cp ./conf/arena-web-conf/arena-defaults-dev.js ./conf/arena-web-conf/defaults.js

# force static volumes to be created again on "up"
if [[ "$*" == *up* ]]
then
    #docker volume rm arena-services-docker_arts-static-content
    docker volume rm arena-services-docker_account-static-content
fi

docker-compose -f docker-compose.yaml -f docker-compose.staging.yaml $@
