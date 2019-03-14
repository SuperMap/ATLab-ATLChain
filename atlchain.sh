#!/bin/bash

# prepending $PWD/ATLChain_NETWORK/bin to PATH to ensure we are picking up the correct binaries
# this may be commented out to resolve installed version of tools if desired
export PATH=${PWD}/ATLChain_NETWORK/bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/ATLChain_NETWORK
export VERBOSE=false

# default compose project name
export COMPOSE_PROJECT_NAME=atl

# default docker image version
export IMAGE_TAG=latest

# Print the usage message
function printHelp() {
    echo "Usage: "
    echo "  byfn.sh <mode> <orgs> [-c <channel name>] [-t <timeout>] [-d <delay>] [-f <docker-compose-file>] [-s <dbtype>] [-l <language>] [-o <consensus-type>] [-i <imagetag>] [-v]"
    echo "    <mode> - one of 'up', 'down', 'restart', 'generate' or 'upgrade'"
    echo "    <orgs> - organizations you want to create e.g. OrgA OrgSuperMap. NEVER use special characters e.g. # @"
    echo "      - 'up' - bring up the network with docker-compose up"
    echo "      - 'down' - clear the network with docker-compose down"
    echo "      - 'restart' - restart the network"
    echo "      - 'generate' - generate required certificates and genesis block"
    echo "      - 'upgrade'  - upgrade the network from version 1.3.x to 1.4.0"
    echo "    -c <channel name> - channel name to use (defaults to \"atlchannel\")"
    echo "    -t <timeout> - CLI timeout duration in seconds (defaults to 10)"
    echo "    -d <delay> - delay duration in seconds (defaults to 3)"
    echo "    -f <docker-compose-file> - specify which docker-compose file use (defaults to docker-compose-cli.yaml)"
    echo "    -s <dbtype> - the database backend to use: goleveldb or couchdb (default)"
    echo "    -l <language> - the chaincode language: golang (default) or node"
    echo "    -o <consensus-type> - the consensus-type of the ordering service: solo or kafka (default)"
    echo "    -i <imagetag> - the tag to be used to launch the network (defaults to \"latest\")"
    echo "    -v - verbose mode"
    echo "  byfn.sh -h (print this message)"
    echo
    echo "Typically, one would first generate the required certificates and "
    echo "genesis block, then bring up the network. e.g.:"
    echo
    echo "	byfn.sh generate OrgA  -c atlchannel"
    echo "	byfn.sh up OrgA -c atlchannel -s couchdb"
    echo "  byfn.sh up OrgA -c atlchannel -s couchdb -i 1.4.0"
    echo "	byfn.sh up OrgA -l node"
    echo "	byfn.sh down -c atlchannel"
    echo "  byfn.sh upgrade OrgA -c atlchannel"
    echo
    echo "Taking all defaults:"
    echo "	byfn.sh generate OrgA"
    echo "	byfn.sh up OrgA"
    echo "	byfn.sh down"
}

# Ask user for confirmation to proceed
function askProceed() {
    read -p "Continue? [Y/n] " ans
    case "$ans" in
    y | Y | "")
        echo "proceeding ..."
        ;;
    n | N)
        echo "exiting..."
        exit 1
        ;;
    *)
        echo "invalid response"
        askProceed
        ;;
    esac
}

# Obtain CONTAINER_IDS and remove them
# TODO Might want to make this optional - could clear other containers
function clearContainers() {
    CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*.atlchaincc.*/) {print $1}')
    if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
        echo "---- No containers available for deletion ----"
    else
        docker rm -f $CONTAINER_IDS
    fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# TODO list generated image naming patterns
function removeUnwantedImages() {
    DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*.atlchaincc.*/) {print $3}')
    if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
        echo "---- No images available for deletion ----"
    else
        docker rmi -f $DOCKER_IMAGE_IDS
    fi
}

# Versions of fabric known not to work with this release of first-network
BLACKLISTED_VERSIONS="^1\.0\. ^1\.1\.0-preview ^1\.1\.0-alpha"

