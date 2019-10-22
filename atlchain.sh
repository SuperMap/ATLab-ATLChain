#!/bin/bash

export PATH=${PWD}/ATLChain_NETWORK/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/ATLChain_NETWORK

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

function help() {
    echo "Usage: "
    echo "  atlchain.sh <mode>"
    echo "      <mode> - one of 'up', 'down', 'clean'"
    echo "        - 'up' - bring up the network with docker-compose up"
    echo "        - 'down' - clear the network with docker-compose down"
    echo "        - 'clean' - clean files built during network running"
    echo "e.g."
    echo "  atlchain.sh up"
    echo "  atlchain.sh down"
}

# Generates Org certs using cryptogen tool
function genCerts() {
    # generate crypto-config.yaml
    genCryptoConfig

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
    echo "#########################################################################"
    echo "### Generating channel configuration transaction '${CHANNEL_NAME}.tx' ###"
    echo "#########################################################################"
    set -x
    configtxgen -profile TxChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to generate channel configuration transaction..."
        exit 1
    fi
    
    echo
    echo "#############################################################"
    echo "#######    Generating anchor peer update for Org   ##########"
    echo "#############################################################"
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

# Start a CA container
function startCA() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_CA} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start CA node"
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

function stopOrderer() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_ORDERER} down 2>&1
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

function stopCA() {
    docker-compose -f ${DOCKER_COMPOSE_FILE_CA} down 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to stop CA node"
        exit 1
    fi
}

function addOrg() {
    cryptogen generate --config=./orgc-crypto.yaml
    configtxgen -printOrg OrgC > ./channel-artifacts/orgc.json
}

function downloadImages() {
    docker pull hyperledger/fabric-tools:amd64-1.4.3
    docker pull hyperledger/fabric-ccenv:amd64-1.4.3
    docker pull hyperledger/fabric-javaenv:amd64-1.4.3
    docker pull hyperledger/fabric-orderer:amd64-1.4.3
    docker pull hyperledger/fabric-peer:amd64-1.4.3
    docker pull hyperledger/fabric-ca:amd64-1.4.3
    docker pull hyperledger/fabric-couchdb：amd64-0.4.15
    docker pull hyperledger/fabric-baseos：amd64-0.4.15
}

function addOrgOrdererCryptoConfig() {
    echo "  - Name: $1
    Domain: $2
    EnableNodeOUs: true
    Specs:
      - Hostname: orderer1
      - Hostname: orderer2
      - Hostname: orderer3
      - Hostname: orderer4
      - Hostname: orderer5" >> crypto-config.yaml
    
    echo "" >> crypto-config.yaml
}

function addOrgPeerCryptoConfig() {
    echo "  - Name: $1
    Domain: $2
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 2" >> crypto-config.yaml

    echo "" >> crypto-config.yaml
}

function genCryptoConfig() {
    if [ ! -d "crypto-config.yaml" ]
    then
        touch crypto-config.yaml
    else
        rm crypto-config.yaml
    fi
    echo "OrdererOrgs:" > crypto-config.yaml
    varSwitch="orderer"
    while read line
    do
        if [ "$line" == "" ]
        then
            if [ "$varSwitch" == "orderer" ]
            then
                varSwitch="peer"
                echo "PeerOrgs:" >> crypto-config.yaml
            fi
            continue
        fi
        
        if [ "$varSwitch" == "orderer" ]
        then
            addOrgOrdererCryptoConfig $(echo $line | awk '{print $1}') $(echo $line | awk '{print $2}')
        elif [ "$varSwitch" == "peer" ]
        then
            addOrgPeerCryptoConfig $(echo $line | awk '{print $1}') $(echo $line | awk '{print $2}')
        fi
    done < conf/crypto-config.conf
}

# Network config files are in ATLChain_NETWORK directory
cd ATLChain_NETWORK
genCerts
# # Download docker images
# echo "Downloading docker images......"
# downloadImages
# if [ $? -ne 0 ]; then
#     echo "ERROR !!!! Unable to download docker images"
#     exit 1
# fi

# # Untar bin package
# if [ ! -d "bin" ] 
# then
#     echo "extract binary files..."
#     tar xvf bin.tar.xz
# fi

# if [ ! -d "production" ];then
#     mkdir production
# fi

# MODE=$1
# shift
# # Determine whether starting or stopping
# if [ "$MODE" == "up" ]; then
#         genCerts
#         genChannelArtifacts
#         startOrderer
#         startPeer
#         # startCA
#         # startCLI
# elif [ "$MODE" == "down" ]; then
#         # stopCLI
#         # stopCA
#         stopPeer
#         stopOrderer
#         cleanFiles    
# elif [ "$MODE" == "addorg" ]; then
#     addOrg
# else
#     help
#     exit 1 
# fi

# Back to working dir
cd ..
