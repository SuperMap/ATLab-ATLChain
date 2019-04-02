#!/bin/bash

export PATH=${PWD}/ATLChain_NETWORK/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/ATLChain_NETWORK

CHANNEL_NAME="atlchannel"
ORG_DOMAIN_NAME="orgc.atlchain.com"

#compose files
DOCKER_COMPOSE_FILE_KAFKA="docker-compose-kafka.yaml"
DOCKER_COMPOSE_FILE_ORDERER="docker-compose-orderer.yaml"
DOCKER_COMPOSE_FILE_PEER="docker-compose-peer.yaml"
DOCKER_COMPOSE_FILE_CA="docker-compose-ca.yaml"
DOCKER_COMPOSE_FILE_CLI="docker-compose-cli.yaml"

# default compose project name
export COMPOSE_PROJECT_NAME=atlproj

export DOCKER_COMPOSE_PEER_ADDRESS=peer0.orgc.atlchain.com:7051
export DOCKER_COMPOSE_PEER_CC_ADDRESS=peer0.orgc.atlchain.com:7052
export DOCKER_COMPOSE_PEER_GOSSIP_BOOTSTRAP=peer0.orgc.atlchain.com:7051 

export CORE_PEER_ADDRESS=peer0.orgc.atlchain.com:7061 
export ORERER_ADDRESS=orderer0.orgc.atlchain.com:7060

function printHelp() {
    echo "Usage: "
    echo "  atlchain.sh <mode> [<node>]"
    echo "      <mode> - one of 'up', 'down', 'genCerts', 'genArti', 'clean'"
    echo "        - 'up' - bring up the network with docker-compose up"
    echo "        - 'down' - clear the network with docker-compose down"
    echo "        - 'genCerts' - generate crypto material"
    echo "        - 'genArti' - generate channel artifacts"
    echo "        - 'clean' - clean files built during network running"
    echo "      <node> - one of 'orderer', 'peer', 'ca', 'cli'"
    echo "        - 'orderer' - orderer node"
    echo "        - 'peer' - peer node"
    echo "        - 'ca' - ca node"
    echo "        - 'cli' - tool node, you can run commands in cli container"
    echo "e.g."
    echo "  atlchain.sh genCerts"
    echo "  atlchain.sh genArti"
    echo "  atlchain.sh up orderer"
    echo "  atlchain.sh down peer"
}

# Generates Org certs using cryptogen tool
function genCerts() {
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
    which configtxgen
    if [ "$?" -ne 0 ]; then
        echo "configtxgen tool not found. exiting"
        exit 1
    fi

    if [ ! -d "./channel-artifacts" ]; then
        mkdir ./channel-artifacts
    fi

    echo "##########################################################"
    echo "#########  Generating Orderer Genesis block ##############"
    echo "##########################################################"
    set -x
    configtxgen -profile OrdererChannel -channelID ordererchannel -outputBlock ./channel-artifacts/genesis.block
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to generate orderer genesis block..."
        exit 1
    fi

    echo
    echo "#################################################################"
    echo "### Generating channel configuration transaction 'atlchannel.tx' ###"
    echo "#################################################################"
    set -x
    configtxgen -profile TxChannel -outputCreateChannelTx ./channel-artifacts/atlchannel.tx -channelID $CHANNEL_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to generate channel configuration transaction..."
        exit 1
    fi
    
    echo
    echo "#################################################################"
    echo "#######    Generating anchor peer update for Org   ##########"
    echo "#################################################################"
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

function startKafka() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_KAFKA} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start kafka"
        exit 1
    fi
}

function startOrderer() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_ORDERER} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start orderer node"
        exit 1
    fi
}

function startPeer() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_PEER} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start peer node"
        exit 1
    fi
}

function startCA() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_CA} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start CA node "
        exit 1
    fi
}

# Start a CLI peer container for operation
function startCLI() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_CLI} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start CLI node"
        exit 1
    fi
}

# Remove the files generated
function cleanFiles() {
    rm -rf crypto-config
    rm -rf channel-artifacts
    rm -rf production
}

function stopOrderer() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_ORDERER} down 2>&1
}

function stopKafka() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_KAFKA} down 2>&1
}

function stopPeer() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_PEER} down 2>&1
}

function stopCA() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_CA} down 2>&1
}

function stopCLI() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_CLI} down 2>&1
}

function startAll() {
    startOrderer
    startPeer
    startCA
    startCLI
}

function stopAll() {
    stopOrderer
    stopPeer
    stopCA
    stopCLI
}

function addOrg() {
    cryptogen generate --config=./orgc-crypto.yaml

    configtxgen -printOrg OrgC > ./channel-artifacts/orgc.json
}

# Network config files in ATLChain_NETWORK directory
cd ATLChain_NETWORK
# untar bin package
if [ ! -d "bin" ] 
then
    echo "extract binary files..."
    tar xvf bin.tar.xz
fi

if [ ! -d "production" ];then
    mkdir production
fi

MODE=$1
shift
NODE=$1
shift
# Determine whether starting or stopping
if [ "$MODE" == "up" ]; then
    if [ "$NODE" == "kafka" ]; then
        export COMPOSE_PROJECT_NAME=atlprojk
        startKafka
    elif [ "$NODE" == "orderer" ]; then
        export COMPOSE_PROJECT_NAME=atlprojo
        startOrderer
    elif [ "$NODE" == "peer" ]; then
        export COMPOSE_PROJECT_NAME=atlprojp
        startPeer
    elif [ "$NODE" == "ca" ]; then
        export COMPOSE_PROJECT_NAME=atlprojc
        startCA
    elif [ "$NODE" == "cli" ]; then
        export COMPOSE_PROJECT_NAME=atlprojcl
        startCLI
    # elif [ "$NODE" == "all" ]; then
    #     startAll
    else 
        printHelp
        exit 1
    fi
elif [ "$MODE" == "down" ]; then
    if [ "$NODE" == "kafka" ]; then
        export COMPOSE_PROJECT_NAME=atlprojk
        stopKafka
    elif [ "$NODE" == "orderer" ]; then
        export COMPOSE_PROJECT_NAME=atlprojo
        stopOrderer
    elif [ "$NODE" == "peer" ]; then
        export COMPOSE_PROJECT_NAME=atlprojp
        stopPeer
    elif [ "$NODE" == "ca" ]; then
        export COMPOSE_PROJECT_NAME=atlprojc
        stopCA
    elif [ "$NODE" == "cli" ]; then
        export COMPOSE_PROJECT_NAME=atlprojcl
        stopCLI
    # elif [ "$NODE" == "all" ]; then
    #     stopAll
    else 
        printHelp
        exit 1
    fi
elif [ "$MODE" == "genCerts" ]; then
    genCerts
elif [ "$MODE" == "genArti" ]; then
    genChannelArtifacts
elif [ "$MODE" == "generate" ]; then
    genCerts
    genChannelArtifacts
elif [ "$MODE" == "clean" ]; then
    cleanFiles
elif [ "$MODE" == "addorg" ]; then
    addOrg
else
    printHelp
    exit 1 
fi
cd ..
