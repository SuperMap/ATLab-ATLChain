/*
 *  HDFS tools set for app
 *  
 *  Author: chengyang@supermap.com
 *  Date:   2019-01-09
 *  Log:    create
 *
 */

var webhdfs = require('webhdfs');
var fs = require('fs');

// TODO hdfs remote operate, now the function just avaliable in localhost. 
class HDFS {
    constructor(user, host, port) {
        this.client = webhdfs.createClient({
            user: user,
            host: host,
            port: port
        });
    }
    
    put(localFile, remoteFile, callback){
        console.log("====put====")
        var localFileStream = fs.createReadStream(localFile);
        var remoteFileStream = this.client.createWriteStream(remoteFile);
    
        localFileStream.pipe(remoteFileStream);
    
        remoteFileStream.on('error', function onError (err) {
            console.log(err);
        });
    
        remoteFileStream.on('finish', function onFinish() {
            callback();
            console.log("finish");
        });
    }
    
    get(remoteFile, localFile, callback){
        var remoteFileStream = this.client.createReadStream(remoteFile);
        var localFileStream = fs.createWriteStream(localFile);
    
        remoteFileStream.on('error', function onError(err) {
            console.log(err);
        });
    
        remoteFileStream.on('data', function onChunk(chunk) {
            localFileStream.write(chunk);
            console.log('writing to local file');
        });
    
        remoteFileStream.on('finish', function onFinish() {
            callback();
            console.log("finish");
        });
    }
}

module.exports = HDFS;
