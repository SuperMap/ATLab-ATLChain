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
    genConfigtx

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

# generate configtx.yaml
function genConfigtx() {
    if [ ! -d "configtx.yaml" ]; then
        touch configtx.yaml
    else
        rm configtx.yaml
    fi
    echo "Organizations:" >configtx.yaml
    varSwitch="orderer"
    while read line; do
        if [ "$line" == "" ]; then
            if [ "$varSwitch" == "orderer" ]; then
                varSwitch="peer"
                echo "PeerOrgs:" >>crypto-config.yaml
            fi
            continue
        fi

        if [ "$varSwitch" == "orderer" ]; then
            addPart1Configtx $(echo $line | awk '{print $1}') $(echo $line | awk '{print $2}')
        elif [ "$varSwitch" == "peer" ]; then
            addPart2Configtx $(echo $line | awk '{print $1}') $(echo $line | awk '{print $2}') $(echo $line | awk '{print $3}')
        fi
    done <./conf/orgs.conf

    addPart3Configtx

    while read line; do
        addPart4Configtx $line
    done <./conf/raft.conf

    varSwitch="orderer"
    while read line; do
        if [ "$line" == "" ]; then
            if [ "$varSwitch" == "orderer" ]; then
                varSwitch="peer"
            fi
            continue
        fi

        if [ "$varSwitch" == "orderer" ]; then
            addPart5Configtx $(echo $line | awk '{print $1}') $(echo $line | awk '{print $2}') $(echo $line | awk '{print $3}') $(echo $line | awk '{print $4}') $(echo $line | awk '{print $5}')
        elif [ "$varSwitch" == "peer" ]; then
            addPart6Configtx $(echo $line | awk '{print $1}') $(echo $line | awk '{print $2}') $(echo $line | awk '{print $3}') $(echo $line | awk '{print $4}')
        fi
    done <./conf/channel.conf
}


function addPart1Configtx() {
    echo "    - &$1
        Name: $1
        ID: $1
        MSPDir: crypto-config/ordererOrganizations/$2/msp
        Policies: &$1Policies
            Readers:
                Type: Signature
                Rule: \"OR('$1.member')\"
            Writers:
                Type: Signature
                Rule: \"OR('$1.member')\"
            Admins:
                Type: Signature
                Rule: \"OR('$1.admin')\"" >>configtx.yaml

    echo "" >>configtx.yaml
}

function addPart2Configtx() {
    echo "    - &$1
        Name: $1
        ID: $1
        MSPDir: crypto-config/peerOrganizations/$2/msp
        Policies: &$1Policies
            Readers:
                Type: Signature
                Rule: \"OR('$1.member')\"
            Writers:
                Type: Signature
                Rule: \"OR('$1.member')\"
            Admins:
                Type: Signature
                Rule: \"OR('$1.admin')\"

        OrdererEndpoints:
            - $4:7050

        AnchorPeers:
            - Host: $2
              Port: 7051" >>configtx.yaml

    echo "" >>configtx.yaml
}

function addPart3Configtx() {
    echo "Capabilities:
    Channel: &ChannelCapabilities
        V1_4_3: true
        V1_3: false
        V1_1: false

    Orderer: &OrdererCapabilities
        V1_4_2: true
        V1_1: false

    Application: &ApplicationCapabilities
        V1_4_2: true
        V1_3: false
        V1_2: false
        V1_1: false

Application: &ApplicationDefaults
    ACLs: &ACLsDefault
        lscc/ChaincodeExists: /Channel/Application/Readers
        lscc/GetDeploymentSpec: /Channel/Application/Readers
        lscc/GetChaincodeData: /Channel/Application/Readers
        lscc/GetInstantiatedChaincodes: /Channel/Application/Readers
        qscc/GetChainInfo: /Channel/Application/Readers
        qscc/GetBlockByNumber: /Channel/Application/Readers
        qscc/GetBlockByHash: /Channel/Application/Readers
        qscc/GetTransactionByID: /Channel/Application/Readers
        qscc/GetBlockByTxID: /Channel/Application/Readers
        cscc/GetConfigBlock: /Channel/Application/Readers
        cscc/GetConfigTree: /Channel/Application/Readers
        cscc/SimulateConfigTreeUpdate: /Channel/Application/Readers
        peer/Propose: /Channel/Application/Writers
        peer/ChaincodeToChaincode: /Channel/Application/Readers
        event/Block: /Channel/Application/Readers
        event/FilteredBlock: /Channel/Application/Readers

    Organizations:

    Policies: &ApplicationDefaultPolicies
        Readers:
            Type: ImplicitMeta
            Rule: \"ANY Readers\"
        Writers:
            Type: ImplicitMeta
            Rule: \"ANY Writers\"
        Admins:
            Type: ImplicitMeta
            Rule: \"MAJORITY Admins\"

    Capabilities:
        <<: *ApplicationCapabilities" >>configtx.yaml

    echo "" >>configtx.yaml
}

