## 网络配置文件夹

- crypto-config.yaml: 密钥配置文件
- configtx.yaml: 组织、通道配置文件
- core.yaml: peer节点配置文件
- orderer.yaml: orderer节点配置文件

#### ccpack.out 来自于
```
$ peer chaincode package -n cc -p github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd -v 1.02 ccpack.out
```

#### 网络搭建测试脚本

1. 生成密钥文件
```
$ cryptogen generate --config=crypto-config.yaml
```

2. 生成orderer创世块
```
$ configtxgen -profile OrdererChannel -outputBlock genesisblock -channelID ordererchannel
```

3. 启动orderer节点（需要在另外一个终端中执行）
```
$ orderer start
```

4. 启动peer节点（需要在另外一个终端中执行）
```
$ peer node start
```

5. 创建通道提案文件
```
$ configtxgen -profile TxChannel -outputCreateChannelTx atlchannel.tx -channelID atlchannel
```

6. 创建锚节点通知提案
```
$ configtxgen -profile TxChannel -outputAnchorPeersUpdate OrgAanchors.tx -channelID atlchannel -asOrg OrgA
```

7. 设置环境变量，创建Channel的组织的编号
```
$ export CORE_PEER_LOCALMSPID=OrgA
```

8. 设置环境变量，执行创建channel的用户账号
```
$ export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orga.atlchain.com/users/Admin@orga.atlchain.com/msp
```

export CORE_PEER_TLS_ENABLED=true

export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/crypto-config/peerOrganizations/orga.atlchain.com/tlsca/tlsca.orga.atlchain.com-cert.pem

peer channel create -o 127.0.0.1:7050 -c atlchannel -f atlchannel.tx --tls --cafile ./crypto-config/peerOrganizations/orga.atlchain.com/tlsca/tlsca.orga.atlchain.com-cert.pem

9. 创建Channel创世块
```
$ peer channel create -o 127.0.0.1:7050 -c atlchannel -f atlchannel.tx
```

10. 加入Channel
```
$ peer channel join -b atlchannel.block
```

11. 通知锚节点
```
$ peer channel update -o 127.0.0.1:7050 -c atlchannel -f OrgAanchors.tx
```

12. 安装链码
```
$ peer chaincode install -n cc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd/
```

13. 实例化链码
```
$ peer chaincode instantiate -o 127.0.0.1:7050 -C atlchannel -n cc -v 1.0 -c '{"Args":["init","a","100","b","200"]}'
```

14. 查询链码
```
$ peer chaincode query -C atlchannel -n cc -c '{"Args":["query","a"]}'
```

15. 链码执行交易
```
$ peer chaincode invoke -o orderer.cystone.me:7050 -C atlchannel -n cc -c '{"Args":["invoke","a","b","1"]}'
```

16. 生成私钥
```
$ openssl genrsa -out test.key 1024
```

17. 生成公钥
```
$ openssl rsa -in test.key -pubout -out test_pub.key
```


// peer1orgb  sshT1
export CORE_PEER_LOCALMSPID=OrgB

export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orgb.atlchain.com/users/Admin@orgb.atlchain.com/msp

// peer0orga  sshT2
export CORE_PEER_LOCALMSPID=OrgA

export export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orga.atlchain.com/users/Admin@orga.atlchain.com/msp

// peer0orgb  sshT3
export CORE_PEER_LOCALMSPID=OrgB

export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orgb.atlchain.com/users/Admin@orgb.atlchain.com/msp