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
$ configtxgen -profile OrdererOrg --outputBlock orderer.genesis.block
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
$ configtxgen -profile TxChannel -outputCreateChannelTx fabricchannel.tx -channelID fabricchannel
```

6. 创建锚节点通知提案
```
$ configtxgen -profile TxChannel -outputAnchorPeersUpdate OrgAMSPanchors.tx -channelID fabricchannel -asOrg OrgAMSP
```

7. 设置环境变量，创建Channel的组织的编号
```
$ export CORE_PEER_LOCALMSPID=OrgAMSP
```

8. 设置环境变量，执行创建channel的用户账号
```
$ export CORE_PEER_MSPCONFIGPATH=/home/cy/Documents/ATL/SuperMap/ATLab-ATLChain/config/crypto-config/peerOrganizations/orga.atlchain.com/users/Admin@orga.atlchain.com/msp
```

9. 创建Channel创世块
```
$ peer channel create -o 127.0.0.1:7050 -c fabricchannel -f fabricchannel.tx
```

10. 加入Channel
```
$ peer channel join -b fabricchannel.block
```

11. 通知锚节点
```
$ peer channel update -o 127.0.0.1:7050 -c fabricchannel -f OrgAMSPanchors.tx
```

12. 安装链码
```
$ peer chaincode install -n cc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd/
```

13. 实例化链码
```
$ peer chaincode instantiate -o 127.0.0.1:7050 -C fabricchannel -n cc -v 1.0 -c '{"Args":["init","a","100","b","200"]}'
```

14. 查询链码
```
$ peer chaincode query -C fabricchannel -n cc -c '{"Args":["query","a"]}'
```

15. 链码执行交易
```
$ peer chaincode invoke -o orderer.cystone.me:7050 -C fabricchannel -n cc -c '{"Args":["invoke","a","b","1"]}'
```

16. 生成私钥
```
$ openssl genrsa -out test.key 1024
```

17. 生成公钥
```
$ openssl rsa -in test.key -pubout -out test_pub.key
```