# Do some basic sanity checking to make sure that the appropriate versions of fabric
# binaries/images are available.  In the future, additional checking for the presence
# of go or other items could be added.
function checkPrereqs() {
    # Note, we check configtxlator externally because it does not require a config file, and peer in the
    # docker image because of FAB-8551 that makes configtxlator return 'development version' in docker
    LOCAL_VERSION=$(configtxlator version | sed -ne 's/ Version: //p')
    DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)

    echo "LOCAL_VERSION=$LOCAL_VERSION"
    echo "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

    if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
        echo "=================== WARNING ==================="
        echo "  Local fabric binaries and docker images are  "
        echo "  out of  sync. This may cause problems.       "
        echo "==============================================="
    fi

    for UNSUPPORTED_VERSION in $BLACKLISTED_VERSIONS; do
        echo "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
        if [ $? -eq 0 ]; then
            echo "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
            exit 1
        fi

        echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
        if [ $? -eq 0 ]; then
            echo "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
            exit 1
        fi
    done
}

# Generate the needed certificates, the genesis block and start the network.
function networkUp() {
    checkPrereqs
    # generate artifacts if they don't exist
    if [ ! -d "crypto-config" ]; then
        generateCerts
        replacePrivateKey
        generateChannelArtifacts
    fi
    if [ "${IF_COUCHDB}" == "couchdb" ]; then
        if [ "$CONSENSUS_TYPE" == "kafka" ]; then
            IMAGE_TAG=$IMAGETAG docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_KAFKA -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_E2E -f $COMPOSE_FILE_HADOOP up -d 2>&1
        else
            IMAGE_TAG=$IMAGETAG docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH up -d 2>&1
        fi
    else
        if [ "$CONSENSUS_TYPE" == "kafka" ]; then
            IMAGE_TAG=$IMAGETAG docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_KAFKA up -d 2>&1
        else
            IMAGE_TAG=$IMAGETAG docker-compose -f $COMPOSE_FILE up -d 2>&1
        fi
    fi
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Unable to start network"
        exit 1
    fi

    if [ "$CONSENSUS_TYPE" == "kafka" ]; then
        sleep 1
        echo "Sleeping 10s to allow kafka cluster to complete booting"
        sleep 9
    fi

    # now run the end to end script
    docker exec cli scripts/script.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! Test failed"
        exit 1
    fi
}

