#!/bin/bash

export PATH=./bin:$PATH
export FABRIC_CFG_PATH=${PWD}

IMAGE_TAG1="1.4.3"
IMAGE_TAG2="0.4.15"

#compose files
DOCKER_COMPOSE_FILE_ORDERER="docker-compose-orderer.yaml"
DOCKER_COMPOSE_FILE_PEER="docker-compose-peer.yaml"
DOCKER_COMPOSE_FILE_CA="docker-compose-ca.yaml"
DOCKER_COMPOSE_FILE_CLI="docker-compose-cli.yaml"

# default compose project name
export COMPOSE_PROJECT_NAME=atlproj

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
    cryptogen generate --config=./crypto-config.yaml >>./log.log 2>&1
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
            configtxgen -profile $value -channelID $channelid -outputBlock ./channel-artifacts/genesis.block >>./log.log 2>&1
        elif [ $varSwitch == "app" ]; then
            channelid=$(echo $value | tr '[A-Z]' '[a-z]')
            configtxgen -profile $value -outputCreateChannelTx ./channel-artifacts/${channelid}.tx -channelID ${channelid} >>./log.log 2>&1
            string=$(echo $line | awk '{print $2}')
            array=(${string//,/ })
            for var in ${array[@]}; do
                configtxgen -profile $value -outputAnchorPeersUpdate ./channel-artifacts/${var}anchors.tx -channelID ${channelid} -asOrg $var >>./log.log 2>&1
            done
        fi
    done <./conf/channel.conf
}

# 安装前的准备
function prepare() {
    testRemoteHost

    echo "正在检查远程主机docker镜像......"
    index=0
    hostArray=()
    while read line; do
        if [ ! "$line" == "" ]; then
            hostArray[$index]=$line
        else
            continue
        fi
        index=$(expr $index + 1)
    done <./conf/remoteHosts.conf

    length=${#hostArray[@]}
    while (($length > 0)); do
        echo "    ==>${hostArray[$(expr $length - 1)]}"
        scp prepare-for-start.sh root@${hostArray[$(expr $length - 1)]}:/root >>log.log
        ssh root@${hostArray[$(expr $length - 1)]} " bash prepare-for-start.sh "
        length=$(expr $length - 1)
    done
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
        url=${hostArray[$(expr $length - 1)]}

        echo "    ==>$url"
        ssh root@$url " [ -d /var/local/hyperledger/fabric/conf ] || mkdir -p /var/local/hyperledger/fabric/conf "
        ssh root@$url " [ -d /var/local/hyperledger/fabric/channel-artifacts ] || mkdir -p /var/local/hyperledger/fabric/channel-artifacts "
        scp -r ./crypto-config root@$url:/var/local/hyperledger/fabric/ >>log.log
        scp -r ./conf/hosts root@$url:/var/local/hyperledger/fabric/conf/hosts >>log.log
        scp -r ./channel-artifacts/genesis.block root@$url:/var/local/hyperledger/fabric/channel-artifacts/genesis.block >>log.log
        scp ./$DOCKER_COMPOSE_FILE_CA ./$DOCKER_COMPOSE_FILE_PEER ./$DOCKER_COMPOSE_FILE_ORDERER root@$url:/var/local/hyperledger/fabric/ >>log.log
        length=$(expr $length - 1)
    done
}

function startNodes() {
    echo "启动节点......"

    echo "    ==>cli"
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CLI} up -d

    index=0
    hostArray=()
    while read line; do
        host=$(echo $line | awk '{print $2}')
        if [ ! "$host" == "" ]; then
            hostArray[$index]=$host
        else
            continue
        fi
        index=$(expr $index + 1)
    done <./conf/hosts

    length=${#hostArray[@]}
    while (($length > 0)); do
        url=${hostArray[$(expr $length - 1)]}
        idx=$(expr index $url '.')
        orgurl=${url:$idx}
        if [ "orderer" == ${url:0:7} ]; then
            echo "    ==>$url"
            ssh root@${hostArray[$(expr $length - 1)]} " cd /var/local/hyperledger/fabric && NODENAME=$url ORGURL=$orgurl IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_ORDERER} up -d "
        elif [ "peer" == ${url:0:4} ]; then
            echo "    ==>$url"
            ssh root@$url " cd /var/local/hyperledger/fabric && NODENAME=$url ORGURL=$orgurl IMAGETAG1=$IMAGE_TAG1 IMAGETAG2=$IMAGE_TAG2 docker-compose -f ${DOCKER_COMPOSE_FILE_PEER} up -d"
        elif [ "ca" == ${url:0:2} ]; then
            echo "    ==>$url"
            key=$(ls crypto-config/peerOrganizations/$orgurl/ca | sed -n '/_sk/p')
            cert=$(ls crypto-config/peerOrganizations/$orgurl/ca | sed -n '/.pem/p')
            ssh root@$url " cd /var/local/hyperledger/fabric && NODENAME=$url ORGURL=$orgurl KEY=$key CERT=$cert IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CA} up -d "
        fi
        length=$(expr $length - 1)
    done
}

function stopNodes() {
    echo "停止节点......"

    index=0
    hostArray=()
    while read line; do
        host=$(echo $line | awk '{print $2}')
        if [ ! "$host" == "" ]; then
            hostArray[$index]=$host
        else
            continue
        fi
        index=$(expr $index + 1)
    done <./conf/hosts

    length=${#hostArray[@]}
    while (($length > 0)); do
        url=${hostArray[$(expr $length - 1)]}
        idx=$(expr index $url '.')
        orgurl=${url:$idx}
        if [ "orderer" == ${url:0:7} ]; then
            echo "    ==>$url"
            ssh root@${hostArray[$(expr $length - 1)]} " cd /var/local/hyperledger/fabric && NODENAME=$url ORGURL=$orgurl IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_ORDERER} down "
        elif [ "peer" == ${url:0:4} ]; then
            echo "    ==>$url"
            ssh root@$url " cd /var/local/hyperledger/fabric && NODENAME=$url ORGURL=$orgurl IMAGETAG1=$IMAGE_TAG1 IMAGETAG2=$IMAGE_TAG2 docker-compose -f ${DOCKER_COMPOSE_FILE_PEER} down "
        elif [ "ca" == ${url:0:2} ]; then
            echo "    ==>$url"
            set -x
            key=$(ls crypto-config/peerOrganizations/$orgurl/ca | sed -n '/_sk/p')
            cert=$(ls crypto-config/peerOrganizations/$orgurl/ca | sed -n '/.pem/p')
            ssh root@$url " cd /var/local/hyperledger/fabric && NODENAME=$url ORGURL=$orgurl KEY=$key CERT=$cert IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CA} down "
            set +x
        fi
        length=$(expr $length - 1)
    done

    echo "    ==>cli"
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CLI} down
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

function addOrg() {
    cryptogen generate --config=./orgc-crypto.yaml
    configtxgen -printOrg OrgC >./channel-artifacts/orgc.json
}

MODE=$1
shift
if [ "$MODE" == "up" ]; then
    prepare
    genCerts
    genChannelArtifacts
    distributeFiles
    startNodes
elif [ "$MODE" == "down" ]; then
    stopNodes
elif [ "$MODE" == "clean" ]; then
    # TODO 清理远程主机
    cleanFiles
# elif [ "$MODE" == "addorg" ]; then
#     addOrg
else
    help
    exit 1
fi
