#!/usr/bin/env sh

COMPOSE_PROJECT=${FEASIBILITY_COMPOSE_PROJECT:-feasibility-deploy}

BASE_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

docker-compose -p $COMPOSE_PROJECT -f $BASE_DIR/aktin-client/docker-compose.yml stop
docker-compose -p $COMPOSE_PROJECT -f $BASE_DIR/flare/docker-compose.yml stop
docker-compose -p $COMPOSE_PROJECT -f $BASE_DIR/fhir-server/blaze-server/docker-compose.yml stop
docker-compose -p $COMPOSE_PROJECT -f $BASE_DIR/fhir-server/hapi-fhir-server/docker-compose.yml stop
docker-compose -p $COMPOSE_PROJECT -f $BASE_DIR/rev-proxy/docker-compose.yml stop
sh $BASE_DIR/dsf-client/stop.sh $COMPOSE_PROJECT
