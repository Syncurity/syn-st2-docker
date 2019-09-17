#!/usr/bin/env bash

echo "Stopping Syncurity ST2 Services"
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down

docker ps

echo "Syncurity Services stopped"

