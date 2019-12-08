# 快速入门

开始本章内容之前，请确保已完成[准备工作](./prereqs.md)的相关内容。正确修改完成配置文件后，启动部署脚本即可实现网络一键化部署。

## 配置文件说明

配置文件在 `conf` 文件夹中，有两个配置文件需要配置：

- **hosts：** 用于配置各节点的域名及 IP 地址，如果节点的域名为实际存在的，且可以正常访问，则可不配置该文件；
- **conf.conf：** 区块链网络配置文件，该文件配置了区块链网络的组织、通道、链码等具体信息。

### hosts 配置文件

示例配置文件 `conf/hosts` 具体内容如下：

```
127.0.0.1	localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

# server1
<ip_address1>    orderer0.example.com
<ip_address1>    peer0.orga.example.com
<ip_address1>    couchdb.orga.example.com
<ip_address1>    ca.orga.example.com

# server2
<ip_address2>    orderer1.example.com
<ip_address2>    couchdb.orgb.example.com
<ip_address2>    peer0.orgb.example.com
<ip_address2>    ca.orgb.example.com
<ip_address2>    hbase.example.com  # 可选
<ip_address2>    hdfs.example.com   # 可选

# server3
<ip_address3>    orderer2.example.com
<ip_address3>    couchdb.orgc.example.com
<ip_address3>    peer0.orgc.example.com
<ip_address3>    ca.orgc.example.com
```

该配置文件表示，网络部署在三台服务器上，每台服务器上都有一个排序节点，一个记账节点，一个 Couchdb 数据库，一个 CA 节点。分布式数据存储 HDFS 和 HBase 可根据实际情况配置。
根据上述修改hosts文件后，也需要将三个server修改到当前主节点的hosts文件如上，修改命令如下

```shell
$ vim /etc/hosts

<ip_address1>    orderer0.example.com
<ip_address1>    peer0.orga.example.com
<ip_address1>    couchdb.orga.example.com
<ip_address1>    ca.orga.example.com

# server2
<ip_address2>    orderer1.example.com
<ip_address2>    couchdb.orgb.example.com
<ip_address2>    peer0.orgb.example.com
<ip_address2>    ca.orgb.example.com

# server3
<ip_address3>    orderer2.example.com
<ip_address3>    couchdb.orgc.example.com
<ip_address3>    peer0.orgc.example.com
<ip_address3>    ca.orgc.example.com
```


#### 节点域名命名规则

- 排序节点域名均为 `orderer+<index>+<Domain>` 的格式，例如 `orderer0.example.com`，`orderer1.example.com`。
- 记账节点域名均为 `peer+<index>+<Domain>` 的格式，例如 `peer0.orga.example.com`，`peer1.orgb.example.com`。
- 具体配置如下
- 


### conf.conf 配置文件

示例配置文件 `conf/conf.conf` 具体内容如下：

```
Orderer:    #组织名，域名，节点个数，读策略，写策略，默认可用节点
OrgOrderer  example.com  3  "OR('OrgOrderer.member')"  "OR('OrgOrderer.member')"  orderer0.example.com

Peer:       #组织名，域名，节点个数，读策略，写策略，排序节点（多个节点逗号隔开），锚节点（多个节点逗号隔开），CA节点（多个节点逗号隔开）  #每个组织一行，可配置多个组织
OrgA  orga.example.com  1  "OR('OrgA.member')"  "OR('OrgA.member')"  orderer0.example.com,orderer1.example.com,orderer2.example.com  peer0.orga.example.com ca.orga.example.com
OrgB  orgb.example.com  1  "OR('OrgB.member')"  "OR('OrgB.member')"  orderer0.example.com,orderer1.example.com,orderer2.example.com  peer0.orgb.example.com ca.orgb.example.com
OrgC  orgc.example.com  1  "OR('OrgC.member')"  "OR('OrgC.member')"  orderer0.example.com,orderer1.example.com,orderer2.example.com  peer0.orgc.example.com ca.orgc.example.com

SystemChannel:      #通道名，通道中的排序组织名，通道中的联盟组织名
OrdererChannel    OrgOrderer    OrgA,OrgB,OrgC

ApplicationChannel:     #通道名，通道中的联盟组织名
TxChannel    OrgA,OrgB,OrgC

Chaincode:      # 链码文件地址（相对于 `scripts` 目录的地址），建议使用 peer chaincode package 打包的链码包
atlchainCC0_4_1.out
```

该配置文件用于生成系统加密材料（证书和私钥），生成系统配置文件，创建通道，加入通道，安装链码等。例如，用于生成加密材料的配置文件 `crypto-config.yaml` 以及系统配置文件 `configtx.yaml`，脚本会读取配置文件的内容，并自动生成这两个文件并根据生成的文件再生成相应的区块文件或者交易提案文件。创建通道、更新锚节点、安装链码等过程也会读取配置文件中的相关信息进行切换节点等相关操作。

配置文件分为五个部分：

- **Orderer:** 排序服务配置，共六个选项，每个选项以空格隔开，分别代表：组织名（MSPID），域名（Domain），节点个数，读策略，写策略，默认可用节点。（目前只支持一个排序组织。）
- **Peer:** Peer 节点配置，共八个选项，每个选项以空格隔开，分别代表：组织名（MSPID），域名（Domain），节点个数，读策略，写策略，排序节点（多个节点逗号隔开），锚节点（多个节点逗号隔开），CA 节点（多个节点逗号隔开）。每个组织一行，可配置多个组织。
- **SystemChannel:** 系统通道配置，共三个选项，每个选项以空格隔开，分别代表：通道名，通道中的排序组织名，通道中的联盟组织名。
- **ApplicationChannel:** 应用通道配置，共两个选项，每个选项以空格隔开，分别代表：通道名，通道中的联盟组织名。
- **Chaincode:** 链码配置，共一个选项，链码文件地址（相对于 `scripts` 目录的地址），建议使用 peer chaincode package 打包的链码包。

**注意：** `Orderer` 和 `Peer` 中的**节点个数**选项需要和 hosts 中的配置一致，否则无法找到对应节点。因为，排序节点的域名是根据排序节点个数生成的，例如有三个排序节点，则排序节点的域名分别为：`orderer0.example.com`，`orderer1.example.com`，`orderer2.example.com`。Peer 也是如此。**因此当有多个节点时，应确保可以访问到对应节点的域名。**

## 执行脚本

修改完成上述配置文件之后，执行如下命令自动网络：

```shell
$ ./run up
```

停止网络：

```shell
$ ./run down
```

清除当前主机生成的文件：

```shell
$ ./run clean
```

**注意：** 暂不支持删除远程主机的文件，因此要清理远程主机的文件需要手动处理。

## 生成的文件说明

1. **crypto-config.yaml:** 网络所需加密材料配置文件，`cryptogen` 利用该文件生成相关加密材料，生成的文件位于 `crypto-config` 文件夹中。
2. **configtx.yaml:** 网络配置文件，`configtxgen` 利用该文件生成搭建网络所需的各种创世区块以及交易提案，生成的文件位于 `channel-artifacts` 文件夹中。
3. **channel-artifacts:** 
4. **/var/local/hyperledger/fabric/production:** 网络搭建所需的文件默认存放于 `/var/local/hyperledger/fabric/`，该路径下的 `production` 文件夹用于存放区块链网络数据，包括区块数据，CA 生成的证书等等。
