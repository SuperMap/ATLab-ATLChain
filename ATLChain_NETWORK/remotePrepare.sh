#!/bin/bash

# 远程主机启动网络前的准备工作

function downloadImages() {
    if [ !"$(docker images hyperledger/fabric-tools:amd64-1.4.3 -q)" == "18ed4db0cd57" ]; then
        docker pull hyperledger/fabric-tools:amd64-1.4.3
    fi

    if [ !"$(docker images hyperledger/fabric-ccenv:amd64-1.4.3 -q)" == "18ed4db0cd57" ]; then
        docker pull hyperledger/fabric-ccenv:amd64-1.4.3
    fi

    if [ !"$(docker images hyperledger/fabric-javaenv:amd64-1.4.3 -q)" == "18ed4db0cd57" ]; then
        docker pull hyperledger/fabric-javaenv:amd64-1.4.3
    fi

    if [ !"$(docker images hyperledger/fabric-orderer:amd64-1.4.3 -q)" == "18ed4db0cd57" ]; then
        docker pull hyperledger/fabric-orderer:amd64-1.4.3
    fi

    if [ !"$(docker images hyperledger/fabric-peer:amd64-1.4.3 -q)" == "18ed4db0cd57" ]; then
        docker pull hyperledger/fabric-peer:amd64-1.4.3
    fi

    if [ !"$(docker images hyperledger/fabric-ca:amd64-1.4.3 -q)" == "18ed4db0cd57" ]; then
        docker pull hyperledger/fabric-ca:amd64-1.4.3
    fi

    if [ !"$(docker images hyperledger/fabric-couchdb：amd64-0.4.15 -q)" == "18ed4db0cd57" ]; then
        docker pull hyperledger/fabric-couchdb：amd64-0.4.15
    fi

    if [ !"$(docker images hyperledger/fabric-baseos：amd64-0.4.15 -q)" == "18ed4db0cd57" ]; then
        docker pull hyperledger/fabric-baseos：amd64-0.4.15
    fi
}

function prepareForStart() {
    # Download docker images
    echo "Downloading docker images......"
    downloadImages
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to download docker images"
        exit 1
    fi

    if [ ! -d "production" ]; then
        mkdir production
    fi
}

prepareForStart