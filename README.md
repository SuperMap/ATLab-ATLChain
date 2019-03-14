## ATLChain

This is an experimental system  for "BLOCKCHAIN + GIS"

**0. Project struct**

```
.
├── ATLChain_CC         # ChainCode for ATLChain
├── ATLChain_DEMO       # ATLChain DEMO system
│   ├── server              # ATLChain server made by Fabric NodeJK SDK
│   └── web                 # ATLChain DEMO website
├── ATLChain_NETWORK    # ATLChain Fabric network configuration files and docker-compose configuration files
└── atlchain.sh         # ATLChain depoly script
```

**1. Prerequisites**

    Ubuntu >= 18.04
    Docker >= 18.x
    Docker-compose >= 1.17.x

    NOTE:
    memory >= 8GB

**2. Getting Started**

    ```
    # install tools
    sudo apt install docker.io docker-compose    

    # start the service
    ./atlchain.sh up
    ```

    then, visit http://127.0.0.1:10001

    ```
    # stop the service
    ./atlchain.sh down
    ```


**3. TroubleShooting**

1. ```Error: got unexpected status: SERVICE_UNAVAILABLE -- backing Kafka cluster has not completed booting; try again later``` because kafka is not booting completely.
    try to start the service again:
    ```
    ./atlchain.sh down

    ./atlchain.sh up
    ```
2. No response when query hbase data.
   Maybe therer is somethings wrong with hbase container, try to restart hbase container by :
   ```
   docker restart hbase.atlchain.com
   ```

TODO: We will do it better.
