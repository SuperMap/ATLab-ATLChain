/*
 *  Test set of app
 *
 *  Author: chengyang@supermap.com
 *  Date:   2019-01-10
 *  Log:    create
 *
 */

// ======================== Test crypto.js ======================= 
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


// ======================== Test storage.js =======================
console.log("======================== Begin test storage.js =======================")

var HDFS = require('./hdfs.js');

var hdfs = new HDFS('chenyang', '148.70.109.243', '50070');
hdfs.put("./orgA.yaml", "/user/chengyang/orgA.yaml");

console.log("======================== End test storage.js =======================")
