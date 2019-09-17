#!/bin/bash -eu

if [ "$(uname)" == "Darwin" ]; then
    printf "OSX detected. This script does not install docker and other tools. Needed to run properly.\n\n"
fi


printf "moving .env into place from template"
cp env.template .env

key=$(openssl rand -base64 32)
printf "Here's a fresh MB_ENCRYPTION_SECRET_KEY: ${key}\n"

printf "Dev environment setup complete.\n"

printf "I created a new .env settings file.\n"


# sleep 3s


printf "Starting Syncurity Services....\n\n"
docker-compose up -d

printf "\nBrowse to http://localhost:3000 to setup metabase\n\n"

printf "docker-compose stop to turn off containers\n"
printf "docker-compose down [--volumes] to destroy containers (--volumes destroys backend)\n"
