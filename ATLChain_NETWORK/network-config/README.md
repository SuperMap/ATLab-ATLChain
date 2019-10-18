## 网络配置文件夹

- crypto-config.yaml: 密钥配置文件
- configtx.yaml: 组织、通道配置文件
- core.yaml: peer节点配置文件
- orderer.yaml: orderer节点配置文件

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
$ export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orga.example.com/users/Admin@orga.example.com/msp
```
/////////////////////三个服务器的环境变量/////////////////////////
// peer1orgb  sshT1
export CORE_PEER_LOCALMSPID=OrgB

export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orgb.example.com/users/Admin@orgb.example.com/msp

// peer0orga  sshT2
export CORE_PEER_LOCALMSPID=OrgA

export export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orga.example.com/users/Admin@orga.example.com/msp

// peer0orgb  sshT3
export CORE_PEER_LOCALMSPID=OrgB

export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orgb.example.com/users/Admin@orgb.example.com/msp
///////////////////////////////////////////////////////////

///////////////////使用TLS的时候/////////////////////////////
export CORE_PEER_TLS_ENABLED=true

export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/crypto-config/peerOrganizations/orga.example.com/tlsca/tlsca.orga.example.com-cert.pem

peer channel create -o 127.0.0.1:7050 -c atlchannel -f atlchannel.tx --tls --cafile ./crypto-config/peerOrganizations/orga.example.com/tlsca/tlsca.orga.example.com-cert.pem
/////////////////////////////////////////////////////////////

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

#### 链码打包（package）
1. 打包
```
$ peer chaincode package -n cc -p github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd -v 1.02 ccpack.out
```

2. 安装
```
$ peer chaincode install ccpack.out
```

#### CA使用
**Fabric CA Server**
1. 初始化 Fabric CA Server
```
// 1.用户名密码可以自定义
// 2.init后会生成配置文件 “fabric-ca-server-config.yaml” ，如需修改配置文件，修改之后再次执行初始化即可
// 3.CA 根证书应该使用对应组织的根证书
$ fabric-ca-server init -b admin:adminpw
```

2. 启动 Fabric CA Server
```
$ fabric-ca-server start

// 或者使用默认配置快速启动，该过程也会先执行 init，然后启动 server
$ fabric-ca-server start -b admin:adminpw
```
**Fabric CA Client**
3. enroll
```
$ export FABRIC_CA_CLIENT_HOME=$PWD/admin
$ fabric-ca-client enroll -u http://admin:adminpw@127.0.0.1:7054
```

enroll （登记）的过程是，用户获取证书、私钥和CA根证书的过程。

4. register
```
// 1.register 成功之后会返回一个密码，用户 enroll 的时候需要使用这个密码
// 2.这个密码也可以在 register 的时候通过 --id.secret passwd 来指定
// 3.register 的时候有很多参数可设置，具体可参考 (Fabric CA 官方文档- Fabric CA Client 部分)[https://hyperledger-fabric-ca.readthedocs.io/en/latest/users-guide.html#fabric-ca-client]。

$ fabric-ca-client register --id.name client2 --id.affiliation org1.department1 --id.attrs 'hf.IntermediateCA=false' --id.type=client
```

**注册的用户得到密码之后，就可以在自己的主机上 enroll ，获取证书和私钥了， enroll 过程参考第 3 步**