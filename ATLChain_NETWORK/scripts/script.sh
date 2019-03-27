#!/bin/bash

CHANNEL_NAME=$1
CC_SRC_PATH="github.com/chaincode/"
ORERER_ADDRESS=172.16.15.66:7050
PEER_ADDRESS=172.16.15.66:7051

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Building your network ......"
echo

# create channel
set -x
peer channel create -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx >& log.txt 
# peer channel create -o orderer0.orga.atlchain.com -c $CHANNEL_NAME -f ./channel-artifacts/atlchannel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
res=$?
set +x
if [ $res -ne 0 ]; then
    echo "===========$res============="
    echo " ERROR !!! FAILED to create channel"
    exit 1
fi

# join channel 
set -x
peer channel join -b $CHANNEL_NAME.block >& log.txt
res=$?
set +x
if [ $res -ne 0 ]; then
    echo "===========$res============="
    echo " ERROR !!! FAILED to join channel"
    exit 1
fi

# update anchor peer
set -x
peer channel update -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >& log.txt 
# peer channel update -o orderer0.orga.atlchain.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >& log.txt
res=$?
set +x
if [ $res -ne 0 ]; then
    echo "===========$res============="
    echo " ERROR !!! FAILED to update anchor peer"
    exit 1
fi

# install chaincode 
set -x
peer chaincode install -v 1.0 -n atlchainCC -p ${CC_SRC_PATH} >& log.txt 
res=$?
set +x
if [ $res -ne 0 ]; then
    echo "===========$res============="
    echo " ERROR !!! FAILED to install chaincode"
    exit 1
fi

# instantiated chaincode 
set -x
peer chaincode instantiate -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC -v 1.0 -c '{"Args": ["init"]}' -P "AND('OrgA.peer')" >& log.txt 
# peer chaincode instantiate -o orderer0.orga.atlchain.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n atlchainCC -v 1.0 -c '{"Args": ["init"]}'  -P "AND('OrgA.peer', 'OrgB.peer')" >& log.txt
res=$?
set +x
if [ $res -ne 0 ]; then
    echo "===========$res============="
    echo " ERROR !!! FAILED to instantiate chaincode"
    exit 1
fi

sleep 10

# invoke 
PEER0_ORGA_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/orga.atlchain.com/peers/peer0.orga.atlchain.com/tls/ca.crt
set -x
peer chaincode invoke -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC --peerAddresses ${PEER_ADDRESS} -c '{"Args":["Put", "tryPutkey", "{\"tryAddrReceive\":\"trytestAddrA\", \"tryAddrSend\":\"trytestAddrB\"}", "trysignagure", "trypubKey"]}' >& log.txt
# peer chaincode invoke -o orderer0.orga.atlchain.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n atlchainCC --peerAddresses peer0.orga.atlchain.com:7051 -c '{"Args":["Put", "tryPutkey", "{\"tryAddrReceive\":\"trytestAddrA\", \"tryAddrSend\":\"trytestAddrB\"}", "trysignagure", "trypubKey"]}' >&log.txt
res=$?
set +x
if [ $res -ne 0 ]; then
    echo "===========$res============="
    echo " ERROR !!! FAILED to invoke chaincode"
    # exit 1
fi

sleep 20

# query
set -x
peer chaincode query -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC --peerAddresses ${PEER_ADDRESS} -c '{"Args":["Get", "{\"tryAddrSend\":\"trytestAddrB\"}"]}' >& log.txt
# peer chaincode query -o orderer0.orga.atlchain.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n atlchainCC --peerAddresses peer0.orga.atlchain.com:7051 -c '{"Args":["Get", "{\"tryAddrSend\":\"trytestAddrB\"}"]}' >& log.txt
res=$?
set +x
cat log.txt   
if [ $res -ne 0 ]; then
    echo "===========$res============="
    echo " ERROR !!! FAILED to query chaincode"
    exit 1
fi

echo
echo "========= All GOOD, network built successfully=========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

