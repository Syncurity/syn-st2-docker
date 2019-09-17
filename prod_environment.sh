#!/bin/bash -eux

if [ "$(uname)" == "Darwin" ]; then
    printf "OSX detected. This script does not install docker and other tools. Needed to run properly.\n\n"
fi


if [ -f ".env" ]; then
    printf "found .env file. Proceeding with load"
else
    printf "moving .env into place from template\n Please configure user settings in here"
    cp env.template .env
fi

# source .env
. .env

printf "Prod environment setup complete\n"


printf "Starting Syncurity Services....\n\n"
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d


## Import ssl cert to docker volume
#if [ "$MB_JETTY_SSL_Keystore" ]; then
#
#    printf "Starting Syncurity Metabase Reporting...\n\n"
#    docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
#
#    printf "Loading selfsigned certificate from ${SELF_SIGNED_CERT}...\n"
#
#    container_id="$(docker ps | grep syncurity/metabase | cut -d' ' -f1)"
#    echo "docker cp ${SELF_SIGNED_CERT} ${container_id}:${MB_JETTY_SSL_Keystore}"
#    docker cp "${SELF_SIGNED_CERT}" "${container_id}:${MB_JETTY_SSL_Keystore}"
#
#elif [ "$CA_SIGNED_CERT" ]; then
#
#    printf "Starting Syncurity Metabase Reporting...\n\n"
#    docker-compose -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.prod.sslcert.yml up -d
#
#    printf "Loading CA cert certificate from ${CA_SIGNED_CERT}...\n"
#    container_id="$(docker ps | grep syncurity/metabase | cut -d' ' -f1)"
#    echo "docker cp ${CA_SIGNED_CERT} ${container_id}:${MB_JETTY_SSL_Keystore}"
#    docker cp "${CA_SIGNED_CERT}" "${container_id}:${MB_JETTY_SSL_Keystore}"
#
#else
#
#    printf "Starting Syncurity Metabase Reporting....\n\n"
#    docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
#    printf "\nBrowse to http://localhost:3000 to setup metabase\n\n"
#fi

printf "Use bin/start_syn_services.sh and bin/stop_syn_services.sh to turn server on and off \n"

echo "Removing env vars from memory"
unset -v POSTGRESQL_ADMIN_PASSWORD

#Show container environment
sleep 5 && docker ps

echo "Waiting for Syncurity Service to come up..."
docker logs syncurity_postgresql


# while not docker logs metabase_web | grep
until [[ $(docker logs syncurity_postgresql | grep COMPLETE) ]]; do
    echo "$(docker logs syncurity_postgresql | grep COMPLETE)"
done

echo "Complete"
