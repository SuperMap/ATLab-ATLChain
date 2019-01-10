/*
 *  HBase tools set for app
 *  
 *  Author: chengyang@supermap.com
 *  Date:   2019-01-10
 *  Log:    create
 *
 */

var hbaseClient = require('hbase-client');

class HBase {
    constructor() {
        this.client = hbaseClient.create({
            zookeeperHosts: [
                '127.0.0.1:2182'
            ]
        });
    }

    put() {
        this.client.putRow('test', 'rowkey1', {'cf:name': 'foo name'}, function (err){
            console.log("error: ", err);
        });
    }
}

module.exports = HBase;
