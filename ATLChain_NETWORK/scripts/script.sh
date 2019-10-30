#!/bin/bash

source /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/script.conf

echo "正在搭建网络 ......"

# . ./readConf.sh

function readConf() {
    while read line || [[ -n $line ]]; do
        # 判断配置段落
        if [ "$line" == "" ]; then
            continue
        elif [ $(echo $line | awk '{print $1}') == "Orderer:" ]; then
            varSwitch="orderer"
            continue
        elif [ $(echo $line | awk '{print $1}') == "Peer:" ]; then
            varSwitch="peer"
            continue
        elif [ $(echo $line | awk '{print $1}') == "SystemChannel:" ]; then
            varSwitch="syschannel"
            continue
        elif [ $(echo $line | awk '{print $1}') == "ApplicationChannel:" ]; then
            varSwitch="appchannel"
            continue
        fi

        # 将配置内容读进数组
        if [ $varSwitch == "orderer" ]; then
            ordererOrgArrays[${#ordererOrgArrays[@]}]=$line
        elif [ $varSwitch == "peer" ]; then
            peerOrgArrays[${#peerOrgArrays[@]}]=$line
        elif [ $varSwitch == "syschannel" ]; then
            sysChannelArrays[${#sysChannelArrays[@]}]=$line
        elif [ $varSwitch == "appchannel" ]; then
            appchannelArrays[${#appchannelArrays[@]}]=$line
        fi
    done <./conf/conf.conf

    # 根据配置文件中的信息自动分解出组织及其节点的详细信息
    getHostsInfo
}

# 获取各个组织的域名、节点信息
function getHostsInfo() {
    hosts=()
    OLD_IFS="$IFS"
    IFS=" "

    # 获取 Orderer 及其所有节点的信息
    i=0
    while [ $i -lt ${#ordererOrgArrays[@]} ]; do
        array=(${ordererOrgArrays[$i]})
        nodeNum=$(expr ${array[2]} - 1)
        nodeHosts=""
        while [ $nodeNum -ge 0 ]; do
            nodeHosts="$nodeHosts orderer${nodeNum}.${array[1]}"
            let nodeNum--
        done

        hosts[${#hosts[@]}]="${array[0]} ${array[1]} $nodeHosts"
        let i++
    done

    # 获取 Peer 及其所有节点的信息
    i=0
    while [ $i -lt ${#peerOrgArrays[@]} ]; do
        array=(${peerOrgArrays[$i]})
        nodeNum=$(expr ${array[2]} - 1)
        nodeHosts=""
        while [ $nodeNum -ge 0 ]; do
            nodeHosts="$nodeHosts peer${nodeNum}.${array[1]}"
            let nodeNum--
        done

        # 获取 CA 节点信息
        caArray=(${array[7]//,/ })
        for var in ${caArray[@]}; do
            nodeHosts="$nodeHosts $var"
        done

        hosts[${#hosts[@]}]="${array[0]} ${array[1]} $nodeHosts"
        let i++
    done
    IFS="$OLD_IFS"
}

function createChannel() {
    peer channel create -o ${ORERER_ADDRESS}:7050 -c $CHANNEL_NAME -f ../channel-artifacts/${CHANNEL_NAME}.tx --tls true --cafile $ORDERER_TLSCA >>log.txt

    # peer channel create -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.tx >&log.txt
    res=$?
    if [ $res -ne 0 ]; then
        echo " ERROR !!! 创建通道失败，请查看日志。"
        exit 1
    fi
}

function joinChannel() {
    peer channel join -b $CHANNEL_NAME.block >&log.txt
    res=$?
    if [ $res -ne 0 ]; then
        echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 加入通道失败，请查看日志。"
        exit 1
    fi
}

function updateAnchor() {
    peer channel update -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f ../channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls true --cafile $ORDERER_TLSCA >&log.txt

    # peer channel update -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
    res=$?
    if [ $res -ne 0 ]; then
        echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 更新锚节点失败，请查看日志。"
        exit 1
    fi
}

function installChaincode() {
    peer chaincode install ${CC_PKG_FILE} >&log.txt
    res=$?
    if [ $res -ne 0 ]; then
        echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 安装链码失败，请查看日志。"
        exit 1
    fi
}

function initChaincode() {
    peer chaincode instantiate -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC -v 1.0 --tls true --cafile $ORDERER_CA -c '{"Args": ["init"]}' -P "AND('OrgA.peer', 'OrgB.peer', 'OrgC.peer')" >&log.txt

    # peer chaincode instantiate -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC -v $CC_VERSION -c '{"Args": ["init"]}' -P "AND('OrgA.peer', 'OrgB.peer', 'OrgC.peer')" >&log.txt
    res=$?
    if [ $res -ne 0 ]; then
        echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 实例化链码失败，请查看日志。"
        exit 1
    fi
}

function invokeChaincode() {
    PEER0_ORGA_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/orga.example.com/peers/peer0.orga.example.com/tls/ca.crt
    peer chaincode invoke -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC --peerAddresses ${PEER_ADDRESS} --tlsRootCertFiles ${PEER_TLS_CERT_FILE} -c '{"Args":["Put", "tryPutkey", "{\"tryAddrReceive\":\"trytestAddrA\", \"tryAddrSend\":\"trytestAddrB\"}", "trysignagure", "trypubKey"]}' --tls true --cafile $ORDERER_CA >&log.txt

    # peer chaincode invoke -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC --peerAddresses peer0.orga.example.com:7051 --peerAddresses peer0.orgb.example.com:7051 --peerAddresses peer0.orgc.example.com:7051 -c '{"Args":["Put", "tryPutkey", "{\"tryAddrReceive\":\"trytestAddrA\", \"tryAddrSend\":\"trytestAddrB\"}", "trysignagure", "trypubKey"]}' >&log.txt
    res=$?
    if [ $res -ne 0 ]; then
        echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 调用链码失败，请查看日志。"
        exit 1
    fi
}

function queryChaincode() {
    peer chaincode query -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC --peerAddresses ${PEER_ADDRESS} --tlsRootCertFiles ${PEER_TLS_CERT_FILE} --tls true --cafile $ORDERER_CA -c '{"Args":["Get", "{\"tryAddrSend\":\"trytestAddrB\"}"]}' >&log.txt

    # peer chaincode query -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC -c '{"Args":["Get", "{\"tryAddrSend\":\"trytestAddrB\"}"]}' >&log.txt
    res=$?
    cat log.txt
    if [ $res -ne 0 ]; then
        echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 查询链码失败，请查看日志。"
        exit 1
    fi
}

# change org for different peers
function changeOrg() {
    org=$1
    if [ $org == "orga" ]; then
        export CORE_PEER_ADDRESS=$PEER0_ORGA_ADDRESS
        export CORE_PEER_LOCALMSPID=$PEER0_ORGA_LOCALMSPID
        export CORE_PEER_MSPCONFIGPATH=$PEER0_ORGA_MSPCONFIGPATH
    elif [ $org == "orgb" ]; then
        export CORE_PEER_ADDRESS=$PEER0_ORGB_ADDRESS
        export CORE_PEER_LOCALMSPID=$PEER0_ORGB_LOCALMSPID
        export CORE_PEER_MSPCONFIGPATH=$PEER0_ORGB_MSPCONFIGPATH
    elif [ $org == "orgc" ]; then
        export CORE_PEER_ADDRESS=$PEER0_ORGC_ADDRESS
        export CORE_PEER_LOCALMSPID=$PEER0_ORGC_LOCALMSPID
        export CORE_PEER_MSPCONFIGPATH=$PEER0_ORGC_MSPCONFIGPATH
    else
        echo "unknown org"
        exit 0
    fi
}

readConf

# echo ${appchannelArrays[@]}
# echo ${peerOrgArrays[1]}
# echo ${ordererOrgArrays[@]}
i=0
while [ $i -lt ${#appchannelArrays[@]} ]; do
    set -x
    # 创建通道
    appArray=(${appchannelArrays[$i]})
    ordererArray=(${ordererOrgArrays[$i]})
    peerArray=(${peerOrgArrays[$i]})
    export CORE_PEER_ADDRESS=peer0.${peerArray[1]}
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/users/Admin@${peerArray[1]}/msp
    export CORE_PEER_LOCALMSPID=${peerArray[0]}
    CHANNEL_NAME=$(echo ${appArray[0]} | tr '[A-Z]' '[a-z]')
    ORERER_ADDRESS=orderer0.${ordererArray[1]}
    ORDERER_TLSCA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ordererArray[1]}/tlsca/tlsca.${ordererArray[1]}-cert.pem

    createChannel
    set +x

    # 加入通道

    let i++
done

# # 加入通道
# set -x
# length=${#peersArray[@]}
# while (($length > 1)); do
#     url=$(echo ${peersArray[$length]} | awk '{print $1}')
#     idx=$(expr index $url '.')
#     orgurl=${url:$idx}
#     export CORE_PEER_ADDRESS=$url:7051
#     export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${orgurl}/users/Admin@${orgurl}/msp
#     export CORE_PEER_LOCALMSPID=$(echo ${peersArray[$length]} | awk '{print $2}')
#     export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${orgurl}/peers/$url/tls/ca.crt
#     export ORDERER_TLSCA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ordererOrgUrl}/tlsca/tlsca.${ordererOrgUrl}-cert.pem

#     joinChannel

#     length=$(expr $length - 1)
# done
# set +x

# for org in "orga" "orgb" "orgc"
# do
#     changeOrg $org
#     queryCC
#     joinChannel
#     updateAnchor
#     installCC
# done

# changeOrg orga
# initCC

# changeOrg orgb
# queryCC

# changeOrg orgc
# queryCC

# changeOrg orga
# invokeCC

# echo
# echo "========= All GOOD, network built successfully=========== "

echo
echo "   _____                                             "
echo "  / ____|                                            "
echo " | (___  _   _ _ __   ___ _ __ _ __ ___   __ _ _ __  "
echo "  \___ \| | | | '_ \ / _ \ '__| '_ \` _ \ / _\` | '_ \ "
echo "  ____) | |_| | |_) |  __/ |  | | | | | | (_| | |_) |"
echo " |_____/ \__,_| .__/ \___|_|  |_| |_| |_|\__,_| .__/ "
echo "              | |                             | |    "
echo "              |_|                             |_|    "
echo
