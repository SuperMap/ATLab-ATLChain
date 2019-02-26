#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build atlchain demo"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=10

CC_SRC_PATH="github.com/chaincode/"
if [ "$LANGUAGE" = "node" ]; then
    CC_SRC_PATH="github.com/chaincode/"
	# CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

if [ "$LANGUAGE" = "java" ]; then
    CC_SRC_PATH="github.com/chaincode/"
	# CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/java/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        set -x
		peer channel create -o orderer0.orga.atlchain.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/atlchannel.tx >&log.txt
		res=$?
        set +x
	else
		set -x
		peer channel create -o orderer0.orga.atlchain.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/atlchannel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
		set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
	for org in 1 2; do
	    for peer in 0 1; do
		    joinChannelWithRetry $peer $org

            if [ $org -eq 1 ]; then
                ORGNAME="a"
            else
                ORGNAME="b"
            fi
		    echo "===================== peer${peer}.org${ORGNAME} joined channel '$CHANNEL_NAME' ===================== "
		    sleep $DELAY
		    echo
	    done
	done
}

##
# docker exec -it ca0.atlchain.com sed -i "s/org1/Org1/g" /etc/hyperledger/fabric-ca-server/fabric-ca-server-config.yaml 

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for orga..."
updateAnchorPeers 0 1
echo "Updating anchor peers for orgb..."
updateAnchorPeers 0 2

## Install chaincode on peer0.orga and peer0.orgb
echo "Installing chaincode on peer0.orga..."
installChaincode 0 1
echo "Install chaincode on peer0.orgb..."
installChaincode 0 2

# Instantiate chaincode on peer0.orgb
echo "Instantiating chaincode on peer0.orgb..."
instantiateChaincode 0 2
sleep $DELAY

# Invoking chaincode on peer0.orga
echo "Invoking chaincode on peer0.orga..."
chaincodeInvoke 0 A

# Query chaincode on peer0.orga
echo "Querying chaincode on peer0.orga..."
chaincodeQuery 0 1

# Invoke chaincode on peer0.orga and peer0.orgb
echo "Sending invoke transaction on peer0.orga peer0.orgb..."
chaincodeInvoke 0 A 0 B

## Install chaincode on peer1.orgb
echo "Installing chaincode on peer1.orgb..."
installChaincode 1 2

# Query on chaincode on peer1.orgb, check if the result is 90
echo "Querying chaincode on peer1.orgb..."
chaincodeQuery 1 2

# cd demo/server
# if [ ! -d node_modules ]
# then
#     npm install
# fi
# nohup node app > app.log 2>&1 &
# nohup node http > http.log 2>&1 &

echo
echo "========= All GOOD, building ATLCHAIN DEMO execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
