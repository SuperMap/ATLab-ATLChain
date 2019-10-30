#!/bin/bash

# generate configtx.yaml
function genConfigtx() {
    if [ ! -d "configtx.yaml" ]; then
        touch configtx.yaml
    else
        rm configtx.yaml
    fi
    echo "Organizations:" > configtx.yaml

    while read line; do
        value=$(echo $line | awk '{print $1}')
        if [ $value == "Orderer:" ]; then
            varSwitch="orderer"
            continue
        elif [ $value == "Peer:" ]; then
            varSwitch="peer"
            continue
        fi

        if [ $varSwitch == "orderer" ]; then
            addPart1Configtx $line
        elif [ $varSwitch == "peer" ]; then
            addPart2Configtx $line
        fi
    done < ./conf/orgs.conf

    addPart3Configtx

    while read line; do
        value=$(echo $line | awk '{print $1}')
        if [ $value == "SystemChannel:" ]; then
            varSwitch="system"
            continue
        elif [ $value == "ApplicationChannel:" ]; then
            varSwitch="app"
            continue
        fi

        if [ $varSwitch == "system" ]; then
            addPart5Configtx $line
        elif [ $varSwitch == "app" ]; then
            addPart6Configtx $line
        fi

    done < ./conf/channel.conf
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
                Rule: $5
            Writers:
                Type: Signature
                Rule: $6
            Admins:
                Type: Signature
                Rule: \"OR('$1.admin')\"

        OrdererEndpoints:" >> configtx.yaml
        string=$7
        array=(${string//,/ })  
        for var in ${array[@]}
        do
            echo "            - $var:7050" >> configtx.yaml
        done

        echo "        AnchorPeers:" >> configtx.yaml

        string=$8
        array=(${string//,/ })  
        for var in ${array[@]}
        do
            echo "            - Host: $var
              Port: 7051" >> configtx.yaml
        done
            

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
        <<: *ApplicationCapabilities

Orderer: &OrdererDefaults
    OrdererType: etcdraft
    Addresses: " >> configtx.yaml
    
    while read line; do
        domain=$(echo $line | awk '{print $1}')
        hostname=$(echo $line | awk '{print $2}')
        echo "        - $hostname.$domain:7050" >> configtx.yaml
    done < ./conf/raft.conf
    
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
        Consenters:" >> configtx.yaml

    while read line; do
        domain=$(echo $line | awk '{print $1}')
        hostname=$(echo $line | awk '{print $2}')
        echo "            - Host: $hostname.$domain
              Port: 7050
              ClientTLSCert: crypto-config/ordererOrganizations/$domain/orderers/$hostname.$domain/tls/server.crt
              ServerTLSCert: crypto-config/ordererOrganizations/$domain/orderers/$hostname.$domain/tls/server.crt" >> configtx.yaml
    done < ./conf/raft.conf

    echo "" >> configtx.yaml
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
            Organizations:" >>configtx.yaml

    string=$2
    array=(${string//,/ })  
    for var in ${array[@]}
    do
        echo "                - <<: *$var" >> configtx.yaml
    done

    echo "            Capabilities:
                <<: *OrdererCapabilities
        Consortiums:
            SampleConsortium:
                Organizations:" >> configtx.yaml

    string=$3
    array=(${string//,/ })  
    for var in ${array[@]}
    do
        echo "                - <<: *$var" >> configtx.yaml
    done

    echo "" >> configtx.yaml
}

function addPart6Configtx() {
    echo "    $1:
        Consortium: SampleConsortium
        <<: *ChannelDefaults
        Application:
            <<: *ApplicationDefaults
            Organizations:" >> configtx.yaml

    string=$2
    array=(${string//,/ })  
    for var in ${array[@]}
    do       
        echo "                - *$var" >> configtx.yaml
    done

    echo "            Capabilities:
                <<: *ApplicationCapabilities" >>configtx.yaml

    echo "" >>configtx.yaml
}

