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
// var prvKeyPEM = "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgddF+fNURw9xuytQ0\nSB9sssle1+Wz37sDwwoCPtwSjIuhRANCAASu83t5e+/JF4W1PXXvYSWGusTn+oJR\nT5zNzEqMxAIK8sGiaZeUd4LU2WnkW3Nm9PHlXENXyVZxSNBNOObpUUpN\n-----END PRIVATE KEY-----";
// var cert = "-----BEGIN CERTIFICATE-----\nMIICXDCCAgKgAwIBAgIUJbmJPWgMfwhga0JCaifHyHsAhoMwCgYIKoZIzj0EAwIw\ndTELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcTDVNh\nbiBGcmFuY2lzY28xGjAYBgNVBAoTEW9yZ2EuYXRsY2hhaW4uY29tMR0wGwYDVQQD\nExRjYS5vcmdhLmF0bGNoYWluLmNvbTAeFw0xODExMjkwMjMwMDBaFw0xOTExMjkw\nMjM1MDBaMB8xDzANBgNVBAsTBmNsaWVudDEMMAoGA1UEAxMDSmltMFkwEwYHKoZI\nzj0CAQYIKoZIzj0DAQcDQgAErvN7eXvvyReFtT1172ElhrrE5/qCUU+czcxKjMQC\nCvLBommXlHeC1Nlp5FtzZvTx5VxDV8lWcUjQTTjm6VFKTaOBxTCBwjAOBgNVHQ8B\nAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU7xDaa5+txo2Z3l0tJnEs\nT2ME5+4wKwYDVR0jBCQwIoAgvA1FMa9xMa1quD3Puakv47jkPAOVf1An01r0WdQo\nTmowVgYIKgMEBQYHCAEESnsiYXR0cnMiOnsiaGYuQWZmaWxpYXRpb24iOiIiLCJo\nZi5FbnJvbGxtZW50SUQiOiJKaW0iLCJoZi5UeXBlIjoiY2xpZW50In19MAoGCCqG\nSM49BAMCA0gAMEUCIQC4VPFMNOOARPIuMft4bOtPUmJvhvukEocN5SAzDFc2JwIg\nEnhmK1UFWgxyk36XL9WqGf5zhCw5qbsG+CWT8p2t+Jk=\n-----END CERTIFICATE-----\n";
// var text = "-----BEGIN CERTIFICATE-----\nMIICXDCCAgKgAwIBAgIUJbmJPWgMfwhga0JCaifHyHsAhoMwCgYIKoZIzj0EAwIw\ndTELMAkGA1UEBhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcTDVNh\nbiBGcmFuY2lzY28xGjAYBgNVBAoTEW9yZ2EuYXRsY2hhaW4uY29tMR0wGwYDVQQD\nExRjYS5vcmdhLmF0bGNoYWluLmNvbTAeFw0xODExMjkwMjMwMDBaFw0xOTExMjkw\nMjM1MDBaMB8xDzANBgNVBAsTBmNsaWVudDEMMAoGA1UEAxMDSmltMFkwEwYHKoZI\nzj0CAQYIKoZIzj0DAQcDQgAErvN7eXvvyReFtT1172ElhrrE5/qCUU+czcxKjMQC\nCvLBommXlHeC1Nlp5FtzZvTx5VxDV8lWcUjQTTjm6VFKTaOBxTCBwjAOBgNVHQ8B\nAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQU7xDaa5+txo2Z3l0tJnEs\nT2ME5+4wKwYDVR0jBCQwIoAgvA1FMa9xMa1quD3Puakv47jkPAOVf1An01r0WdQo\nTmowVgYIKgMEBQYHCAEESnsiYXR0cnMiOnsiaGYuQWZmaWxpYXRpb24iOiIiLCJo\nZi5FbnJvbGxtZW50SUQiOiJKaW0iLCJoZi5UeXBlIjoiY2xpZW50In19MAoGCCqG\nSM49BAMCA0gAMEUCIQC4VPFMNOOARPIuMft4bOtPUmJvhvukEocN5SAzDFc2JwIg\nEnhmK1UFWgxyk36XL9WqGf5zhCw5qbsG+CWT8p2t+Jk=\n-----END CERTIFICATE-----\n";
// var signature = "3045022100d4e473822634da78affc8567a57ce5cd6dead90997e05e9a4ebe1582d034b72b02206cb7cda0aa7573b3c417ef9ae203ac6d4760a70fe06593f8dc34eb2dd72bbfa0";
// var pubKey = "04aef37b797befc91785b53d75ef612586bac4e7fa82514f9ccdcc4a8cc4020af2c1a26997947782d4d969e45b7366f4f1e55c4357c9567148d04d38e6e9514a4d";
// var prvKey = "75d17e7cd511c3dc6ecad434481f6cb2c95ed7e5b3dfbb03c30a023edc128c8b";
// var curve = "secp256r1";
// var alg = "SHA256withECDSA";
// 
// var si = crypto.doSign(prvKeyPEM, 'aaa');
// console.log("signature: " + si);
// 
// 
// if(crypto.signatureVerify(cert, "aaa", signature)) {
//     console.log("sucess");
// } else {
//     console.log("failed");
// }
// 
// console.log("======================== End test crypto.js =======================")


console.log("======================== Begin test hdfs.js =======================")
var HDFS = require('./hdfs.js');

function callback(){
    console.log("Do something here");    
}

var hdfs = new HDFS('root', '127.0.0.1', '50070');
hdfs.put("./orgA.yaml", "/user/root/orgA.yaml", callback);

// filename = "ttttt";
// hdfs.get("/test/orgA.yaml", filename, function(){console.log(filename.length)});

console.log("======================== End test hdfs.js =======================")
 
 
// console.log("======================== Begin test hbase.js =======================")
// var hbase = require('./hbase.js');
// var hbaseClient = new hbase('148.70.109.243', '8080');
// console.log(hbaseClient);
// hbaseClient.put('test', 'rowkey2', 'cf:name', 'myname', putCallback);
// hbaseClient.get('test', 'rowkey2', 'cf:name', getCallback);
// 
// function getCallback(err, val){
//     console.log("err: " + err);
//     console.log(val);
// }
// 
// function putCallback(){
//     console.log("finish");
// }
// 
// console.log("======================== End test hbase.js =======================")


// console.log("======================== Start test write file =======================")
// var fs = require('fs');
// fs.writeFileSync('/tmp/fstest', "fstest");
// console.log("======================== End test write file =======================")

