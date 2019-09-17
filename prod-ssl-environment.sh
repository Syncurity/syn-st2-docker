#!/bin/bash -e
# This script initializes the metabase stack.

# Debug function
function myecho {
  if [ ! -z "$DEBUG" ]; then
  echo "$*"
  fi
}


# Ensure we are running as irflow user
if [ "$(whoami)" == "irflow" ] || [ "$(whoami)" == "metabase" ] ; then
        echo "Starting Metabase..."
else
        echo "Script must be run as user: metabase or irflow"
        echo "run sudo su irflow"
        exit 1
fi

if [ "$(uname)" == "Darwin" ]; then
    printf "OSX detected. This script does not install docker and other tools needed to run properly.\n\n"
fi

if [ -f ".env" ]; then
    printf "found .env file. Proceeding with load\n"
else
    printf "moving .env into place from template\n Please configure user settings in here \n\n"
    cp env.template .env
fi

source .env
# source ansible/vault.yml

if [[ ! -d certs ]]; then
    mkdir certs
fi

if [[ -z "$(ls -A certs)" ]]; then
    echo "You chose the ssl cert config, but there are no certs in the ./certs directory"
    echo "Run bin/create_self_signed_cert.sh or copy a certficate into the ./certs directory"
    exit 1
fi

if [[ -z $MB_ENCRYPTION_SECRET_KEY ]]; then

    printf "Generating Encryption Key \n\n"
    key=$(openssl rand -base64 32)

    # replace / with @ for sed (https://stackoverflow.com/questions/32252458/how-to-pass-base64-ecoded-content-to-sed)
    if [ "$(uname)" == "Darwin" ]; then
        # gnu-sed on OSX
        gsed -i "s@MB_ENCRYPTION_SECRET_KEY.*@MB_ENCRYPTION_SECRET_KEY=${key}@g" \.env
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        # sed in linux
        sed -i "s@MB_ENCRYPTION_SECRET_KEY.*@MB_ENCRYPTION_SECRET_KEY=${key}@g" \.env
    fi

    echo "Here's a fresh MB_ENCRYPTION_SECRET_KEY: ${key}" && echo
    printf "I created a new .env settings file and set your randomly generated encryption key.\n\n"

else
    printf "Using the encryption key already present in .env. To regenerate clear the MB_ENCRYPTION_SECRET_KEY in .env\n\n"
fi

# only bother with SELF_SIGNED_CERT if CA_SIGNED_CERT is missing

# debug echo cert env variables
myecho "${CA_SIGNED_CERT}"
myecho "${SELF_SIGNED_CERT}"

if [[ ! ${CA_SIGNED_CERT} ]]; then
  if [[ ${SELF_SIGNED_CERT: -4} == ".jks" ]]; then
      # Convert to PKCS12 Keystore (Removes many error messages
      echo "Converting from JKS to PKCS12 keystore"
      keytool -importkeystore \
              -srckeystore certs/selfsigned.jks \
              -destkeystore certs/selfsigned.keystore \
              -deststoretype pkcs12 \
              -srcstorepass "${MB_JETTY_SSL_Keystore_Password}" \
              -deststorepass "${MB_JETTY_SSL_Keystore_Password}"

      # update .env with new keystore name
      if [[ "$?" -eq 1 ]]; then
          sed -i "s@$SELF_SIGNED_CERT.*@$SELF_SIGNED_CERT=certs/selfsigned.keystore@g" \.env
          sed -i "s@MB_JETTY_SSL_Keystore.*@MB_JETTY_SSL_Keystore=certs/selfsigned.keystore@g" \.env
          echo "Keystore conversion complete"
      elif [[ "$?" -ne 0 ]]; then
          # Warn if keystore conversion failed
          echo "Conversion to PKCS12 failed. Contact support"
      fi
  fi
fi

# Login to docker if desired
if [[ ! -z $1 ]] && [[ "${1}" = "--login" ]]; then
    # Read in  Syncurity quay.io robot token
    read -p 'Enter your quay.io username:' QUAY_USER
    read -sp 'Please enter your Syncurity Image Key:' QUAY_KEY
    docker login -u "$QUAY_USER" -p "$QUAY_KEY" quay.io
fi

# Start metabase stack
printf "Starting Syncurity Metabase Reporting....\n\n"
docker-compose -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.prod.sslcert.yml up -d

printf "\nBrowse to http://localhost:3000 to setup metabase\n"
printf "\nBrowse to https://localhost:8443 to setup metabase\n\n"

printf "docker-compose stop to turn off containers\n"
printf "docker-compose down [--volumes] to destroy containers [--volumes destroys backend]\n"


# Import ssl cert to docker volume
if [[ -f $CA_SIGNED_CERT ]]; then
        container_id="$(docker ps | grep syncurity/metabase | cut -d' ' -f1)"
        echo "Found CA signed certificate. Loading..."
        echo "docker cp ${CA_SIGNED_CERT} ${container_id}:${MB_JETTY_SSL_Keystore}"
        if docker cp "${CA_SIGNED_CERT}" "${container_id}:${MB_JETTY_SSL_Keystore}"
        then
          echo "CA Signed Cert loaded!"
        fi
elif [ -f "$SELF_SIGNED_CERT" ]; then
    container_id="$(docker ps | grep syncurity/metabase | cut -d' ' -f1)"
    echo "docker cp ${SELF_SIGNED_CERT} ${container_id}:${MB_JETTY_SSL_Keystore}"
    docker cp "${SELF_SIGNED_CERT}" "${container_id}:${MB_JETTY_SSL_Keystore}"
else
    echo "Keystore not found. Unable to run in SSL mode."
    exit 1
fi

unset -v MB_DB_DBNAME MB_DB_PASS MB_ENCRYPTION_SECRET_KEY MB_JETTY_SSL_Keystore_Password POSTGRESQL_ADMIN_PASSWORD

#Show container environment
sleep 7 && docker ps

echo "Waiting for Metabase to come up..."
sleep 20
docker logs metabase_postgresql
docker logs metabase_web

# while not docker logs metabase_web | grep
until [ "docker logs metabase_web | grep COMPLETE" ]; do
    print "$(docker logs metabase_web | grep COMPLETE)"
done

echo "Metabase setup successful."
echo
docker ps
echo

# Print key to stdout if it was generated.
if [[ "${key}" ]]; then
  echo
  echo "A new encryption key was generated. You probably want to back this up somewhere safe:"
  echo
  echo "Metabase Encryption Key: ${key}"
  echo
fi

echo "You can login to at https://0.0.0.0:8443"
