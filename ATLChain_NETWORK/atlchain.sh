#!/bin/bash

export PATH=./bin:$PATH
export FABRIC_CFG_PATH=${PWD}

IMAGE_TAG1="1.4.4"
IMAGE_TAG2="0.4.18"

# compose 配置文件
DOCKER_COMPOSE_FILE_ORDERER="docker-compose-orderer.yaml"
DOCKER_COMPOSE_FILE_PEER="docker-compose-peer.yaml"
DOCKER_COMPOSE_FILE_CA="docker-compose-ca.yaml"
DOCKER_COMPOSE_FILE_CLI="docker-compose-cli.yaml"

# 默认 compose 工程名
export COMPOSE_PROJECT_NAME=atlproj

function help() {
    echo "Usage: "
    echo "  command <mode>"
    echo "    <mode> - one of 'up', 'down', 'clean'"
    echo "      - 'up' - start up the network"
    echo "      - 'down' - shutdown the network"
    echo "      - 'clean' - clean all the files using by the networks"
}

# 安装前的准备
function prepareBeforeStart() {
    testRemoteHost

    # Untar bin package
    if [ ! -d "bin" ]; then
        if [ -f "bin.tar.xz" ]; then
            echo "extract binary files..."
            tar xvf bin.tar.xz
        fi
    fi
    export PATH=$PATH:$PWD/bin

    echo "正在检查远程主机docker镜像......"

    OLD_IFS="$IFS"
    IFS=" "

    # 向各节点复制启动前的检查脚本
    i=0
    while [ $i -lt ${#hosts[@]} ]; do
        hostArray=(${hosts[$i]})
        nodeNum=$(expr ${#hostArray[@]} - 1)
        while [ $nodeNum -ge 2 ]; do
            echo "    ==>${hostArray[$nodeNum]} CHECKING......"
            ssh root@${hostArray[$nodeNum]} " [ -d /var/local/hyperledger/fabric ] || mkdir -p /var/local/hyperledger/fabric "
            scp ./scripts/prepare-for-start.sh root@${hostArray[$nodeNum]}:/var/local/hyperledger/fabric/ >>log.log
            ssh root@${hostArray[$nodeNum]} " cd /var/local/hyperledger/fabric/ && bash prepare-for-start.sh | tee -a log.log "
            res=$?
            if [ $res -ne 0 ]; then
                echo " ERROR !!! 节点 ${hostArray[$nodeNum]} 环境准备失败，请查看日志。"
                exit 1
            fi
            echo "    ==>${hostArray[$nodeNum]} SUCCESS"
            let nodeNum--
        done
        let i++
    done

    IFS="$OLD_IFS"
}

# 测试远程主机是否可以正常登录
function testRemoteHost() {
    echo "正在测试远程登录......"

    OLD_IFS="$IFS"
    IFS=" "

    i=0
    while [ $i -lt ${#hosts[@]} ]; do
        hostArray=(${hosts[$i]})
        nodeNum=$(expr ${#hostArray[@]} - 1)
        while [ $nodeNum -ge 2 ]; do
            echo "    ==>${hostArray[$nodeNum]} CHECKING......"
            if [ ! $(ssh root@${hostArray[$nodeNum]} " pwd ") == "/root" ]; then
                echo "不能登录到 ${hostArray[$nodeNum]}，请配置该主机的 ssh 免密登录。"
                exit
            fi
            echo "    ==>${hostArray[$nodeNum]} SUCCESS"
            let nodeNum--
        done
        let i++
    done

    IFS="$OLD_IFS"
}

# 生成加密材料
function genCerts() {
    echo "正在生成初始密钥......"

    # 生成 crypto-config.yaml
    . ./scripts/crypto-config.sh
    genCryptoConfig

    if [ -d "crypto-config" ]; then
        rm -rf crypto-config
    fi
    cryptogen generate --config=./crypto-config.yaml >>./log.log
    res=$?
    if [ $res -ne 0 ]; then
        echo " ERROR !!! 生成加密材料失败，请查看日志。"
        exit 1
    fi
}

# 生成网络构件
function genChannelArtifacts() {
    echo "正在生成网络构件......"

    # 生成 configtx.yaml
    . ./scripts/configtx.sh
    genConfigtx

    if [ ! -d "./channel-artifacts" ]; then
        mkdir ./channel-artifacts
    fi

    i=0
    while [ $i -lt ${#sysChannelArrays[@]} ]; do
        sysArray=(${sysChannelArrays[$i]})
        channelid=$(echo ${sysArray[0]} | tr '[A-Z]' '[a-z]')
        configtxgen -profile ${sysArray[0]} -channelID $channelid -outputBlock ./channel-artifacts/genesis.block >>./log.log 2>&1
        res=$?
        if [ $res -ne 0 ]; then
            echo " ERROR !!! 生成系统通道 ${sysArray[0]} 创世区块失败，请查看日志。"
            exit 1
        fi
        let i++
    done

    echo "PeerOrgs:" >>crypto-config.yaml
    i=0
    while [ $i -lt ${#appchannelArrays[@]} ]; do
        appArray=(${appchannelArrays[$i]})
        channelid=$(echo ${appArray[0]} | tr '[A-Z]' '[a-z]')
        configtxgen -profile ${appArray[0]} -outputCreateChannelTx ./channel-artifacts/${channelid}.tx -channelID ${channelid} >>./log.log 2>&1
        res=$?
        if [ $res -ne 0 ]; then
            echo " ERROR !!! 生成应用通道 ${appArray[0]} 创世区块失败，请查看日志。"
            exit 1
        fi
        string=${appArray[1]}
        array=(${string//,/ })
        for var in ${array[@]}; do
            configtxgen -profile ${appArray[0]} -outputAnchorPeersUpdate ./channel-artifacts/${var}anchors.tx -channelID ${channelid} -asOrg $var >>./log.log 2>&1
            res=$?
            if [ $res -ne 0 ]; then
                echo " ERROR !!! 生成组织 $var 锚节点更新交易失败，请查看日志。"
                exit 1
            fi
        done
        let i++
    done
}

function distributeFiles() {
    ## TODO 删除其他组织的的私钥
    ## TODO 只向对应的节点发送 docker-compose YAML 文件
    echo "正在向远程主机复制相关文件......"

    OLD_IFS="$IFS"
    IFS=" "

    i=0
    while [ $i -lt ${#hosts[@]} ]; do
        hostArray=(${hosts[$i]})
        nodeNum=$(expr ${#hostArray[@]} - 1)
        while [ $nodeNum -ge 2 ]; do
            url=${hostArray[$nodeNum]}
            echo "    ==>$url COPYING......"
            ssh root@$url " [ -d /var/local/hyperledger/fabric/conf ] || mkdir -p /var/local/hyperledger/fabric/conf "
            ssh root@$url " [ -d /var/local/hyperledger/fabric/channel-artifacts ] || mkdir -p /var/local/hyperledger/fabric/channel-artifacts "
            scp -r ./crypto-config root@$url:/var/local/hyperledger/fabric/ >>log.log
            scp -r ./conf/hosts root@$url:/var/local/hyperledger/fabric/conf/hosts >>log.log
            scp ./channel-artifacts/genesis.block root@$url:/var/local/hyperledger/fabric/channel-artifacts/genesis.block >>log.log
            scp -r ./docker-compose-conf root@$url:/var/local/hyperledger/fabric/ >>log.log
            echo "    ==>$url DONE"
            let nodeNum--
        done
        let i++
    done

    IFS="$OLD_IFS"
}

function startNodes() {
    echo "启动节点......"

    echo "    ==>cli"
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ./docker-compose-conf/${DOCKER_COMPOSE_FILE_CLI} up -d

    OLD_IFS="$IFS"
    IFS=" "

    i=0
    while [ $i -lt ${#hosts[@]} ]; do
        hostArray=(${hosts[$i]})
        echo ${hostArray[@]}

        mspid=${hostArray[0]}
        orgurl=${hostArray[1]}
        nodeNum=$(expr ${#hostArray[@]} - 1)
        while [ $nodeNum -ge 2 ]; do
            url=${hostArray[$nodeNum]}
            echo "    ==>节点 $url STARTING......"
            if [ "orderer" == ${url:0:7} ]; then
                ssh root@$url " cd  /var/local/hyperledger/fabric && LOCALMSPID=$mspid NODENAME=$url ORGURL=$orgurl IMAGETAG1=$IMAGE_TAG1 docker-compose -f ./docker-compose-conf/${DOCKER_COMPOSE_FILE_ORDERER} up -d "
            elif [ "peer" == ${url:0:4} ]; then
                ssh root@$url " cd /var/local/hyperledger/fabric && LOCALMSPID=$mspid NODENAME=$url ORGURL=$orgurl IMAGETAG1=$IMAGE_TAG1 IMAGETAG2=$IMAGE_TAG2 docker-compose -f ./docker-compose-conf/${DOCKER_COMPOSE_FILE_PEER} up -d "
            else
                key=$(ls crypto-config/peerOrganizations/$orgurl/ca | sed -n '/_sk/p')
                cert=$(ls crypto-config/peerOrganizations/$orgurl/ca | sed -n '/.pem/p')
                ssh root@$url " cd /var/local/hyperledger/fabric && NODENAME=$url ORGURL=$orgurl KEY=$key CERT=$cert IMAGETAG1=$IMAGE_TAG1 docker-compose -f ./docker-compose-conf/${DOCKER_COMPOSE_FILE_CA} up -d "
            fi
            echo "    ==>$url STARTED"
            echo 
            let nodeNum--
        done
        let i++
    done

    IFS="$OLD_IFS"
}

function operatePeers() {
    docker exec cli sh -c "cd scripts && ./script.sh"
}

function stopNodes() {
    echo "停止节点......"

    OLD_IFS="$IFS"
    IFS=" "

    i=0
    while [ $i -lt ${#hosts[@]} ]; do
        hostArray=(${hosts[$i]})
        echo ${hostArray[@]}

        orgurl=${hostArray[1]}
        nodeNum=$(expr ${#hostArray[@]} - 1)
        while [ $nodeNum -ge 2 ]; do
            url=${hostArray[$nodeNum]}
            echo "    ==>节点 $url STOPPING......"
            if [ "orderer" == ${url:0:7} ]; then
                ssh root@$url " cd  /var/local/hyperledger/fabric && NODENAME=$url ORGURL=$orgurl IMAGETAG1=$IMAGE_TAG1 docker-compose -f ./docker-compose-conf/${DOCKER_COMPOSE_FILE_ORDERER} down "
            elif [ "peer" == ${url:0:4} ]; then
                ssh root@$url " cd /var/local/hyperledger/fabric && NODENAME=$url ORGURL=$orgurl IMAGETAG1=$IMAGE_TAG1 IMAGETAG2=$IMAGE_TAG2 docker-compose -f ./docker-compose-conf/${DOCKER_COMPOSE_FILE_PEER} down "
            else
                key=$(ls crypto-config/peerOrganizations/$orgurl/ca | sed -n '/_sk/p')
                cert=$(ls crypto-config/peerOrganizations/$orgurl/ca | sed -n '/.pem/p')
                ssh root@$url " cd /var/local/hyperledger/fabric && NODENAME=$url ORGURL=$orgurl KEY=$key CERT=$cert IMAGETAG1=$IMAGE_TAG1 docker-compose -f ./docker-compose-conf/${DOCKER_COMPOSE_FILE_CA} down "
            fi
            echo "    ==>$url STOPPED"
            echo 
            let nodeNum--
        done
        let i++
    done

    IFS="$OLD_IFS"

    echo "    ==>cli"
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ./docker-compose-conf/${DOCKER_COMPOSE_FILE_CLI} down
}

# 删除生成的文件
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

echo
echo "   _____                                             "
echo "  / ____|                                            "
echo " | (___  _   _ _ __   ___ _ __ _ __ ___   __ _ _ __  "
echo "  \___ \| | | | '_ \ / _ \ '__| '_ \` _ \ / _\` | '_ \ "
echo "  ____) | |_| | |_) |  __/ |  | | | | | | (_| | |_) |"
echo " |_____/ \__,_| .__/ \___|_|  |_| |_| |_|\__,_| .__/ "
echo "              | |                             | |    "
echo "              |_|                             |_|    "
echo

MODE=$1
shift
. ./scripts/readConf.sh 
readConf ./conf/conf.conf
if [ "$MODE" == "up" ]; then
    prepareBeforeStart
    genCerts
    genChannelArtifacts
    distributeFiles
    startNodes
    operatePeers
elif [ "$MODE" == "down" ]; then
    stopNodes
elif [ "$MODE" == "clean" ]; then
    # TODO 清理远程主机
    cleanFiles
else
    help
    exit 1
fi
