#!/bin/bash
docker build . -t conixcenter/arena-services-docker-init-utils

echo -e "\n### Push the container to dockerhub (needs credentials)."
read -p "Continue? (y/N) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker login --username conixcenter
    docker push conixcenter/arena-services-docker-init-utils
fi