# Upgrade the network components which are at version 1.3.x to 1.4.x
# Stop the orderer and peers, backup the ledger for orderer and peers, cleanup chaincode containers and images
# and relaunch the orderer and peers with latest tag
function upgradeNetwork() {
    if [[ "$IMAGETAG" == *"1.4"* ]] || [[ $IMAGETAG == "latest" ]]; then
        docker inspect -f '{{.Config.Volumes}}' orderer.atlchain.com | grep -q '/var/hyperledger/production/orderer'
        if [ $? -ne 0 ]; then
            echo "ERROR !!!! This network does not appear to start with fabric-samples >= v1.3.x?"
            exit 1
        fi

        LEDGERS_BACKUP=./ledgers-backup

        # create ledger-backup directory
        mkdir -p $LEDGERS_BACKUP

        export IMAGE_TAG=$IMAGETAG
        if [ "${IF_COUCHDB}" == "couchdb" ]; then
            if [ "$CONSENSUS_TYPE" == "kafka" ]; then
                COMPOSE_FILES="-f $COMPOSE_FILE -f $COMPOSE_FILE_KAFKA -f $COMPOSE_FILE_COUCH"
            else
                COMPOSE_FILES="-f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH"
            fi
        else
            if [ "$CONSENSUS_TYPE" == "kafka" ]; then
                COMPOSE_FILES="-f $COMPOSE_FILE -f $COMPOSE_FILE_KAFKA"
            else
                COMPOSE_FILES="-f $COMPOSE_FILE"
            fi
        fi

        # removing the cli container
        docker-compose $COMPOSE_FILES stop cli
        docker-compose $COMPOSE_FILES up -d --no-deps cli

        echo "Upgrading orderer"
        docker-compose $COMPOSE_FILES stop orderer.atlchain.com
        docker cp -a orderer.atlchain.com:/var/hyperledger/production/orderer $LEDGERS_BACKUP/orderer.atlchain.com
        docker-compose $COMPOSE_FILES up -d --no-deps orderer.atlchain.com

        for PEER in peer0.org1.atlchain.com peer1.org1.atlchain.com peer0.org2.atlchain.com peer1.org2.atlchain.com; do
            echo "Upgrading peer $PEER"

            # Stop the peer and backup its ledger
            docker-compose $COMPOSE_FILES stop $PEER
            docker cp -a $PEER:/var/hyperledger/production $LEDGERS_BACKUP/$PEER/

            # Remove any old containers and images for this peer
            CC_CONTAINERS=$(docker ps | grep dev-$PEER | awk '{print $1}')
            if [ -n "$CC_CONTAINERS" ]; then
                docker rm -f $CC_CONTAINERS
            fi
            CC_IMAGES=$(docker images | grep dev-$PEER | awk '{print $1}')
            if [ -n "$CC_IMAGES" ]; then
                docker rmi -f $CC_IMAGES
            fi

            # Start the peer again
            docker-compose $COMPOSE_FILES up -d --no-deps $PEER
        done

        docker exec cli scripts/upgrade_to_v14.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE
        if [ $? -ne 0 ]; then
            echo "ERROR !!!! Test failed"
            exit 1
        fi
    else
        echo "ERROR !!!! Pass the v1.4.x image tag"
    fi
}

