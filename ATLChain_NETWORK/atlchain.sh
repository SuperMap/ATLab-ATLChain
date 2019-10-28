#!/bin/bash

export PATH=./bin:$PATH
export FABRIC_CFG_PATH=${PWD}

. ./nodes.sh

function help() {
    echo "Usage: "
    echo "  command <mode>"
    echo "    <mode> - one of 'up', 'down', 'clean'"
    echo "      - 'up' - start up the network"
    echo "      - 'down' - shutdown the network"
    echo "      - 'clean' - clean all the files using by the networks"
}

function genCerts() {
    echo "正在生成初始密钥......"

    # generate crypto-config.yaml
    ./crypto-config.sh

    if [ -d "crypto-config" ]; then
        rm -rf crypto-config
    fi
    cryptogen generate --config=./crypto-config.yaml >> ./log.log 2>&1
}

function genChannelArtifacts() {
    echo "正在生成通道构件......"

    # 生成 configtx.yaml
    ./configtx.sh

    if [ ! -d "./channel-artifacts" ]; then
        mkdir ./channel-artifacts
    fi

    # 获取设置的系统通道名
    while read line; do
        value=$(echo $line | awk '{print $1}')
        if [ $value == "SystemChannel:" ]; then
            varSwitch="system"
            continue
        elif [ $value == "ApplicationChannel:" ]; then
            varSwitch="app"
            continue
        fi

        if [ $varSwitch == "system" ]; then
            channelid=$(echo $value | tr '[A-Z]' '[a-z]')
            configtxgen -profile $value -channelID $channelid -outputBlock ./channel-artifacts/genesis.block >> ./log.log 2>&1
        elif [ $varSwitch == "app" ]; then
            channelid=$(echo $value | tr '[A-Z]' '[a-z]')
            configtxgen -profile $value -outputCreateChannelTx ./channel-artifacts/${channelid}.tx -channelID ${channelid} >> ./log.log 2>&1
            string=$(echo $line | awk '{print $2}')
            array=(${string//,/ })  
            for var in ${array[@]}
            do       
                configtxgen -profile $value -outputAnchorPeersUpdate ./channel-artifacts/${var}anchors.tx -channelID ${channelid} -asOrg $var >> ./log.log 2>&1
            done
        fi
    done <./conf/channel.conf
}

# Start a CLI peer container for operation
function startCLI() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CLI} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start CLI node"
        exit 1
    fi
}

# Remove the files generated
function cleanFiles() {
    if [ -d "./crypto-config" ]; then
        rm -rf crypto-config
    fi
    if [ -d "./channel-artifacts" ]; then
        rm -rf channel-artifacts
    fi
    if [ -d "./production" ]; then
        rm -rf production
    fi
}

function stopCLI() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CLI} down 2>&1
}

function addOrg() {
    cryptogen generate --config=./orgc-crypto.yaml
    configtxgen -printOrg OrgC >./channel-artifacts/orgc.json
}

# 测试远程主机是否可以正常登录
function testRemoteHost() {
    echo "正在测试远程登录......"
    index=0
    hostArray=()
    while read line; do
        host=$(echo $line | awk '{print $3}')
        if [ ! $line == "" ]; then
            hostArray[$index]=$line
        else
            continue
        fi
        index=$(expr $index + 1)
    done <./conf/remoteHosts.conf

    length=${#hostArray[@]}
    while (($length > 0)); do
        if [ ! $(ssh root@${hostArray[$(expr $length - 1)]} " pwd ") = "/root" ]; then
            echo "不能登录到 ${hostArray[$(expr $length - 1)]}，请配置该主机的 ssh 免密登录。"
            exit
        fi
        length=$(expr $length - 1)
    done
}

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
    testRemoteHost

    # Download docker images
    echo "正在下载 Docker 镜像......"
    downloadImages
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to download docker images"
        exit 1
    fi

    # Untar bin package
    if [ ! -d "bin" ]; then
        echo "extract binary files..."
        tar xvf bin.tar.xz
    fi

    if [ ! -d "production" ]; then
        mkdir production
    fi
}

function distributeFiles() {
    ## TODO 删除其他组织的的私钥
    echo "正在向远程主机复制相关文件......"

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
        echo "==>${hostArray[$(expr $length - 1)]}"
        ssh root@${hostArray[$(expr $length - 1)]} " [ -d /var/local/hyperledger/fabric/conf ] || mkdir -p /var/local/hyperledger/fabric/conf "
        ssh root@${hostArray[$(expr $length - 1)]} " [ -d /var/local/hyperledger/fabric/channel-artifacts ] || mkdir -p /var/local/hyperledger/fabric/channel-artifacts "
        scp -r ./crypto-config root@${hostArray[$(expr $length - 1)]}:/var/local/hyperledger/fabric/ >> log.log
        scp -r ./conf/hosts root@${hostArray[$(expr $length - 1)]}:/var/local/hyperledger/fabric/conf/hosts >> log.log
        scp -r ./channel-artifacts/genesis.block root@${hostArray[$(expr $length - 1)]}:/var/local/hyperledger/fabric/channel-artifacts/genesis.block >> log.log
        scp ./$DOCKER_COMPOSE_FILE_CA ./$DOCKER_COMPOSE_FILE_PEER ./$DOCKER_COMPOSE_FILE_ORDERER root@${hostArray[$(expr $length - 1)]}:/var/local/hyperledger/fabric/ >> log.log
        length=$(expr $length - 1)
    done
}

MODE=$1
shift
# Determine whether starting or stopping
if [ "$MODE" == "up" ]; then
    prepareForStart
    genCerts
    genChannelArtifacts
    distributeFiles
    startOrderers
    # startPeers
    # startCAs
    # startCLI
elif [ "$MODE" == "down" ]; then
    # stopCLI
    # stopCAs
    # stopPeers
    stopOrderers
elif [ "$MODE" == "clean" ]; then
    cleanFiles
elif [ "$MODE" == "addorg" ]; then
    addOrg
else
    help
    exit 1
fi
