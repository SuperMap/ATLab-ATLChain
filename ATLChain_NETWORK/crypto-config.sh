#!/bin/bash

# generate crypto-config.yaml
function genCryptoConfig() {
    if [ ! -d "crypto-config.yaml" ]; then
        touch crypto-config.yaml
    else
        rm crypto-config.yaml
    fi
    echo "OrdererOrgs:" >crypto-config.yaml

    while read line; do
        value=$(echo $line | awk '{print $1}')
        if [ $value == "Orderer:" ]; then
            varSwitch="orderer"
            continue
        elif [ $value == "Peer:" ]; then
            varSwitch="peer"
            echo "PeerOrgs:"  >> crypto-config.yaml
            continue
        fi

        if [ $varSwitch == "orderer" ]; then
            addOrgOrdererCryptoConfig $line
        elif [ $varSwitch == "peer" ]; then
            addOrgPeerCryptoConfig $line
        fi
    done <./conf/orgs.conf
}

function addOrgOrdererCryptoConfig() {
    # TODO 子节点数量需要可配置
    echo "  - Name: $1
    Domain: $2
    EnableNodeOUs: true
    Specs:" >> crypto-config.yaml

    count=0
    
    while(( $count<$3 )); do
        echo "      - Hostname: orderer${count}" >> crypto-config.yaml
        count=`expr $count + 1`
    done

    echo "" >>crypto-config.yaml
}

function addOrgPeerCryptoConfig() {
    echo "  - Name: $1
    Domain: $2
    EnableNodeOUs: true
    Template:
      Count: $3
    Users:
      Count: $4" >>crypto-config.yaml

    echo "" >>crypto-config.yaml
}

genCryptoConfig
