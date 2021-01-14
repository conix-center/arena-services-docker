#!/bin/bash
source .env
SCRIPT_PATH=$(dirname $(realpath -s $0))
[ ! -d "$SCRIPT_PATH/data/backup" ] && mkdir $SCRIPT_PATH/data/backup
sudo /usr/bin/docker exec -it arena-services-docker_mongodb_1 sh -c 'exec mongodump --db arena_persist --collection arenaobjects --out /backup/mongo'
cp $SCRIPT_PATH/data/arena-store/database.db $SCRIPT_PATH/data/backup/store-database.db
chown -R $BACKUP_USER $SCRIPT_PATH/data/backup/*
