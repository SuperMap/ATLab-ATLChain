#!/bin/bash

# generate configtx.yaml
function genConfigtx() {
    if [ ! -d "configtx.yaml" ]; then
        touch configtx.yaml
    else
        rm configtx.yaml
    fi
    echo "Organizations:" >configtx.yaml

    OLD_IFS="$IFS"
    IFS=" "

    i=0
    while [ $i -lt ${#ordererOrgArrays[@]} ]; do
        ordererArray=(${ordererOrgArrays[$i]})
        addPart1Configtx ${ordererArray[@]}
        let i++
    done

    echo "PeerOrgs:" >>crypto-config.yaml
    i=0
    while [ $i -lt ${#peerOrgArrays[@]} ]; do
        peerArray=(${peerOrgArrays[$i]})
        addPart2Configtx ${peerArray[@]}
        let i++
    done

    i=0
    while [ $i -lt ${#ordererOrgArrays[@]} ]; do
        ordererArray=(${ordererOrgArrays[$i]})
        addPart3Configtx ${ordererArray[@]}
        let i++
    done

    i=0
    while [ $i -lt ${#sysChannelArrays[@]} ]; do
        sysArray=(${sysChannelArrays[$i]})
        addPart5Configtx ${sysArray[@]}
        let i++
    done

    echo "PeerOrgs:" >>crypto-config.yaml
    i=0
    while [ $i -lt ${#appchannelArrays[@]} ]; do
        appArray=(${appchannelArrays[$i]})
        addPart6Configtx ${appArray[@]}
        let i++
    done

    IFS="$OLD_IFS"

}

function addPart1Configtx() {
    echo "    - &$1
        Name: $1
        ID: $1
        MSPDir: crypto-config/ordererOrganizations/$2/msp
        Policies: &$1Policies
            Readers:
                Type: Signature
                Rule: $4
            Writers:
                Type: Signature
                Rule: $5
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
                Rule: $4
            Writers:
                Type: Signature
                Rule: $5
            Admins:
                Type: Signature
                Rule: \"OR('$1.admin')\"

        OrdererEndpoints:" >>configtx.yaml
    string=$6
    array=(${string//,/ })
    for var in ${array[@]}; do
        echo "            - $var:7050" >>configtx.yaml
    done

    echo "        AnchorPeers:" >>configtx.yaml

    string=$7
    array=(${string//,/ })
    for var in ${array[@]}; do
        echo "            - Host: $var
              Port: 7051" >>configtx.yaml
    done

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
        <<: *ApplicationCapabilities

Orderer: &OrdererDefaults
    OrdererType: etcdraft
    Addresses: " >>configtx.yaml

    count=0
    while (($count < $3)); do
        echo "        - orderer${count}.$2:7050" >>configtx.yaml
        count=$(expr $count + 1)
    done

    echo "    BatchTimeout: 2s

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
        Consenters:" >>configtx.yaml

    count=0
    while (($count < $3)); do
        echo "            - Host: orderer${count}.$2
              Port: 7050
              ClientTLSCert: crypto-config/ordererOrganizations/$2/orderers/orderer${count}.$2/tls/server.crt
              ServerTLSCert: crypto-config/ordererOrganizations/$2/orderers/orderer${count}.$2/tls/server.crt" >>configtx.yaml
        count=$(expr $count + 1)
    done

    echo "" >>configtx.yaml
    echo "        Options:
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
            Organizations:" >>configtx.yaml

    string=$2
    array=(${string//,/ })
    for var in ${array[@]}; do
        echo "                - <<: *$var" >>configtx.yaml
    done

    echo "            Capabilities:
                <<: *OrdererCapabilities
        Consortiums:
            SampleConsortium:
                Organizations:" >>configtx.yaml

    string=$3
    array=(${string//,/ })
    for var in ${array[@]}; do
        echo "                - <<: *$var" >>configtx.yaml
    done

    echo "" >>configtx.yaml
}

function addPart6Configtx() {
    echo "    $1:
        Consortium: SampleConsortium
        <<: *ChannelDefaults
        Application:
            <<: *ApplicationDefaults
            Organizations:" >>configtx.yaml

    string=$2
    array=(${string//,/ })
    for var in ${array[@]}; do
        echo "                - *$var" >>configtx.yaml
    done

    echo "            Capabilities:
                <<: *ApplicationCapabilities" >>configtx.yaml

    echo "" >>configtx.yaml
}
