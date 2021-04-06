#!/bin/bash
source .env
BACKUP_PATH=$(realpath -s $ARENA_DOCKER_REPO_FOLDER)/data/backup/$HOSTNAME 
DATA_PATH=$(realpath -s $ARENA_DOCKER_REPO_FOLDER)/data 
[ ! -d "$BACKUP_PATH" ] && mkdir $BACKUP_PATH
BFOLDER=$BACKUP_PATH/mongodb
[ ! -d "$BFOLDER" ] && mkdir $BFOLDER
# backup mongodb using mongodump
sudo /usr/bin/docker exec -it -e HOSTNAME=$HOSTNAME arena-services-docker_mongodb_1 sh -c 'exec mongodump --db arena_persist --collection arenaobjects --out /backup/$HOSTNAME/mongodb'
# backup other services by copying files
DATA_FOLDERS=( "arena-store" "grafana" "prometheus" "account" )
for d in "${DATA_FOLDERS[@]}"
do
  BFOLDER=$BACKUP_PATH/$d
  #[ ! -d "$BFOLDER" ] && mkdir $BFOLDER
  echo "cp -R $DATA_PATH/$d/ $BFOLDER/"
  cp -R $DATA_PATH/$d/ $BFOLDER
done
chown -R $BACKUP_USER $DATA_PATH/backup/*
