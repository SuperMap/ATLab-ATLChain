#!/bin/bash

# 读取配置文件
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
        elif [ $(echo $line | awk '{print $1}') == "Chaincode:" ]; then
            varSwitch="chaincode"
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
        elif [ $varSwitch == "chaincode" ]; then
            CC_PKG_FILE=$line
        fi
    done <$1

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
