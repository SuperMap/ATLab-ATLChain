/*
 *  Storage tools set for app, include HBase and hdfs
 *  
 *  Author: chengyang@supermap.com
 *  Date:   2019-01-09
 *  Log:    create
 *
 */

var webhdfs = require('webhdfs');
var fs = require('fs');

// TODO hdfs operate functions
class HDFS {
    constructor(user, host, port) {
        this.client = webhdfs.createClient({
            user: user,
            host: host,
            port: port
        });
        console.log("client: ", this.client);
    }
    
    put(localFile, remoteFile){
        var localFileStream = fs.createReadStream(localFile);
        var remoteFileStream = this.client.createWriteStream(remoteFile);
    
        localFileStream.pipe(remoteFileStream);
    
        remoteFileStream.on('error', function onError (err) {
            console.log(err);
        });
    
        remoteFileStream.on('finish', function onFinish() {
            console.log("finish");
        });
    }
    
    get(remoteFile, localFile){
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
            console.log('finish');
        });
    }
}

module.exports = HDFS;
