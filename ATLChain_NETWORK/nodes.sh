#!/bin/bash

CHANNEL_NAME="atlchannel"
ORG_DOMAIN_NAME="orga.example.com"
IMAGE_TAG1="amd64-1.4.3"
IMAGE_TAG2="amd64-0.4.15"

#compose files
DOCKER_COMPOSE_FILE_ORDERER="docker-compose-orderer.yaml"
DOCKER_COMPOSE_FILE_PEER="docker-compose-peer.yaml"
DOCKER_COMPOSE_FILE_CA="docker-compose-ca.yaml"
DOCKER_COMPOSE_FILE_CLI="docker-compose-cli.yaml"

# default compose project name
export COMPOSE_PROJECT_NAME=atlproj

export DOCKER_COMPOSE_PEER_ADDRESS=peer0.orga.example.com:7051
export DOCKER_COMPOSE_PEER_GOSSIP_BOOTSTRAP=peer0.orga.example.com:7051 

export CORE_PEER_ADDRESS=peer0.orga.example.com:7051 
export ORERER_ADDRESS=orderer1.example.com:7050

function startOrderer() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_ORDERER} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start orderer node"
        exit 1
    fi
}

function startPeer() {
    IMAGETAG1=$IMAGE_TAG1 IMAGETAG2=$IMAGE_TAG2 docker-compose -f ${DOCKER_COMPOSE_FILE_PEER} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start peer node"
        exit 1
    fi
}

function startCA() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CA} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start CA node"
        exit 1
    fi
}

function stopOrderer() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_ORDERER} down 2>&1
}

function stopPeer() {
    IMAGETAG1=$IMAGE_TAG1 IMAGETAG2=$IMAGE_TAG2 docker-compose -f ${DOCKER_COMPOSE_FILE_PEER} down 2>&1
}

function stopCA() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CA} down 2>&1
}