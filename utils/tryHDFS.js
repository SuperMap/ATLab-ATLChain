var WebHDFS = require('webhdfs');
var fs = require('fs');
var hdfs = WebHDFS.createClient({
    user: 'cy',
    host: 'localhost',
    port: '50070'
});

function putFileToHDFS(localFile, remoteFile) {
    
    var localFileStream = fs.createReadStream(localFile);
    var remoteFileStream = hdfs.createWriteStream(remoteFile);
    
    localFileStream.pipe(remoteFileStream);
    
    remoteFileStream.on('error', function onError (err) {
        console.log(err);
    });
    
    remoteFileStream.on('finish', function onFinish() {
        console.log("finish");
    });
}

function getFileFromHDFS(remoteFile, localFile) {
    var remoteFileStream = hdfs.createReadStream(remoteFile);
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

// putFileToHDFS('./Rbeijing.zip', '/user/cy/Rbeijing2.zip');
getFileFromHDFS('/user/cy/Rbeijing.zip', './Rbeijing_local.zip');
