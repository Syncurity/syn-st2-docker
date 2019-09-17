#!/usr/bin/env bash

source .env
echo "Checking Environment"
#certs_volume_exists="$(docker volume ls | grep metabase_certs)"
#echo "${certs_volume_exists}"

#if [[ -z ${certs_volume_exists} ]] && [ ${MB_JETTY_SSL} = "true" ]; then
#    echo "Trying to start metabase in SSL mode with out certificate store. Run ./prod_environment.sh"
#    exit 1
#fi

echo "Starting Syncurity ST2 Services"
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

docker ps

echo "Syncurity ST2 Services Started"


