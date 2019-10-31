# 快速入门

开始本章内容之前，请确保已完成[准备工作](./prereqs.md)的相关内容。

## 修改预生成密钥配置

在网络搭建期间需生成预设密钥用于网络搭建，在网络运行期间密钥由 CA 进行管理。

预生成密钥的配置文件为 `conf/orgs.conf` ，其示例内容如下：

``` 
OrgOrderer1  example.com

OrgA        orga.example.com
OrgB        orgb.example.com
OrgC        orgb.example.com
// Do not delete， Keep this line！！！
```

该文件分为两部分内容，第一部分为排序组织的配置，第一列为组织名，第二列为该组织的域名。排序组织和记账组织的配置中间需**间隔一个空行**，记账组织的配置第一列为组织名，第二列为该组织的域名，第三列为该节点可使用的排序节点。在配置文件最后请**保留最后一行内容**，即 `// Do not delete， Keep this line！！！` 不要删除，也不要有多余行。

## 配置文件说明

1. 配置文件分为两部分：序组织部分和节点组织部分；
2. 排序组织默认所有节点都参与raft；
3. 有几个活动节点就写几个，排序节点为orderer0.example.com，orderer0.example.com，Peer 节点为peer0.orga.example.com
4. 端口默认7050，7051，7052，暂不可调整;
5. 应用通道必须和排序通道一一对应，如，conf.conf 9-13行如下：

    ``` 
    SystemChannel:      #通道名，排序组织名，联盟组织名
    OrdererChannel    OrgOrderer    OrgA,OrgB,OrgC

    ApplicationChannel:     #通道名，排序组织名，联盟组织名
    TxChannel    OrgA,OrgB,OrgC
    ```

    在表明应用通道 TxChannel 所使用的排序通道为 OrdererChannel。
6. 未设置链码策略、链码名、版本号。使用 Fabric 默认策略，链码名默认“atlchainCC”，默认版本“1.0”
