#!/bin/bash

# 远程主机启动网络前的准备工作
IMAGE_TAG1="1.4.4"
IMAGE_TAG2="0.4.15"

# 判断系统中是否存在 docker 镜像，没有就下载
function downloadImages() {
    if [ ! "$(docker images hyperledger/fabric-tools:$IMAGE_TAG1 -q)" == "7552e1968c0b" ]; then
        docker pull hyperledger/fabric-tools:$IMAGE_TAG1
    fi

    if [ ! "$(docker images hyperledger/fabric-ccenv:$IMAGE_TAG1 -q)" == "ca4780293e4c" ]; then
        docker pull hyperledger/fabric-ccenv:$IMAGE_TAG1
    fi

    if [ ! "$(docker images hyperledger/fabric-javaenv:$IMAGE_TAG1 -q)" == "4648059d209e" ]; then
        docker pull hyperledger/fabric-javaenv:$IMAGE_TAG1
    fi

    if [ ! "$(docker images hyperledger/fabric-orderer:$IMAGE_TAG1 -q)" == "dbc9f65443aa" ]; then
        docker pull hyperledger/fabric-orderer:$IMAGE_TAG1
    fi

    if [ ! "$(docker images hyperledger/fabric-peer:$IMAGE_TAG1 -q)" == "9756aed98c6b" ]; then
        docker pull hyperledger/fabric-peer:$IMAGE_TAG1
    fi

    if [ ! "$(docker images hyperledger/fabric-ca:$IMAGE_TAG1 -q)" == "62a60c5459ae" ]; then
        docker pull hyperledger/fabric-ca:$IMAGE_TAG1
    fi

    if [ ! "$(docker images hyperledger/fabric-couchdb:$IMAGE_TAG2 -q)" == "8de128a55539" ]; then
        docker pull hyperledger/fabric-couchdb:$IMAGE_TAG2
    fi

    if [ ! "$(docker images hyperledger/fabric-baseos:$IMAGE_TAG2 -q)" == "9d6ec11c60ff" ]; then
        docker pull hyperledger/fabric-baseos:$IMAGE_TAG2
    fi
}

# 启动前的准备工作
function prepareForStart() {
    # Download docker images
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
