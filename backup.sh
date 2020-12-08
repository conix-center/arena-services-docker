#!/bin/bash
SCRIPT_PATH=$(dirname $(realpath -s $0))
ARENA_DOCKER_FOLDER=/home/wiselab/arena-services-docker
[ ! -d "$SCRIPT_PATH/data/backup" ] && mkdir $SCRIPT_PATH/data/backup
docker exec -it arena-services-docker_mongodb_1 sh -c 'exec mongodump --db arena_persist --collection arenaobjects --out -' > $SCRIPT_PATH/data/backup/mongo-arenaobjects-$(date +%j).dump
cp $SCRIPT_PATH/data/arena-store/database.db $SCRIPT_PATH/data/backup/

