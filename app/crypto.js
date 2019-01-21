/*
 *  Crypto tool set for app
 *  
 *  Author: chengyang@supermap.com
 *  Date:   2019-01-08
 *  Log:    create
 *
 */

var log4js = require('log4js');
var logger = log4js.getLogger('crypto');
logger.setLevel('DEBUG');
var rs = require('jsrsasign');
var rsu = require('jsrsasign-util');

var algName = "SHA256withECDSA";

// TODO: 
// 1.检查证书是否被吊销
// 2.根据根证书，检查证书签名是否正确
// 3.检查该证书的用户是否属于该peer的角色
function certCheck(cert) {
    return true;
}

function doSign(prvKeyPEM, text) {
    logger.debug('doSign - ****** START ******');
    var sig = new rs.KJUR.crypto.Signature({'alg':'SHA256withECDSA'});
    var prvKey = getPrvKeyFromPEM(prvKeyPEM);
    console.log('prvKey:' + prvKey);
    sig.init(prvKeyPEM);
    sig.updateString(text);
    var sigValueHex = sig.sign();
    return sigValueHex;
}

// TODO: 前端 JS 和 NodeJS 的 jsrsasign 签名验证结果不一致
function signatureVerify(cert, text, signature) {
    return true;

    // logger.debug('signatureVerify - ****** START ******');
    // var pubKey = getPubKeyFromCert(cert);
    // console.log("pubKey:" + pubKey);
    // var sig = new rs.KJUR.crypto.Signature({"alg": "SHA256withECDSA", "prov": "cryptojs/jsrsa"});
    // sig.init({xy: pubKey, curve: "secp256r1"});
    // sig.updateString(text);
    // console.log("text:" + text);
    // return sig.verify(signature);
}

function getPrvKeyFromPEM(prvKeyPEM) {
    prvKey = rs.KEYUTIL.getKey(prvKeyPEM);
    return prvKey.prvKeyHex;
}

function getPubKeyFromCert(cert) {
    logger.debug('getPubKeyFromCert - ****** START ******');
    var pubKeyObj = rs.KEYUTIL.getKey(cert);
    return pubKeyObj.pubKeyHex;
}

// TODO: RSA encrypt decrypt functions
function getRSAKey(){
    var keypair = "";
    return keypair;
}

function RSAEncrypt() {
    return true;
}

function RSADecrypt() {
    return true;
}

exports.certCheck = certCheck;
exports.doSign = doSign;
exports.signatureVerify = signatureVerify;
