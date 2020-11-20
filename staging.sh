#!/bin/bash
# usage: ./staging.sh [docker-compose SUBCOMMAND: up, down, ...]

docker-compose -f docker-compose.yaml -f docker-compose.prod.yaml -f docker-compose.staging.yaml $@
