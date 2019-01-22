/*
 *  HBase tools set for app
 *  
 *  Author: chengyang@supermap.com
 *  Date:   2019-01-10
 *  Log:    create
 *
 */

var hbaseClient = require('hbase');

class HBase {
    constructor(host, port) {
        this.client = hbaseClient({
            host: host, 
            port: port 
        })
    }

    createTable(tableName, columnFamilyName) {
        this.client
            .table(tableName)
            .create(columnFamilyName, function(error, success) {
            console.info('Table created: ' + (success ? 'yes' : 'no'))
        });
    }

    deleteTable(tableName) {
        this.client
            .table(tableName)
            .delete((error, success) => {
                assert.ok(success)
            });
    }

    get(tableName, rowName, columnFamilyName, callback) {
        this.client
            .table(tableName)
            .row(rowName)
            .get(columnFamilyName, (error, value) => {
                callback(error, value);
            });
    }

    put(tableName, rowName, listColumnFamilyName, listValue, callback) {
        this.client
            .table(tableName)
            .row(rowName)
            .put(listColumnFamilyName, listValue, callback);
    }
}

module.exports = HBase;