# Tear down running network
function networkDown() {
    # stop org3 containers also in addition to org1 and org2, in case we were running sample to add org3
    # stop kafka and zookeeper containers in case we're running with kafka consensus-type
    echo "##########################################################"
    echo "#################  remove useless files ##################"
    echo "##########################################################"
    echo "docker exec -it cli rm -rf /opt/gopath/src/github.com/hyperledger/fabric/peer/demo/web/public/msp/"
    docker exec -it cli rm -rf /opt/gopath/src/github.com/hyperledger/fabric/peer/demo/web/public/msp/

    echo "docker exec -it cli rm -rf /opt/gopath/src/github.com/hyperledger/fabric/peer/demo/web/public/tmp/"
    docker exec -it cli rm -rf /opt/gopath/src/github.com/hyperledger/fabric/peer/demo/web/public/tmp/

    echo "docker exec -it cli rm -rf /opt/gopath/src/github.com/hyperledger/fabric/peer/demo/server/fabric-client-kv-orga/"
    docker exec -it cli rm -rf /opt/gopath/src/github.com/hyperledger/fabric/peer/demo/server/fabric-client-kv-orga/
    
    docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_KAFKA -f $COMPOSE_FILE_E2E -f $COMPOSE_FILE_ORG3 -f $COMPOSE_FILE_HADOOP down --volumes --remove-orphans

    # Don't remove the generated artifacts -- note, the ledgers are always removed
    if [ "$MODE" != "restart" ]; then
        # Bring down the network, deleting the volumes
        #Delete any ledger backups
        docker run -v $PWD:/tmp/first-network --rm hyperledger/fabric-tools:$IMAGETAG rm -Rf /tmp/first-network/ledgers-backup
        #Cleanup the chaincode containers
        clearContainers
        #Cleanup images
        removeUnwantedImages
        # remove orderer block and other channel configuration transactions and certs
        rm -rf channel-artifacts/*.block channel-artifacts/*.tx crypto-config ./org3-artifacts/crypto-config/ channel-artifacts/org3.json
        # remove the docker-compose yaml file that was customized to the example
        rm -f docker-compose-e2e.yaml ../ATLChain_DEMO/server/app/network-config.yaml ../ATLChain_DEMO/server/app.log ../ATLChain_DEMO/server/http.log
    fi

}

# Using docker-compose-e2e-template.yaml, replace constants with private key file names
# generated by the cryptogen tool and output a docker-compose.yaml specific to this
# configuration
function replacePrivateKey() {
    # sed on MacOSX does not support -i flag with a null extension. We will use
    # 't' for our back-up's extension and delete it at the end of the function
    ARCH=$(uname -s | grep Darwin)
    if [ "$ARCH" == "Darwin" ]; then
        OPTS="-it"
    else
        OPTS="-i"
    fi

    # Copy the template to the file that will be modified to add the private key
    cp docker-compose-e2e-template.yaml docker-compose-e2e.yaml

    # The next steps will replace the template's contents with the
    # actual values of the private key file names for the two CAs.
    CURRENT_DIR=$PWD
    cd crypto-config/peerOrganizations/orga.atlchain.com/ca/
    PRIV_KEY=$(ls *_sk)
    cd "$CURRENT_DIR"
    sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml
    cd crypto-config/peerOrganizations/orgb.atlchain.com/ca/
    PRIV_KEY=$(ls *_sk)
    cd "$CURRENT_DIR"
    sed $OPTS "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml

    cp ../ATLChain_DEMO/server/app/network-config-template.yaml ../ATLChain_DEMO/server/app/network-config.yaml
    cd crypto-config/peerOrganizations/orga.atlchain.com/users/Admin@orga.atlchain.com/msp/keystore/
    PRIV_KEY=$(ls *_sk)
    cd "$CURRENT_DIR"
    sed $OPTS "s/ADMIN_ORGA_PRIVATE_KEY/${PRIV_KEY}/g" ../ATLChain_DEMO/server/app/network-config.yaml
    cd crypto-config/peerOrganizations/orgb.atlchain.com/users/Admin@orgb.atlchain.com/msp/keystore/
    PRIV_KEY=$(ls *_sk)
    cd "$CURRENT_DIR"
    sed $OPTS "s/ADMIN_ORGB_PRIVATE_KEY/${PRIV_KEY}/g" ../ATLChain_DEMO/server/app/network-config.yaml

    # If MacOSX, remove the temporary backup of the docker-compose file
    if [ "$ARCH" == "Darwin" ]; then
        rm docker-compose-e2e.yamlt
    fi
}

# generate crypto-config.yaml 
function generateCryptoConfig() {
    echo
    echo "##########################################################"
    echo "############# Generate crypto config file ################"
    echo "##########################################################"

    ARCH=$(uname -s | grep Darwin)
    if [ "$ARCH" == "Darwin" ]; then
        OPTS="-it"
    else
        OPTS="-i"
    fi

    if [ ! -f "${CRYPTO_CONFIG_FILE}" ]
    then
        touch ${CRYPTO_CONFIG_FILE}
    fi

    # Set orderer nodes
    echo "OrdererOrgs:" > ${CRYPTO_CONFIG_FILE}
    echo "" >> ${CRYPTO_CONFIG_FILE}
    cat ./templates/crypto-config-orderer.template >> ${CRYPTO_CONFIG_FILE}
    # Set orderer hostname
    sed ${OPTS} "s/ORDERER_NUM/0/g" ${CRYPTO_CONFIG_FILE}

    # Set peer nodes
    echo "" >> ${CRYPTO_CONFIG_FILE}
    echo "PeerOrgs:" >> ${CRYPTO_CONFIG_FILE}
    count=0
    echo "args nums: $#"
    args_count=$#
    while (( ${count} < args_count))
    do
        echo "" >> ${CRYPTO_CONFIG_FILE}
        cat ./templates/crypto-config-peer.template >> ${CRYPTO_CONFIG_FILE}

        # Set org name
        sed ${OPTS} "s/ORG_NAME/${1}/g" ${CRYPTO_CONFIG_FILE}
        
        # Set domain name
        DOMAIN=$(echo "${1}.${DOMAIN_NAME}" | tr '[:upper:]' '[:lower:]')
        sed ${OPTS} "s/ORG_DOMAIN/${DOMAIN}/g" ${CRYPTO_CONFIG_FILE}


        # Set peer count
        sed ${OPTS} "s/PEER_COUNT/2/g" ${CRYPTO_CONFIG_FILE}

        # Set user count
        sed ${OPTS} "s/USER_COUNT/2/g" ${CRYPTO_CONFIG_FILE}

        index=${#ARRAY_ORGS[*]}
        ARRAY_ORGS[index]=${1}

        shift
        let "count++"
    done
}

# Generates Org certs using cryptogen tool
function generateCerts() {
    generateCryptoConfig $*
    echo "array::: ${ARRAY_ORGS[*]}"
    which cryptogen
    if [ "$?" -ne 0 ]; then
        echo "cryptogen tool not found. exiting"
        exit 1
    fi
    echo
    echo "##########################################################"
    echo "##### Generate certificates using cryptogen tool #########"
    echo "##########################################################"

    if [ -d "crypto-config" ]; then
        rm -Rf crypto-config
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

# Generate orderer genesis block, channel configuration transaction and
# anchor peer update transactions
function generateChannelArtifacts() {
    which configtxgen
    if [ "$?" -ne 0 ]; then
        echo "configtxgen tool not found. exiting"
        exit 1
    fi

    echo "##########################################################"
    echo "#########  Generating Orderer Genesis block ##############"
    echo "##########################################################"
    # Note: For some unknown reason (at least for now) the block file can't be
    # named orderer.genesis.block or the orderer will fail to launch!
    echo "CONSENSUS_TYPE="$CONSENSUS_TYPE
    set -x
    if [ "$CONSENSUS_TYPE" == "solo" ]; then
        configtxgen -profile OrdererChannel -channelID ordererchannel -outputBlock ./channel-artifacts/genesis.block
    elif [ "$CONSENSUS_TYPE" == "kafka" ]; then
        configtxgen -profile OrdererChannel -channelID ordererchannel -outputBlock ./channel-artifacts/genesis.block
    else
        set +x
        echo "unrecognized CONSESUS_TYPE='$CONSENSUS_TYPE'. exiting"
        exit 1
    fi
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
    echo "#######    Generating anchor peer update for OrgA   ##########"
    echo "#################################################################"
    set -x
    configtxgen -profile TxChannel -outputAnchorPeersUpdate ./channel-artifacts/OrgAanchors.tx -channelID $CHANNEL_NAME -asOrg OrgA
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to generate anchor peer update for OrgA..."
        exit 1
    fi

    echo
    echo "#################################################################"
    echo "#######    Generating anchor peer update for OrgB   ##########"
    echo "#################################################################"
    set -x
    configtxgen -profile TxChannel -outputAnchorPeersUpdate \
        ./channel-artifacts/OrgBanchors.tx -channelID $CHANNEL_NAME -asOrg OrgB
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to generate anchor peer update for OrgB..."
        exit 1
    fi
    echo
}

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform, e.g., darwin-amd64 or linux-amd64
OS_ARCH=$(echo "$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
CLI_TIMEOUT=10
# default for delay between commands
CLI_DELAY=3
# channel name defaults to "atlchannel"
CHANNEL_NAME="atlchannel"
# use this as the default docker-compose yaml definition
COMPOSE_FILE=./docker-compose-cli.yaml
#
COMPOSE_FILE_COUCH=./docker-compose-couch.yaml
# org3 docker compose file
COMPOSE_FILE_ORG3=./docker-compose-org3.yaml
# kafka and zookeeper compose file
COMPOSE_FILE_KAFKA=./docker-compose-kafka.yaml
COMPOSE_FILE_E2E=./docker-compose-e2e.yaml
COMPOSE_FILE_HADOOP=./docker-compose-hadoop.yaml
#
CRYPTO_CONFIG_FILE=crypto-config.yaml
DOMAIN_NAME="atlchain.com"
#
ARRAY_ORGS=()
#
# use golang as the default language for chaincode
LANGUAGE=golang
# default image tag
IMAGETAG="latest"
# default consensus type
CONSENSUS_TYPE="kafka"
IF_COUCHDB="couchdb"
# Parse commandline args
if [ "$1" = "-m" ]; then # supports old usage, muscle memory is powerful!
    shift
fi
MODE=$1
shift
# Determine whether starting, stopping, restarting, generating or upgrading
if [ "$MODE" == "up" ]; then
    EXPMODE="Starting"
elif [ "$MODE" == "down" ]; then
    EXPMODE="Stopping"
elif [ "$MODE" == "restart" ]; then
    EXPMODE="Restarting"
elif [ "$MODE" == "generate" ]; then
    EXPMODE="Generating certs and genesis block"
elif [ "$MODE" == "upgrade" ]; then
    EXPMODE="Upgrading the network"
elif [ "$MODE" == "crypto" ]; then
    EXPMODE="trying"
else
    printHelp
    exit 1
fi

while getopts "h?c:t:d:f:s:l:i:o:v" opt; do
    case "$opt" in
    h | \?)
        printHelp
        exit 0
        ;;
    c)
        CHANNEL_NAME=$OPTARG
        ;;
    t)
        CLI_TIMEOUT=$OPTARG
        ;;
    d)
        CLI_DELAY=$OPTARG
        ;;
    f)
        COMPOSE_FILE=$OPTARG
        ;;
    s)
        IF_COUCHDB=$OPTARG
        ;;
    l)
        LANGUAGE=$OPTARG
        ;;
    i)
        IMAGETAG=$(go env GOARCH)"-"$OPTARG
        ;;
    o)
        CONSENSUS_TYPE=$OPTARG
        ;;
    v)
        VERBOSE=true
        ;;
    esac
done


# Announce what was requested


if [ "${IF_COUCHDB}" == "couchdb" ]; then
    echo
    echo "${EXPMODE} for channel '${CHANNEL_NAME}' with CLI timeout of '${CLI_TIMEOUT}' seconds and CLI delay of '${CLI_DELAY}' seconds and using database '${IF_COUCHDB}'"
else
    echo "${EXPMODE} for channel '${CHANNEL_NAME}' with CLI timeout of '${CLI_TIMEOUT}' seconds and CLI delay of '${CLI_DELAY}' seconds"
fi
# ask for confirmation to proceed
askProceed

# touch file if not exist
cd ATLChain_DEMO/server
if [ ! -f "app.log" ]
then
    touch app.log
fi

if [ ! -f "http.log" ]
then
    touch http.log
fi
cd ../..

cd ATLChain_NETWORK
# untar bin package
if [ ! -d "bin" ] 
then
    tar xvf bin.tar.xz
fi

# make directories if not exist
if [ ! -d "../ATLChain_DEMO/web/public/tmp" ] 
then
    mkdir ../ATLChain_DEMO/web/public/tmp
fi

if [ ! -d "../ATLChain_DEMO/web/public/msp" ] 
then
    mkdir ../ATLChain_DEMO/web/public/msp
fi

if [ ! -d "../ATLChain_DEMO/server/fabric-client-kv-orga" ] 
then
    mkdir ../ATLChain_DEMO/server/fabric-client-kv-orga
fi

if [ ! -d "channel-artifacts" ] 
then
    mkdir channel-artifacts
fi

#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
    networkUp
elif [ "${MODE}" == "down" ]; then ## Clear the network
    networkDown
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
    generateCerts $*
    # replacePrivateKey
    # generateChannelArtifacts
elif [ "${MODE}" == "restart" ]; then ## Restart the network
    networkDown
    networkUp
elif [ "${MODE}" == "upgrade" ]; then ## Upgrade the network from version 1.2.x to 1.3.x
    upgradeNetwork
else
    printHelp
    exit 1
fi
cd ..
