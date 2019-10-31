#!/bin/bash

# 生成 crypto-config.yaml
function genCryptoConfig() {
    if [ ! -d "crypto-config.yaml" ]; then
        touch crypto-config.yaml
    else
        rm crypto-config.yaml
    fi

    echo "OrdererOrgs:" >crypto-config.yaml
    OLD_IFS="$IFS"
    IFS=" "

    i=0
    while [ $i -lt ${#ordererOrgArrays[@]} ]; do
        ordererArray=(${ordererOrgArrays[$i]})
        addOrgOrdererCryptoConfig ${ordererArray[@]}
        let i++
    done

    echo "PeerOrgs:" >>crypto-config.yaml
    i=0
    while [ $i -lt ${#peerOrgArrays[@]} ]; do
        peerArray=(${peerOrgArrays[$i]})
        addOrgPeerCryptoConfig ${peerArray[@]}
        let i++
    done

    IFS="$OLD_IFS"
}

# 生成 OrdererOrgs 部分
function addOrgOrdererCryptoConfig() {
    echo "  - Name: $1
    Domain: $2
    EnableNodeOUs: true
    Specs:" >>crypto-config.yaml

    count=0
    while (($count < $3)); do
        echo "      - Hostname: orderer${count}" >>crypto-config.yaml
        count=$(expr $count + 1)
    done

    echo "" >>crypto-config.yaml
}

# 生成
function addOrgPeerCryptoConfig() {
    echo "  - Name: $1
    Domain: $2
    EnableNodeOUs: true
    Template:
      Count: $3
    Users:
      Count: 2" >>crypto-config.yaml

    echo "" >>crypto-config.yaml
}
