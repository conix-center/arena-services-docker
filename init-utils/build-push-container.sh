#!/bin/bash
DOCKER_USER=conixcenter
docker build . -t conixcenter/arena-services-docker-init-utils

echo -e "\n### Push the container to dockerhub (needs dockerhub credentials for user '$DOCKER_USER'."
read -p "Continue? (y/N) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Enter dockerhub credentials for '$DOCKER_USER'"
    docker login --username $DOCKER_USER
    docker push conixcenter/arena-services-docker-init-utils
fi