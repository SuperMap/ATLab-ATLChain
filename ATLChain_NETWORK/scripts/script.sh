#!/bin/bash

echo "正在搭建网络 ......"

# 创建通道
function createChannel() {
    echo "正在创建通道......"
    i=0
    while [ $i -lt ${#appchannelArrays[@]} ]; do
        appArray=(${appchannelArrays[$i]})
        ordererArray=(${ordererOrgArrays[$i]})
        peerArray=(${peerOrgArrays[$i]})
        export CORE_PEER_ADDRESS=peer0.${peerArray[1]}:7051
        export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/users/Admin@${peerArray[1]}/msp
        export CORE_PEER_LOCALMSPID=${peerArray[0]}
        export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/tlsca/tlsca.${peerArray[1]}-cert.pem
        CHANNEL_NAME=$(echo ${appArray[0]} | tr '[A-Z]' '[a-z]')
        ORERER_ADDRESS=orderer0.${ordererArray[1]}:7050
        ORDERER_TLSCA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ordererArray[1]}/tlsca/tlsca.${ordererArray[1]}-cert.pem

        echo "    ==>通道 $CHANNEL_NAME CREATING......"
        peer channel create -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f ../channel-artifacts/${CHANNEL_NAME}.tx --tls true --cafile $ORDERER_TLSCA >>log.log 2>&1

        # 不使用 TLS
        # peer channel create -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CHANNEL_NAME}.tx >>log.log 2>&1
        res=$?
        if [ $res -ne 0 ]; then
            echo " ERROR !!! 创建通道失败，请查看日志。"
            exit 1
        fi
        echo "    ==>通道 $CHANNEL_NAME CREATED"

        let i++
    done
}

# 加入通道
function joinChannel() {
    echo "节点正在加入通道......"

    i=0
    while [ $i -lt ${#appchannelArrays[@]} ]; do
        appArray=(${appchannelArrays[$i]})
        ordererArray=(${ordererOrgArrays[$i]})

        CHANNEL_NAME=$(echo ${appArray[0]} | tr '[A-Z]' '[a-z]')

        ii=0
        while [ $ii -lt ${#peerOrgArrays[@]} ]; do
            peerArray=(${peerOrgArrays[$ii]})

            export CORE_PEER_ADDRESS=peer0.${peerArray[1]}:7051
            export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/users/Admin@${peerArray[1]}/msp
            export CORE_PEER_LOCALMSPID=${peerArray[0]}
            export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/tlsca/tlsca.${peerArray[1]}-cert.pem

            echo "    ==>节点 $CORE_PEER_ADDRESS JOINING......"
            peer channel join -b $CHANNEL_NAME.block >>log.log 2>&1
            res=$?
            if [ $res -ne 0 ]; then
                echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 加入通道失败，请查看日志。"
                exit 1
            fi
            let ii++
        done
        echo "    ==>节点 $CORE_PEER_ADDRESS JOINED"

        let i++
    done
}

# 更新锚节点
function updateAnchor() {
    echo "正在更新组织锚节点......"

    i=0
    while [ $i -lt ${#appchannelArrays[@]} ]; do
        appArray=(${appchannelArrays[$i]})
        ordererArray=(${ordererOrgArrays[$i]})

        CHANNEL_NAME=$(echo ${appArray[0]} | tr '[A-Z]' '[a-z]')
        ORERER_ADDRESS=orderer0.${ordererArray[1]}:7050
        ORDERER_TLSCA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ordererArray[1]}/tlsca/tlsca.${ordererArray[1]}-cert.pem

        ii=0
        while [ $ii -lt ${#peerOrgArrays[@]} ]; do
            peerArray=(${peerOrgArrays[$ii]})

            export CORE_PEER_ADDRESS=peer0.${peerArray[1]}:7051
            export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/users/Admin@${peerArray[1]}/msp
            export CORE_PEER_LOCALMSPID=${peerArray[0]}
            export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/tlsca/tlsca.${peerArray[1]}-cert.pem

            echo "    ==>组织 $CORE_PEER_LOCALMSPID UPDATING......"
            peer channel update -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f ../channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls true --cafile $ORDERER_TLSCA >>log.log 2>&1

            # 不使用 TLS
            # peer channel update -o ${ORERER_ADDRESS} -c $CHANNEL_NAME -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx  >>log.log 2>&1
            res=$?
            if [ $res -ne 0 ]; then
                echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 更新锚节点失败，请查看日志。"
                exit 1
            fi
            echo "    ==>组织 $CORE_PEER_LOCALMSPID UPDATED"

            let ii++
        done

        let i++
    done
}

# 安装链码
function installChaincode() {
    echo "正在安装链码......"

    i=0
    while [ $i -lt ${#appchannelArrays[@]} ]; do
        appArray=(${appchannelArrays[$i]})
        ordererArray=(${ordererOrgArrays[$i]})

        CHANNEL_NAME=$(echo ${appArray[0]} | tr '[A-Z]' '[a-z]')
        ORERER_ADDRESS=orderer0.${ordererArray[1]}:7050
        ORDERER_TLSCA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ordererArray[1]}/tlsca/tlsca.${ordererArray[1]}-cert.pem

        ii=0
        while [ $ii -lt ${#peerOrgArrays[@]} ]; do
            peerArray=(${peerOrgArrays[$ii]})

            export CORE_PEER_ADDRESS=peer0.${peerArray[1]}:7051
            export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/users/Admin@${peerArray[1]}/msp
            export CORE_PEER_LOCALMSPID=${peerArray[0]}
            export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/tlsca/tlsca.${peerArray[1]}-cert.pem

            echo "    ==>节点 $CORE_PEER_ADDRESS INSTALLING......"
            peer chaincode install -l java ${CC_PKG_FILE} >>log.log 2>&1
            res=$?
            if [ $res -ne 0 ]; then
                echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 安装链码失败，请查看日志。"
                exit 1
            fi
            echo "    ==>节点 $CORE_PEER_ADDRESS INSTALLED"

            let ii++
        done

        let i++
    done
}

function initChaincode() {
    echo "正在示例化链码......"

    i=0
    while [ $i -lt ${#appchannelArrays[@]} ]; do
        appArray=(${appchannelArrays[$i]})
        ordererArray=(${ordererOrgArrays[$i]})
        peerArray=(${peerOrgArrays[$i]})
        export CORE_PEER_ADDRESS=peer0.${peerArray[1]}:7051
        export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/users/Admin@${peerArray[1]}/msp
        export CORE_PEER_LOCALMSPID=${peerArray[0]}
        export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/tlsca/tlsca.${peerArray[1]}-cert.pem
        CHANNEL_NAME=$(echo ${appArray[0]} | tr '[A-Z]' '[a-z]')
        ORERER_ADDRESS=orderer0.${ordererArray[1]}:7050
        ORDERER_TLSCA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ordererArray[1]}/tlsca/tlsca.${ordererArray[1]}-cert.pem

        echo "    ==>节点 $CORE_PEER_ADDRESS INSTANTIATING......"
        peer chaincode instantiate -o $ORERER_ADDRESS -C $CHANNEL_NAME -n atlchainCC -v 0.4.1 --tls true --cafile $ORDERER_TLSCA -c '{"Args": ["init"]}' >>log.log 2>&1

        # 不使用 TLS
        # peer chaincode instantiate -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC -v $CC_VERSION -c '{"Args": ["init"]}' -P "AND('OrgA.peer', 'OrgB.peer', 'OrgC.peer')" >>log.log 2>&1
        res=$?
        if [ $res -ne 0 ]; then
            echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 实例化链码失败，请查看日志。"
            exit 1
        fi
        echo "    ==>节点 $CORE_PEER_ADDRESS INSTANTIATED"

        let i++
    done
}

function invokeChaincode() {
    echo "正在测试写入数据......"
    echo "等一会儿，让链码运行起来......"
    sleep 5 &
    wait

    i=0
    while [ $i -lt ${#appchannelArrays[@]} ]; do
        appArray=(${appchannelArrays[$i]})
        ordererArray=(${ordererOrgArrays[$i]})

        CHANNEL_NAME=$(echo ${appArray[0]} | tr '[A-Z]' '[a-z]')
        ORERER_ADDRESS=orderer0.${ordererArray[1]}:7050
        ORDERER_TLSCA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ordererArray[1]}/tlsca/tlsca.${ordererArray[1]}-cert.pem

        ii=0
        while [ $ii -lt ${#peerOrgArrays[@]} ]; do
            peerArray=(${peerOrgArrays[$ii]})

            export CORE_PEER_ADDRESS=peer0.${peerArray[1]}:7051
            export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/users/Admin@${peerArray[1]}/msp
            export CORE_PEER_LOCALMSPID=${peerArray[0]}
            export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/tlsca/tlsca.${peerArray[1]}-cert.pem

            echo "    ==>节点 $CORE_PEER_ADDRESS WRITING......"
            peer chaincode invoke -o $ORERER_ADDRESS -C $CHANNEL_NAME -n atlchainCC -c '{"Args":["Put", "tryPutkey", "{\"tryAddrReceive\":\"trytestAddrA\", \"tryAddrSend\":\"trytestAddrB\"}", "trysignagure", "trypubKey"]}' --tls true --cafile $ORDERER_TLSCA >>log.log 2>&1

            # 不使用 TLS
            # peer chaincode invoke -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC --peerAddresses peer0.orga.example.com:7051 --peerAddresses peer0.orgb.example.com:7051 --peerAddresses peer0.orgc.example.com:7051 -c '{"Args":["Put", "tryPutkey", "{\"tryAddrReceive\":\"trytestAddrA\", \"tryAddrSend\":\"trytestAddrB\"}", "trysignagure", "trypubKey"]}' >>log.log 2>&1
            res=$?
            if [ $res -ne 0 ]; then
                echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 调用链码失败，请查看日志。"
                exit 1
            fi
            echo "    ==>节点 $CORE_PEER_ADDRESS WRITED"

            let ii++
        done

        let i++
    done
}

function queryChaincode() {
    echo "正在测试读取数据......"
    echo "等一会儿，让网络同步交易数据......"
    sleep 5 &
    wait

    i=0
    while [ $i -lt ${#appchannelArrays[@]} ]; do
        appArray=(${appchannelArrays[$i]})
        ordererArray=(${ordererOrgArrays[$i]})

        CHANNEL_NAME=$(echo ${appArray[0]} | tr '[A-Z]' '[a-z]')
        ORERER_ADDRESS=orderer0.${ordererArray[1]}:7050
        ORDERER_TLSCA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ordererArray[1]}/tlsca/tlsca.${ordererArray[1]}-cert.pem

        ii=0
        while [ $ii -lt ${#peerOrgArrays[@]} ]; do
            peerArray=(${peerOrgArrays[$ii]})

            export CORE_PEER_ADDRESS=peer0.${peerArray[1]}:7051
            export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/users/Admin@${peerArray[1]}/msp
            export CORE_PEER_LOCALMSPID=${peerArray[0]}
            export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${peerArray[1]}/tlsca/tlsca.${peerArray[1]}-cert.pem

            echo "节点 $CORE_PEER_ADDRESS 的查询结果为：（不为“[]”则正确）"
            peer chaincode query -o $ORERER_ADDRESS -C $CHANNEL_NAME -n atlchainCC --tls true --cafile $ORDERER_TLSCA -c '{"Args":["Get", "{\"tryAddrSend\":\"trytestAddrB\"}"]}' | tee -a log.log 2>&1

            # 不使用 TLS
            # peer chaincode query -o ${ORERER_ADDRESS} -C $CHANNEL_NAME -n atlchainCC -c '{"Args":["Get", "{\"tryAddrSend\":\"trytestAddrB\"}"]}' >>log.log 2>&1
            res=$?
            if [ $res -ne 0 ]; then
                echo " ERROR !!! 节点 $CORE_PEER_ADDRESS 查询链码失败，请查看日志。"
                exit 1
            fi
            let ii++
        done

        let i++
    done

}

. ./readConf.sh
readConf ./conf/conf.conf

createChannel
joinChannel
updateAnchor
installChaincode
initChaincode
invokeChaincode
queryChaincode

echo
echo "========= 网络搭建成功 =========== "

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
