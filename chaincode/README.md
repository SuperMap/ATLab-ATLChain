# chaincode 安装运行脚本

1. 设置环境变量，peer的编号
```
$ export CORE_PEER_LOCALMSPID=OrgA
```

2. 设置环境变量，peer账号
```
$ export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/orga.atlchain.com/users/Admin@orga.atlchain.com/msp/
```

3. 安装链码
``` 
$ peer chaincode install -n atlchain -v 1.0 -p ATLab-ATLChain
```

4. 实例化链码
``` 
$ peer chaincode instantiate -o 127.0.0.1:7050 -C atlchannel -n atlchain -v 1.0 -c '{"Args":["init"]}'
```

5. 升级链码（先install再upgrade，不需要instantiate）
```
$ peer chaincode install -n atlchain -v 0.2 -p ATLab-ATLChain
$ peer chaincode upgrade -o 127.0.0.1:7050 -C atlchannel -n atlchain -v 0.2 -c '{"Args":["init"]}'
```

6. 写入一条记录数据，key => addB
```
$ peer chaincode invoke -o 127.0.0.1:7050 -C atlchannel -n atlchain -c '{"Args":["putRecord", "addB", "addA", "100", "20181107", "hashcode"]}'
```

7. 根据买方地址查询交易记录
```
$ peer chaincode query -C atlchannel -n atlchain -c '{"Args":["getRecordByBuyerAddr","addB"]}'
```

8. 根据买方地址查询历史交易记录
```
$ peer chaincode query -C atlchannel -n atlchain -c '{"Args":["getHistoryByBuyerAddr","addB"]}'
// 结果示例 {"TxId":"3a198be789b60fb964141e4d4e24b47298f874b0378900ae5e33c98f401afbb9", "Value":{"Buyer":"addB","Seller":"addC","Price":100,"Time":"20181108","Hash":"hashcode2"}, "Timestamp":"2018-11-07 06:58:56.420657457 +0000 UTC", "IsDelete":"false"}
```

9. 根据hash查询交易记录 
$ peer chaincode query -C atlchannel -n atlchain -c '{"Args":["getHistoryByHash","hashcode"]}'

10. 根据hash和买方地址查询交易记录
peer chaincode query -C atlchannel -n atlchain -c '{"Args":["getHistoryByHashAndBuyerAddr","hashcode","addB"]}'

11. 调试模式时用
```
$ export CORE_PEER_ADDRESS=127.0.0.1:7051
$ export CORE_CHAINCODE_ID_NAME=atlchain:0.1
$ 改变core.yaml的配置文件将net模式改为dev模式
$ ./transaction -peer.address=127.0.0.1:7052
```

10. 查询peer中已安装和已实例化的链码
```
$ peer chaincode list --instantiated -C atlchannel
$ peer chaincode list --installed
```
