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

# Generates Org certs using cryptogen tool
function genCerts() {
    # generate crypto-config.yaml
    ./crypto-config.sh

    which cryptogen
    if [ "$?" -ne 0 ]; then
        echo "cryptogen tool not found."
        exit 1
    fi
    echo
    echo "##########################################################"
    echo "##### Generate certificates using cryptogen tool #########"
    echo "##########################################################"

    if [ -d "crypto-config" ]; then
        rm -rf crypto-config
    fi
    set -x
    cryptogen generate --config=./crypto-config.yaml
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to generate certificates..."
        exit 1
    fi
    echo
}

# Generate Channel Artifacts used in the network
function genChannelArtifacts() {
    # generate configtx.yaml
    # ./configtx.sh

    which configtxgen
    if [ "$?" -ne 0 ]; then
        echo "configtxgen tool not found. exiting"
        exit 1
    fi

    if [ ! -d "./channel-artifacts" ]; then
        mkdir ./channel-artifacts
    fi

    echo "##########################################################"
    echo "#################  生成系统通道创世区块  ####################"
    echo "##########################################################"

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
            set -x
            configtxgen -profile $value -channelID $channelid -outputBlock ./channel-artifacts/genesis.block
            res=$?
            set +x
            if [ $res -ne 0 ]; then
                echo "Failed to generate orderer genesis block..."
                exit 1
            fi
        else
            break
        fi
    done < ./conf/channel.conf

    echo
    echo "##########################################################"
    echo "##################    生成通道配置交易    ##################"
    echo "##########################################################"
    set -x
    configtxgen -profile TxChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to generate channel configuration transaction..."
        exit 1
    fi

    echo
    echo "##########################################################"
    echo "##################    生成更新锚节点交易    #################"
    echo "##########################################################"
    set -x
    configtxgen -profile TxChannel -outputAnchorPeersUpdate ./channel-artifacts/OrgAanchors.tx -channelID $CHANNEL_NAME -asOrg OrgA
    configtxgen -profile TxChannel -outputAnchorPeersUpdate ./channel-artifacts/OrgBanchors.tx -channelID $CHANNEL_NAME -asOrg OrgB
    configtxgen -profile TxChannel -outputAnchorPeersUpdate ./channel-artifacts/OrgCanchors.tx -channelID $CHANNEL_NAME -asOrg OrgC
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to generate anchor peer update for Org..."
        exit 1
    fi
    echo
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

    # Untar bin package
    if [ ! -d "bin" ]; then
        echo "extract binary files..."
        tar xvf bin.tar.xz
    fi

    if [ ! -d "production" ]; then
        mkdir production
    fi
}

function distributeCerts() {
    ## TODO 删除其他组织的的私钥
    echo "Distributing certs to orgs..."

    index=0
    hostArray=()
    while read line; do
        host=$(echo $line | awk '{print $3}')
        if [ ! $host == "" ]; then
            hostArray[$index]=$host
        else
            continue
        fi
        index=$(expr $index + 1)
    done <./conf/orgs.conf

    length=${#hostArray[@]}
    while (($length > 0)); do
        ssh root@${hostArray[$(expr $length - 1)]} " [ -d /var/local/hyperledger/fabric/msp ] || mkdir -p /var/local/hyperledger/fabric/msp "
        scp -r ./crypto-config root@${hostArray[$(expr $length - 1)]}:/var/local/hyperledger/fabric/msp/
        scp ./$DOCKER_COMPOSE_FILE_CA ./$DOCKER_COMPOSE_FILE_PEER ./$DOCKER_COMPOSE_FILE_ORDERER root@${hostArray[$(expr $length - 1)]}:/var/local/hyperledger/fabric/
        length=$(expr $length - 1)
    done
}

MODE=$1
shift
# Determine whether starting or stopping
if [ "$MODE" == "up" ]; then
    # prepareForStart
    # genCerts
    # distributeCerts
    genChannelArtifacts
    # startOrderer
    # startPeer
    # startCA
    # startCLI
elif [ "$MODE" == "down" ]; then
    stopCLI
    stopCA
    stopPeer
    stopOrderer
elif [ "$MODE" == "clean" ]; then
    cleanFiles
elif [ "$MODE" == "addorg" ]; then
    addOrg
else
    help
    exit 1
fi
