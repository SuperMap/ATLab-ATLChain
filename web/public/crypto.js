/*
 *  Using crypto lib jsrsasign-all-min.js(http://kjur.github.io/jsrsasign/)
 *
 *  Author: cystone@aliyun.com
 *  Date:   2019-01-08
 *  Log:    create
 */

function getPubKeyFromCert(pubKeyCert) {
    pubKeyObj = KEYUTIL.getKey(pubKeyCert);
    return pubKeyObj.pubKeyHex;
}

function getPrvKeyFromPEM(prvKeyPEM) {
    prvKeyObj = KEYUTIL.getKey(prvKeyPEM);
    return prvKeyObj.prvKeyHex;
}

function ECSign(prvKey, text) {
    var sig = new KJUR.crypto.Signature({"alg": "SHA256withECDSA"});
    sig.init({d: prvKey, curve: "secp256r1"});
    sig.updateString(text);
    return sig.sign();
}

function ECVerify(pubKey, cipher, signature) {
    var sig = new KJUR.crypto.Signature({"alg": "SHA256withECDSA", "prov": "cryptojs/jsrsa"});
    sig.init({xy: pubKey, curve: "secp256r1"});
    sig.updateString(cipher);
    return sig.verify(signature);
}

// genECKeyObj returns a object obtains private key and public key
// prvKey = keypair.ecprvhex;  
// pubKey = keypair.ecpubhex;
function genECKeyObj() {
    var ec = new KJUR.crypto.ECDSA({"curve": "secp256r1"});
    var keypair = ec.generateKeyPairHex();

    return keypair; 
}

// genRSAKeyObj returns a object obtains private key and public key
// prvKey = keypair.prvKeyObj;  
// pubKey = keypair.pubKeyObj;
function genRSAKeyObj() {
    var rsaKeypair = KEYUTIL.generateKeypair("RSA", 1024);
    return rsaKeypair; 
}

function RSAEncrypt(text, encryptKey) {
    var cipher = KJUR.crypto.Cipher.encrypt(text, encryptKey);
    return cipher;
}

function RSADecrypt(cipher, decryptKey) {
    var text = KJUR.crypto.Cipher.decrypt(cipher, decryptKey);
    return text;
}
