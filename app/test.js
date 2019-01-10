/*
 *  Test set of app
 *
 *  Author: chengyang@supermap.com
 *  Date:   2019-01-10
 *  Log:    create
 *
 */

// console.log("======================== Begin test crypto.js =======================")
// 
// var crypto = require('./crypto.js');
// 
// var cert = "464e76d03973c1c36ffcfe08fc1038df34aae361df0e9ab6cfd5b0c196eadeaa7d84c1f76882a36bde4040cc19276d4d19d3d9ce32f15c8b001f10dcc49d3c3df";
// var text = "aaa";
// var signature = "3046022100f04f6568683c2865b276afaa6d0df91bc9168b57efaf370472f8bad4178cf188022100ddb2eec5d5fc78d64a052f02772c34f9017c0f1915bd21293abaad85019bbbb9";
// 
// if(crypto.signatureVerify(cert, text, signature)) {
//     console.log("sucess");
// } else {
//     console.log("failed");
// }
// 
// console.log("======================== End test crypto.js =======================")
// 
// 
console.log("======================== Begin test hdfs.js =======================")
var HDFS = require('./hdfs.js');

function callback(){
    console.log("Do something here");    
}

var hdfs = new HDFS('chengyang', 'localhost', '50070');
//hdfs.put("./orgA.yaml", "/user/chengyang/orgA.yaml", callback);

filename = "ttttt";
hdfs.get("/user/chengyang/orgA.yaml", filename, function(){console.log(filename.length)});

console.log("======================== End test hdfs.js =======================")


console.log("======================== Begin test hbase.js =======================")
// var hbase = require('./hbase.js');
// var hbaseClient = new hbase();
// hbaseClient.put();

// var HBase = require('hbase-client');
//         
// var client = HBase.create({
//     zookeeperHosts: [
//         '127.0.0.1:2182' // only local zookeeper
//     ],
//     zookeeperRoot: '/hbase-0.94.16',
// });
// 
// client.putRow('test', 'rowkey1', {'cf:name': 'name'}, function(err) {
//     console.log(err);
// });
// 
// console.log("======================== End test hbase.js =======================")



