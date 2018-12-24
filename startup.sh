#!/bin/bash

function startOrderer() {
    echo ""
    echo "############### Start orderer ###############"
    echo ""
    cd config 
    nohup orderer start > orderer.log 2>&1 &
    cd ..
    echo ""
    echo "############### Start orderer Done ###############"
    echo ""
}

function stopOrderer() {
    echo ""
    echo "############### Stop orderer ###############"
    echo ""
    ps -aux | grep 'orderer start' | awk '{print $2}' | sed -n 1p | xargs kill -9
    echo ""
    echo "############### Stop orderer Done ###############"
    echo ""
}

function startPeer() {
    echo ""
    echo "############### Start peer ###############"
    echo ""
    cd config 
    echo "PeerID: OrgA"
    echo "msp path: crypto-config/peerOrganizations/orga.atlchain.com/users/Admin@orga.atlchain.com/msp"
    export CORE_PEER_LOCALMSPID=OrgA
    export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orga.atlchain.com/users/Admin@orga.atlchain.com/msp
    nohup peer node start > peer.log 2>&1 &
    cd ..
    echo ""
    echo "############### Start peer Done ###############"
    echo ""
}

function stopPeer() {
    echo ""
    echo "############### Stop peer ###############"
    echo ""
    ps -aux | grep 'peer node start' | awk '{print $2}' | sed -n 1p | xargs kill -9
    echo ""
    echo "############### Stop peer Done ###############"
    echo ""
}

function startCA() {
    echo ""
    echo "############### Start CA ###############"
    echo ""
    cd ca-config 
    nohup fabric-ca-server start -b admin:adminpw > ca.log 2>&1 &
    cd ..
    echo ""
    echo "############### Start CA Done ###############"
    echo ""
}

function stopCA() {
    echo ""
    echo "############### Stop CA ###############"
    echo ""
    ps -aux | grep 'fabric-ca-server start -b admin:adminpw' | awk '{print $2}' | sed -n 1p | xargs kill -9
    echo ""
    echo "############### Stop CA Done ###############"
    echo ""
}

function startRESTServer() {
    echo ""
    echo "############### Start REST Server ###############"
    echo ""
    nohup node ./app.js > ./app.log 2>&1 &
    echo "REST Server running at http://localhost:4000"
    echo ""
    echo "############### Start REST Server Done ###############"
    echo ""
}

function stopRESTServer() {
    echo ""
    echo "############### Stop REST Server ###############"
    echo ""
    ps -aux | grep 'node ./app.js' | awk '{print $2}' | sed -n 1p | xargs kill -9
    echo ""
    echo "############### Stop REST Server Done ###############"
    echo ""
}

function startWebServer() {
    echo ""
    echo "############### Start Web Server ###############"
    echo ""
    cd web
    nohup node ./server.js > ./server.log 2>&1 &
    echo "Server running at http://localhost:8080"
    cd ..
    echo ""
    echo "############### Start Web Server Done ###############"
    echo ""
}

function stopWebServer() {
    echo ""
    echo "############### Stop Web Server ###############"
    echo ""
    ps -aux | grep 'node ./server.js' | awk '{print $2}' | sed -n 1p | xargs kill -9
    echo ""
    echo "############### Stop Web Server Done ###############"
    echo ""
}

if [ $1 = "start" ] 
then
    startCA
    startOrderer
    startPeer
    startRESTServer
    startWebServer
elif [ $1 = "stop" ]
then
    stopWebServer
    stopPeer
    stopOrderer
    stopCA
    stopRESTServer
fi

