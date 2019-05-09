var crypto = require('crypto');
var fs = require("fs");
var base58 = require('base58-native');
var DEBUG = false;

var getAddress = function(publicKeyPath) {
    
    var data = fs.readFileSync(publicKeyPath);
    var arr = data.toString().split("\r\n");
    publicKey = new Buffer(arr[1] + "\r\n" + arr[2], 'base64');
    if (DEBUG) {
        console.log("pubkey: " + publicKey.toString('hex'));
    }
    
    var sha = crypto.createHash('sha256').update(publicKey).digest();
    var pubkeyHash = crypto.createHash('rmd160').update(sha).digest();
     
    var publicKeyWithVer = Buffer.concat([new Buffer([0x00]), pubkeyHash]);
     
    if (DEBUG) {
        console.log("ver+sha256(rmd160(pubkey)): " + publicKeyWithVer.toString('hex'))
    }
    
    
    sha = crypto.createHash('sha256').update(publicKeyWithVer).digest();
    sha = crypto.createHash('sha256').update(sha).digest();
    var checkbits = sha.toString('hex').substring(0,4); 
    if (DEBUG) {
        console.log("checkbits: " + checkbits);
    }
    
    pubkeyHash = Buffer.concat([publicKeyWithVer, new Buffer(checkbits)])
    if (DEBUG) {
        console.log("ver+hash+checkbits: " + pubkeyHash.toString('hex'));
    }
    
    var addr = base58.encode(pubkeyHash);
    if (DEBUG) {
        console.log("BASE58: " + addr);
    }
    return addr;
}

exports.getAddress = getAddress;
