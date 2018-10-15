# chaincode 安装运行脚本



1. 设置环境变量，peer的编号
```
export CORE_PEER_LOCALMSPID=OrgAMSP
```

2. 设置环境变量，peer账号
```
export CORE_PEER_MSPCONFIGPATH=/home/stone/Documents/ATL/ATLab-ATLChain/config/crypto-config/peerOrganizations/orga.cystone.me/users/Admin@orga.cystone.me/msp/
```

3. 安装链码
``` 
peer chaincode install -n AtoB -v 0.0 -p ATLChain 
```

4. 实例化链码
``` 
peer chaincode instantiate -o orderer.cystone.me:7050 -C fabricchannel -n AtoB -v 0.0 -c '{"Args":["init"]}'
```

3. 升级链码（先install再upgrade，不需要instantiate）
```
peer chaincode upgrade -o orderer.cystone.me:7050 -C fabricchannel -n AtoB -v 0.1 -c '{"Args":["init"]}'
```

4. 查询
```
peer chaincode query -C fabricchannel -n AtoB -c '{"Args":["query","A"]}'
```

5. 执行链码
```
peer chaincode invoke -o orderer.cystone.me:7050 -C fabricchannel -n AtoB -c '{"Args":["invoke"]}'
```

6. 调试模式时用
```
export CORE_PEER_ADDRESS=127.0.0.1:7051
export CORE_CHAINCODE_ID_NAME=AtoB:0.0
export COER_CHAINCODE_MODE=dev
./transaction -peer.address=127.0.0.1:7052
```

7. 查询peer中已安装和已实例化的链码
```
peer chaincode list --instantiated -C fabricchannel
peer chaincode list --installed
```