function addPart4Configtx() {
    echo "Orderer: &OrdererDefaults
    OrdererType: etcdraft
    Addresses:
        - $1:7050
        - $2:7050
        - $3:7050

    BatchTimeout: 2s

    BatchSize:
        MaxMessageCount: 2000
        AbsoluteMaxBytes: 100 MB
        PreferredMaxBytes: 50 MB

    MaxChannels: 0
    Kafka:
        Brokers:
            - kafka0:9092
            - kafka1:9092
            - kafka2:9092

    EtcdRaft:
        Consenters:
            - Host: $2.$1
              Port: 7050
              ClientTLSCert: crypto-config/ordererOrganizations/$1/orderers/$2.$1/tls/server.crt
              ServerTLSCert: crypto-config/ordererOrganizations/$1/orderers/$2.$1/tls/server.crt
            - Host: $3.$1
              Port: 7050
              ClientTLSCert: crypto-config/ordererOrganizations/$1/orderers/$3.$1/tls/server.crt
              ServerTLSCert: crypto-config/ordererOrganizations/$1/orderers/$3.$1/tls/server.crt
            - Host: $4.$1
              Port: 7050
              ClientTLSCert: crypto-config/ordererOrganizations/$1/orderers/$4.$1/tls/server.crt
              ServerTLSCert: crypto-config/ordererOrganizations/$1/orderers/$4.$1/tls/server.crt

        Options:
            TickInterval: 500ms
            ElectionTick: 10
            HeartbeatTick: 1
            MaxInflightBlocks: 5
            SnapshotIntervalSize: 200 MB

    Organizations:

    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: \"ANY Readers\"
        Writers:
            Type: ImplicitMeta
            Rule: \"ANY Writers\"
        Admins:
            Type: ImplicitMeta
            Rule: \"MAJORITY Admins\"
        BlockValidation:
            Type: ImplicitMeta
            Rule: \"ANY Writers\"

    Capabilities:
        <<: *OrdererCapabilities

Channel: &ChannelDefaults
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: \"ANY Readers\"
        Writers:
            Type: ImplicitMeta
            Rule: \"ANY Writers\"
        Admins:
            Type: ImplicitMeta
            Rule: \"MAJORITY Admins\"

    Capabilities:
        <<: *ChannelCapabilities" >>configtx.yaml

    echo "" >>configtx.yaml
}

function addPart5Configtx() {
    echo "Profiles:
    $1:
        <<: *ChannelDefaults
        Capabilities:
            <<: *ChannelCapabilities
        Orderer:
            <<: *OrdererDefaults
            Organizations:
                - <<: *$2
            Capabilities:
                <<: *OrdererCapabilities
        Consortiums:
            SampleConsortium:
                Organizations:
                    - <<: *$3
                    - <<: *$4
                    - <<: *$5" >>configtx.yaml

    echo "" >>configtx.yaml
}

function addPart6Configtx() {
    echo "    $1:
        Consortium: SampleConsortium
        <<: *ChannelDefaults
        Application:
            <<: *ApplicationDefaults
            Organizations:
                - *$2
                - *$3
                - *$4
            Capabilities:
                <<: *ApplicationCapabilities" >>configtx.yaml

    echo "" >>configtx.yaml
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
    genCerts
    # distributeCerts
    # genChannelArtifacts
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
