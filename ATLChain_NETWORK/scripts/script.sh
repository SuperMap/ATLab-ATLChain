#!/bin/bash

source /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/script.conf

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
function createChannel(){
    set -x
    # peer channel create -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f ./channel-artifacts/${CHANNEL_NAME}.tx --tls true --cafile $ORDERER_CA  >& log.txt 
    
    peer channel create -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.tx >& log.txt 
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "===========$res============="
        echo " ERROR !!! FAILED to create channel"
        exit 1
    fi
}

# join channel 
function joinChannel(){
    set -x
    peer channel join -b $CHANNEL_NAME.block >& log.txt
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "===========$res============="
        echo " ERROR !!! FAILED to join channel"
        exit 1
    fi
}

# update anchor peer
function updateAnchor(){
    set -x
    # peer channel update -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls true --cafile $ORDERER_CA >& log.txt 
    
    peer channel update -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >& log.txt 
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "===========$res============="
        echo " ERROR !!! FAILED to update anchor peer"
        exit 1
    fi
}

# install chaincode 
function installCC(){
    set -x
    peer chaincode install ${CC_PKG_FILE} >& log.txt 
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "===========$res============="
        echo " ERROR !!! FAILED to install chaincode"
        exit 1
    fi
}
 
# instantiated chaincode 
function initCC(){
    set -x
    # peer chaincode instantiate -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC -v 1.0 --tls true --cafile $ORDERER_CA -c '{"Args": ["init"]}' -P "AND('OrgA.peer', 'OrgB.peer', 'OrgC.peer')" >& log.txt 
    
    peer chaincode instantiate -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC -v $CC_VERSION -c '{"Args": ["init"]}' -P "AND('OrgA.peer', 'OrgB.peer', 'OrgC.peer')" >& log.txt 
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "===========$res============="
        echo " ERROR !!! FAILED to instantiate chaincode"
        exit 1
    fi
}

# invoke chaincode
function invokeCC(){
    PEER0_ORGA_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/orga.atlchain.com/peers/peer0.orga.atlchain.com/tls/ca.crt
    set -x
    # peer chaincode invoke -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC --peerAddresses ${PEER_ADDRESS} --tlsRootCertFiles ${PEER_TLS_CERT_FILE} -c '{"Args":["Put", "tryPutkey", "{\"tryAddrReceive\":\"trytestAddrA\", \"tryAddrSend\":\"trytestAddrB\"}", "trysignagure", "trypubKey"]}' --tls true --cafile $ORDERER_CA >& log.txt
    
    peer chaincode invoke -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC --peerAddresses peer0.orga.atlchain.com:7051 --peerAddresses peer0.orgb.atlchain.com:7051 --peerAddresses peer0.orgc.atlchain.com:7051 -c '{"Args":["Put", "tryPutkey", "{\"tryAddrReceive\":\"trytestAddrA\", \"tryAddrSend\":\"trytestAddrB\"}", "trysignagure", "trypubKey"]}' >& log.txt
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "===========$res============="
        echo " ERROR !!! FAILED to invoke chaincode"
        # exit 1
    fi
}

# query chaincode
function queryCC(){
    set -x
    # peer chaincode query -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC --peerAddresses ${PEER_ADDRESS} --tlsRootCertFiles ${PEER_TLS_CERT_FILE} --tls true --cafile $ORDERER_CA -c '{"Args":["Get", "{\"tryAddrSend\":\"trytestAddrB\"}"]}' >& log.txt
    
    peer chaincode query -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC -c '{"Args":["Get", "{\"tryAddrSend\":\"trytestAddrB\"}"]}' >& log.txt
    res=$?
    set +x
    cat log.txt   
    if [ $res -ne 0 ]; then
        echo "===========$res============="
        echo " ERROR !!! FAILED to query chaincode"
        exit 1
    fi
}

# change org for different peers
function changeOrg(){
    org=$1
    if [ $org == "orga" ]
    then
        export CORE_PEER_ADDRESS=$PEER0_ORGA_ADDRESS
        export CORE_PEER_LOCALMSPID=$PEER0_ORGA_LOCALMSPID
        export CORE_PEER_MSPCONFIGPATH=$PEER0_ORGA_MSPCONFIGPATH
    elif [ $org == "orgb" ]
    then 
        export CORE_PEER_ADDRESS=$PEER0_ORGB_ADDRESS
        export CORE_PEER_LOCALMSPID=$PEER0_ORGB_LOCALMSPID
        export CORE_PEER_MSPCONFIGPATH=$PEER0_ORGB_MSPCONFIGPATH
    elif [ $org == "orgc" ]
    then
        export CORE_PEER_ADDRESS=$PEER0_ORGC_ADDRESS
        export CORE_PEER_LOCALMSPID=$PEER0_ORGC_LOCALMSPID
        export CORE_PEER_MSPCONFIGPATH=$PEER0_ORGC_MSPCONFIGPATH
    else
        echo "unknown org"
        exit 0
    fi
}

# The first peer create channel
# createChannel;

for org in "orga" "orgb" "orgc"
do
    changeOrg $org
    queryCC
    joinChannel
    updateAnchor
    installCC
done

changeOrg orga
initCC

changeOrg orgb
queryCC

changeOrg orgc
queryCC

changeOrg orga
invokeCC

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
