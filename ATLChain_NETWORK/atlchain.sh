#!/bin/bash

export PATH=./bin:$PATH
export FABRIC_CFG_PATH=${PWD}

IMAGE_TAG1="1.4.3"
IMAGE_TAG2="0.4.15"

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

# 读取配置文件
function readConf() {
    while read line || [[ -n $line ]]; do
        # 判断配置段落
        if [ "$line" == "" ]; then
            continue
        elif [ $(echo $line | awk '{print $1}') == "Orderer:" ]; then
            varSwitch="orderer"
            continue
        elif [ $(echo $line | awk '{print $1}') == "Peer:" ]; then
            varSwitch="peer"
            continue
        elif [ $(echo $line | awk '{print $1}') == "SystemChannel:" ]; then
            varSwitch="syschannel"
            continue
        elif [ $(echo $line | awk '{print $1}') == "ApplicationChannel:" ]; then
            varSwitch="appchannel"
            continue
        fi

        # 将配置内容读进数组
        if [ $varSwitch == "orderer" ]; then
            ordererOrgArrays[${#ordererOrgArrays[@]}]=$line
        elif [ $varSwitch == "peer" ]; then
            peerOrgArrays[${#peerOrgArrays[@]}]=$line
        elif [ $varSwitch == "syschannel" ]; then
            sysChannelArrays[${#sysChannelArrays[@]}]=$line
        elif [ $varSwitch == "appchannel" ]; then
            appchannelArrays[${#appchannelArrays[@]}]=$line
        fi
    done <./conf/conf.conf

    # 根据配置文件中的信息自动分解出组织及其节点的详细信息
    getHostsInfo
}

# 获取各个组织的域名、节点信息
function getHostsInfo() {
    hosts=()
    OLD_IFS="$IFS"
    IFS=" "

    # 获取 Orderer 及其所有节点的信息
    i=0
    while [ $i -lt ${#ordererOrgArrays[@]} ]; do
        array=(${ordererOrgArrays[$i]})
        nodeNum=$(expr ${array[2]} - 1)
        nodeHosts=""
        while [ $nodeNum -ge 0 ]; do
            nodeHosts="$nodeHosts orderer${nodeNum}.${array[1]}"
            let nodeNum--
        done

        hosts[${#hosts[@]}]="${array[0]} ${array[1]} $nodeHosts"
        let i++
    done

    # 获取 Peer 及其所有节点的信息
    i=0
    while [ $i -lt ${#peerOrgArrays[@]} ]; do
        array=(${peerOrgArrays[$i]})
        nodeNum=$(expr ${array[2]} - 1)
        nodeHosts=""
        while [ $nodeNum -ge 0 ]; do
            nodeHosts="$nodeHosts peer${nodeNum}.${array[1]}"
            let nodeNum--
        done

        # 获取 CA 节点信息
        caArray=(${array[7]//,/ })
        for var in ${caArray[@]}; do
            nodeHosts="$nodeHosts $var"
        done

        hosts[${#hosts[@]}]="${array[0]} ${array[1]} $nodeHosts"
        let i++
    done
    IFS="$OLD_IFS"
}

# 安装前的准备
function prepareBeforeStart() {
    testRemoteHost

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
            scp prepare-for-start.sh root@${hostArray[$nodeNum]}:/root >>log.log
            ssh root@${hostArray[$nodeNum]} " bash prepare-for-start.sh | tee -a log.log "
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
    . ./crypto-config.sh
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

# 生成通道构建
function genChannelArtifacts() {
    echo "正在生成通道构件......"

    # 生成 configtx.yaml
    . ./configtx.sh
    genConfigtx

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

function distributeFiles() {
    ## TODO 删除其他组织的的私钥
    echo "正在向远程主机复制相关文件......"

    index=1
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

    index=1
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

function operatePeers() {
    docker exec cli sh -c "scripts/script.sh"
    # docker exec cli sh -c "SYS_CHANNEL=$CH_NAME && scripts/upgrade_to_v14.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE"
}

function stopNodes() {
    echo "停止节点......"

    index=1
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

# TODO 添加组织
function addOrg() {
    cryptogen generate --config=./orgc-crypto.yaml
    configtxgen -printOrg OrgC >./channel-artifacts/orgc.json
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
readConf
if [ "$MODE" == "up" ]; then
    # prepareBeforeStart
    # genCerts
    genChannelArtifacts
    # distributeFiles
    # startNodes
    # operatePeers
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
