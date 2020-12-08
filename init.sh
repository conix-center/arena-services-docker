#!/bin/bash

touch secret.env

if [ ! -f .env ]
then
  cp init.env .env
fi

# TMP: create ARENA-core/user/static
[ ! -d "ARENA-core/user/static" ] mkdir -p ARENA-core/user/static

echo -e "\n\e[1m### Init config files (create secrets.env, ./conf/* files, and ./data/* folders)\e[0m\n"
docker run -it --env-file .env --env-file secret.env -e OWNER=`id -u`:`id -g` --rm -v $PWD:/work -w /work conixcenter/arena-services-docker-init-utils /work/init-config.sh

if [ $? -ne 0 ]
then
    echo -e "\n\e[1m### Init config failed. Stopping here.\e[0m\n"
    exit 1
fi

echo -e "\n\e[1m### Init letsencrypt (create/renew certificates)\e[0m\n"
docker run -it --env-file .env --env-file secret.env -e OWNER=`id -u`:`id -g` --rm -v $PWD:/work -v $PWD/data/certbot/conf:/etc/letsencrypt -v $PWD/data/certbot/www:/var/www/certbot -w /work -p 80:80 conixcenter/arena-services-docker-init-utils /work/init-letsencrypt.sh
if [ $? -ne 0 ]
then
    echo -e "\n\e[1m### Init letsencrypt failed. Did you stop services on port 80 ? To stop all services: [./dev.sh | ./prod.sh ./staging.sh] down).\e[0m\n"
    exit 1
fi
