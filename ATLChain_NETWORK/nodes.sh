#!/bin/bash

IMAGE_TAG1="amd64-1.4.3"
IMAGE_TAG2="amd64-0.4.15"

#compose files
DOCKER_COMPOSE_FILE_ORDERER="docker-compose-orderer.yaml"
DOCKER_COMPOSE_FILE_PEER="docker-compose-peer.yaml"
DOCKER_COMPOSE_FILE_CA="docker-compose-ca.yaml"
DOCKER_COMPOSE_FILE_CLI="docker-compose-cli.yaml"

# default compose project name
export COMPOSE_PROJECT_NAME=atlproj

function startOrderers() {
    echo "启动排序节点......"
    index=0
    hostArray=()
    while read line; do
        if [ ! $line == "" ]; then
            hostArray[$index]=$line
        else
            continue
        fi
        index=$(expr $index + 1)
    done <./conf/remoteHosts.conf


    length=${#hostArray[@]}
    while (($length > 0)); do
        if [ "orderer" == ${hostArray[$(expr $length - 1)]:0:7} ]; then
            echo "    ==>${hostArray[$(expr $length - 1)]}"
            set -x
            ssh root@${hostArray[$(expr $length - 1)]} " cd /var/local/hyperledger/fabric && NODENAME=${hostArray[$(expr $length - 1)]} IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_ORDERER} up -d "
            set +x
        fi
        length=$(expr $length - 1)
    done
}

function startPeers() {
        echo "启动排序节点......"
    index=0
    hostArray=()
    while read line; do
        if [ ! $line == "" ]; then
            hostArray[$index]=$line
        else
            continue
        fi
        index=$(expr $index + 1)
    done <./conf/remoteHosts.conf


    length=${#hostArray[@]}
    while (($length > 0)); do
        if [ "peer" == ${hostArray[$(expr $length - 1)]:0:4} ]; then
            echo "    ==>${hostArray[$(expr $length - 1)]}"
            set -x
            ssh root@${hostArray[$(expr $length - 1)]} " cd /var/local/hyperledger/fabric && NODENAME=${hostArray[$(expr $length - 1)]} IMAGETAG1=$IMAGE_TAG1 IMAGETAG2=$IMAGE_TAG2 docker-compose -f ${DOCKER_COMPOSE_FILE_PEER} up -d >> log.log 2>&1"
            set +x
        fi
        length=$(expr $length - 1)
    done
    
}

function startCAs() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CA} up -d >> log.log 2>&1
}

function stopOrderers() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_ORDERER} down # >> log.log 2>&1
}

function stopPeers() {
    IMAGETAG1=$IMAGE_TAG1 IMAGETAG2=$IMAGE_TAG2 docker-compose -f ${DOCKER_COMPOSE_FILE_PEER} down >> log.log 2>&1
}

function stopCAs() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CA} down >> log.log 2>&1
}