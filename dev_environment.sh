#!/bin/bash -e

echo "Setup dev environment for docker metabase use"

# Mac OS X setup
if [ "$(uname)" == "Darwin" ]; then

    # Check to see if Homebrew is installed, and install it if it is not
    command -v brew >/dev/null 2>&1 || { echo >&2 "Installing Homebrew Now"; \
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; }

    # install Docker and docker tools
    brew cask install docker kitematic
    brew install docker-compose docker-machine xhyve docker-machine-driver-xhyve bash-completion gnu-sed

    # allow xhyve to run as root
    sudo chown root:wheel $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
    sudo chmod u+s $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve

    # End Mac Docker Setup

    # Check for and install vagrant if needed
    vagrant_version="$(brew cask ls --versions vagrant)"
    if [ ! -z "$vagrant_version" ]; then
      echo "Found $vagrant_version, skipping install"
    else
      echo "Installing vagrant"
      brew cask install vagrant
    fi

    # End OSX Setup


# Adding some vagrant plugins
# vagrant plugin install vagrant-triggers

fi

printf "moving .env into place from template\n"
cp env.template .env
source ".env"

printf "Dev environment setup complete\n"

if [[ -z $MB_ENCRYPTION_SECRET_KEY ]]; then

    printf "Generating Encryption Key"
    key=$(openssl rand -base64 32)

    # replace / with @ for sed (https://stackoverflow.com/questions/32252458/how-to-pass-base64-ecoded-content-to-sed)
    if [ "$(uname)" == "Darwin" ]; then
        # gnu-sed on OSX
        gsed -i "s@MB_ENCRYPTION_SECRET_KEY.*@MB_ENCRYPTION_SECRET_KEY=${key}@g" \.env
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        # sed in linux
        sed -i "s@MB_ENCRYPTION_SECRET_KEY.*@MB_ENCRYPTION_SECRET_KEY=${key}@g" \.env
    fi

    printf "Here's a fresh MB_ENCRYPTION_SECRET_KEY: ${key}\n"
    printf "I created a new .env settings file and set your randomly generated encryption key.\n\n"

else
    printf "Using the encryption key already present in .env. To regenerate clear the MB_ENCRYPTION_SECRET_KEY in .env\n\n"
fi

read -p "Please enter quay.io user name:" quay_user
read -sp 'Please enter your Syncurity Image Key:' quay_key
docker login -u ${quay_user} -p ${quay_key} quay.io


printf "Starting Syncurity Metabase Reporting....\n\n"
echo "running docker-compose up -d"
docker-compose up -d

printf "\nBrowse to http://localhost:3000 to setup metabase\n\n"

printf "docker-compose stop to turn off containers\n"
printf "docker-compose down [--volumes] to destroy containers (--volumes destroys backend)\n"


