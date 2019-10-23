#!/bin/bash

export PATH=./bin:$PATH
export FABRIC_CFG_PATH=${PWD}

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

function startOrderer() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_ORDERER} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start orderer node"
        exit 1
    fi
}

function startPeer() {
    IMAGETAG1=$IMAGE_TAG1 IMAGETAG2=$IMAGE_TAG2 docker-compose -f ${DOCKER_COMPOSE_FILE_PEER} up -d 2>&1
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
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CLI} up -d 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start CLI node"
        exit 1
    fi
}

# Start a CA container
function startCA() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CA} up -d 2>&1
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
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_ORDERER} down 2>&1
}

function stopPeer() {
    IMAGETAG1=$IMAGE_TAG1 IMAGETAG2=$IMAGE_TAG2 docker-compose -f ${DOCKER_COMPOSE_FILE_PEER} down 2>&1
}

function stopCLI() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CLI} down 2>&1
}

function stopCA() {
    IMAGETAG1=$IMAGE_TAG1 docker-compose -f ${DOCKER_COMPOSE_FILE_CA} down 2>&1
}

function addOrg() {
    cryptogen generate --config=./orgc-crypto.yaml
    configtxgen -printOrg OrgC > ./channel-artifacts/orgc.json
}

function downloadImages() {
    if [ !"$(docker images hyperledger/fabric-tools:amd64-1.4.3 -q)" == "18ed4db0cd57" ]
    then
        docker pull hyperledger/fabric-tools:amd64-1.4.3
    fi
    
    if [ !"$(docker images hyperledger/fabric-ccenv:amd64-1.4.3 -q)" == "18ed4db0cd57" ]
    then
        docker pull hyperledger/fabric-ccenv:amd64-1.4.3
    fi

    if [ !"$(docker images hyperledger/fabric-javaenv:amd64-1.4.3 -q)" == "18ed4db0cd57" ]
    then
        docker pull hyperledger/fabric-javaenv:amd64-1.4.3
    fi

    if [ !"$(docker images hyperledger/fabric-orderer:amd64-1.4.3 -q)" == "18ed4db0cd57" ]
    then
        docker pull hyperledger/fabric-orderer:amd64-1.4.3
    fi

    if [ !"$(docker images hyperledger/fabric-peer:amd64-1.4.3 -q)" == "18ed4db0cd57" ]
    then
        docker pull hyperledger/fabric-peer:amd64-1.4.3
    fi

    if [ !"$(docker images hyperledger/fabric-ca:amd64-1.4.3 -q)" == "18ed4db0cd57" ]
    then
        docker pull hyperledger/fabric-ca:amd64-1.4.3
    fi

    if [ !"$(docker images hyperledger/fabric-couchdb：amd64-0.4.15 -q)" == "18ed4db0cd57" ]
    then
        docker pull hyperledger/fabric-couchdb：amd64-0.4.15
    fi

    if [ !"$(docker images hyperledger/fabric-baseos：amd64-0.4.15 -q)" == "18ed4db0cd57" ]
    then
        docker pull hyperledger/fabric-baseos：amd64-0.4.15
    fi
}

# generate crypto-config.yaml
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
    done < ./conf/crypto-config.conf
}

# generate configtx.yaml
function genConfigtx() {
    if [ ! -d "configtx.yaml" ]
    then
        touch configtx.yaml
    else
        rm configtx.yaml
    fi
    echo "Organizations:" > configtx.yaml
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
            addPart1Configtx $(echo $line | awk '{print $1}') $(echo $line | awk '{print $2}')
        elif [ "$varSwitch" == "peer" ]
        then
            addPart2Configtx $(echo $line | awk '{print $1}') $(echo $line | awk '{print $2}') $(echo $line | awk '{print $3}')
        fi
    done < ./conf/crypto-config.conf

    addPart3Configtx

    while read line
    do
        addPart4Configtx $line
    done < ./conf/raft.conf
    
    varSwitch="orderer"
    while read line
    do
        if [ "$line" == "" ]
        then
            if [ "$varSwitch" == "orderer" ]
            then
                varSwitch="peer"
            fi
            continue
        fi
        
        if [ "$varSwitch" == "orderer" ]
        then
            addPart5Configtx $(echo $line | awk '{print $1}') $(echo $line | awk '{print $2}') $(echo $line | awk '{print $3}') $(echo $line | awk '{print $4}') $(echo $line | awk '{print $5}')
        elif [ "$varSwitch" == "peer" ]
        then
            addPart6Configtx $(echo $line | awk '{print $1}') $(echo $line | awk '{print $2}') $(echo $line | awk '{print $3}') $(echo $line | awk '{print $4}')
        fi
    done < ./conf/channel.conf
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
                Rule: \"OR('$1.admin')\"" >> configtx.yaml

    echo "" >> configtx.yaml
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
            - $3:7050

        AnchorPeers:
            - Host: $2
              Port: 7051" >> configtx.yaml

    echo "" >> configtx.yaml
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
        <<: *ApplicationCapabilities" >> configtx.yaml

    echo "" >> configtx.yaml
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
        <<: *ChannelCapabilities" >> configtx.yaml

    echo "" >> configtx.yaml
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
                    - <<: *$5" >> configtx.yaml

    echo "" >> configtx.yaml
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
                <<: *ApplicationCapabilities" >> configtx.yaml

    echo "" >> configtx.yaml
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
    if [ ! -d "bin" ] 
    then
        echo "extract binary files..."
        tar xvf bin.tar.xz
    fi

    if [ ! -d "production" ];then
        mkdir production
    fi
}

MODE=$1
shift
# Determine whether starting or stopping
if [ "$MODE" == "up" ]; then
    prepareForStart

    genCerts
    genChannelArtifacts
    startOrderer
    startPeer
    startCA
    startCLI
elif [ "$MODE" == "down" ]; then
    stopCLI
    stopCA
    stopPeer
    stopOrderer
    cleanFiles    
elif [ "$MODE" == "addorg" ]; then
    addOrg
else
    help
    exit 1 
fi
