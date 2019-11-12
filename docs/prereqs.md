# 准备工作

在你准备试用本系统之前，请确认已完成本章所描述的环境配置。请使用 root 用户执行安装过程。

**注意：** 需要参与网络搭建的主机，都需要安装以下这些软件。

## 安装 Docker 和 Docker Compose

### Docker 和 Docker Compose 要求 17.06.2-ce 及以上版本

使用一下命令安装 Docker 和 Docker Compose ：
```
$ apt install docker.io docker-compose
```

## 配置远程免密登录

如果你需要在多台主机上搭建 Fabric 网络，请确保运行安装脚本的主机和其他主机可以正常通信且能免密登录，**提醒一下,如果当前主机也需要搭建节点，也必须配置 root 用户的免密登录**。测试免密登录的命令如下：

```shell
$ ssh root@<host IP>
```

如果不能登录远程主机，请按以下方式进行配置。

1. 查看当前用户是否已生成密钥对：

    ```shell
    $ ls ~/.ssh/id_rsa.pub
    ```

2. 如果该文件不存在，则执行如下命令生成新的密钥对：

    ```shell
    $ ssh-keygen  -t rsa
    ```

3. 然后将公钥复制到需要登录的远程主机：

    ```shell
    $ ssh-copy-id -i ~/.ssh/id_rsa.pub root@<host IP>
    ```

4. 重复步骤 1 重新测试是否能够免密登录远程主机。

## 安装 GO

### Go 要求 1.11.x 及以上版本

1. GO 二进制包[下载页面](https://golang.org/dl/)，下载相应的包，如 Ubuntu 18.04 对应包为 `go1.13.4.linux-amd64.tar.gz` 。

2. 解压压缩包：

    ```shell
    $ tar xzvf go1.13.4.linux-amd64.tar.gz
    ```

3. 配置 GO 目录，选定一个目录为 GO Home 目录，并在该目录创建三个文件夹 `src、pkg、bin`，例如，将 <user_home>/GO 目录设为 GO Home 目录：
  
    ```shell
    $ mkdir ~/GO
    $ cd ~/GO
    $ mkdir src
    $ mkdir pkg
    $ mkdir bin
    ```

4. 设置环境变量，在 `/etc/profile` 文件最后添加如下内容：

    ```
    export GO_HOME=<user_home>/GO
    export PATH=$PATH:$GO_HOME/bin:<path_to_go_binary>/bin
    ```

    执行如下命令使配置生效：
    
    ```shell
    $ source /etc/profile
    ```

5. 验证 go 是否可用：
    
    ```shell
    $ go version
    ```

