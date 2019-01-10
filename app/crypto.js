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

// TODO: certCheck(cert, username, orgname)
function certCheck(cert, username, orgName) {
    return true;
}

function signatureVerify(cert, text, signature) {
    logger.debug('signatureVerify - ****** START ******');
    var pubKey = getPubKeyFromCert(cert);
    console.log("pubKey: ", pubKey);
    var sig = new rs.KJUR.crypto.Signature({"alg": algName, "prov": "cryptojs/jsrsa"});
    sig.init({xy: pubKey, curve: "secp256r1"});
    sig.updateString(text);
    return sig.verify(signature);
}

function getPubKeyFromCert(cert) {
    logger.debug('getPubKeyFromCert - ****** START ******');
    var jsonCert = JSON.parse(cert);
    var pubKeyObj = rs.KEYUTIL.getKey(jsonCert.enrollment.identity.certificate);
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

// exports.certCheck = certCheck;
exports.signatureVerify = signatureVerify;
