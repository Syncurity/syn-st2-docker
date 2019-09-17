#!/bin/bash -eu

if [ "$(uname)" == "Darwin" ]; then
    printf "OSX detected. This script does not install docker and other tools. Needed to run properly.\n\n"
fi

quay_user=${QUAY_USER}
quay_key=${QUAY_KEY}


printf "moving .env into place from template"
cp env.template .env

key=$(openssl rand -base64 32)
printf "Here's a fresh MB_ENCRYPTION_SECRET_KEY: ${key}\n"

# replace / with @ for sed (https://stackoverflow.com/questions/32252458/how-to-pass-base64-ecoded-content-to-sed)
if [ "$(uname)" == "Darwin" ]; then
    # gnu-sed on OSX
    gsed -i "s@MB_ENCRYPTION_SECRET_KEY.*@MB_ENCRYPTION_SECRET_KEY=${key}@g" \.env
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # sed in linux
    sed -i "s@MB_ENCRYPTION_SECRET_KEY.*@MB_ENCRYPTION_SECRET_KEY=${key}@g" \.env
fi

printf "Dev environment setup complete.\n"

printf "I created a new .env settings file and set your randomly generated encryption key.\n"
echo "Please write down your key:"
echo "${key}"

# sleep 3s

# read -p 'Enter your quay.io username:'  quay_user
# read -sp 'Please enter your Syncurity Image Key:' quay_key
docker login -u ${quay_user} -p ${quay_key} quay.io


printf "Starting Syncurity Metabase Reporting....\n\n"
docker-compose up -d

printf "\nBrowse to http://localhost:3000 to setup metabase\n\n"

printf "docker-compose stop to turn off containers\n"
printf "docker-compose down [--volumes] to destroy containers (--volumes destroys backend)\n"
