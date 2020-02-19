# syn-st2-docker

This repo contains the docker-compose files needed to run different Syncurity provided services
 in Stackstorm. 
 
See the env.template for the environment variables needed for each service.

## Setup


 
## Docker Network
 
## Services

### PostGres DB Container

This service is used to support sensors that have data to store that is too big for the st2
 datastore. This container is seeded with the `syn_st2_datastore` database which persists to
  disk.

Packs which use this service:

    - syncurity-netskope
  
### Blocklist container

This container runs a flask + gunicorn instance on port `0.0.0.0:8081` which serves up Palo Alto
 or Checkpoint blocklist files.

    * Checkpoint:
        - http://0.0.0.0/static/checkpoint/domain_list.csv
        - http://0.0.0.0/static/checkpoint/ip_block.txt
    * Palo Alto Dynamic Block Lists
        - http://0.0.0.0/static/paloalto/demo_ip_list.txt


Packs which use this service:

    - syncurity-checkpoint_ngfw
    - syncurity-paloalto_ngfw
