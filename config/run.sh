#!/bin/sh
if [ $1 = clean ]
then
    rm atlchannel.block atlchannel.tx genesisblock OrgAanchors.tx

    rm -rf ./production

elif [ $1 = s1 ]
then
    # echo "### configtxgen -profile OrdererOrg --outputBlock orderer.genesis.block ###"
    # cryptogen generate --config=crypto-config.yaml

    echo "### configtxgen -profile OrdererChannel --outputBlock genesisblock ###"
    configtxgen -profile OrdererChannel --outputBlock genesisblock

    echo "### Finish stage 1 ###"

    echo "### You should start Ordere and peer ###"
    
elif [ $1 = s2 ]
then
    echo "### configtxgen -profile TxChannel -outputCreateChannelTx atlchannel.tx -channelID atlchannel ###"
    configtxgen -profile TxChannel -outputCreateChannelTx atlchannel.tx -channelID atlchannel

    echo "### configtxgen -profile TxChannel -outputAnchorPeersUpdate OrgAanchors.tx -channelID atlchannel -asOrg OrgA ###"
    configtxgen -profile TxChannel -outputAnchorPeersUpdate OrgAanchors.tx -channelID atlchannel -asOrg OrgA

    echo "### export CORE_PEER_LOCALMSPID=OrgA ###"
    export CORE_PEER_LOCALMSPID=OrgA
     
    echo "### export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orga.atlchain.com/users/Admin@orga.atlchain.com/msp ###"
    export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orga.atlchain.com/users/Admin@orga.atlchain.com/msp

    echo "### peer channel create -o 127.0.0.1:7050 -c atlchannel -f atlchannel.tx ###"
    peer channel create -o 127.0.0.1:7050 -c atlchannel -f atlchannel.tx

    echo "### peer channel join -b atlchannel.block ###"
    peer channel join -b atlchannel.block
    
    echo "###  peer channel update -o 127.0.0.1:7050 -c atlchannel -f OrgAanchors.tx ###"
    peer channel update -o 127.0.0.1:7050 -c atlchannel -f OrgAanchors.tx

    echo "### peer chaincode install -n cc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd/ ###"
    peer chaincode install -n cc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd/ 
    
    echo "### peer chaincode instantiate -o 127.0.0.1:7050 -C atlchannel -n cc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' ###"
    peer chaincode instantiate -o 127.0.0.1:7050 -C atlchannel -n cc -v 1.0 -c '{"Args":["init","a","100","b","200"]}'
     
    echo "### Finish stage 2 ###"
elif [ $1 = query ]
then 
    echo "### query ###"
    peer chaincode query -C atlchannel -n cc -c '{"Args":["query","a"]}'
elif [ $1 = invoke ]
then
    echo "### invoke ###"
    peer chaincode invoke -o 127.0.0.1:7050 -C atlchannel -n cc -c '{"Args":["invoke","a","b","1"]}'
fi
