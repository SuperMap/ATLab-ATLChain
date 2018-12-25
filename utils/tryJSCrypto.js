'use strict';
var crypto = require('crypto');

var privKey = `-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQDFWnl8fChyKI/Tgo1ILB+IlGr8ZECKnnO8XRDwttBbf5EmG0qV
8gs0aGkh649rb75I+tMu2JSNuVj61CncL/7Ct2kAZ6CZZo1vYgtzhlFnxd4V7Ra+
aIwLZaXT/h3eE+/cFsL4VAJI5wXh4Mq4Vtu7uEjeogAOgXACaIqiFyrk3wIDAQAB
AoGBAKdrunYlqfY2fNUVAqAAdnvaVOxqa+psw4g/d3iNzjJhBRTLwDl2TZUXImEZ
QeEFueqVhoROTa/xVg/r3tshiD/QC71EfmPVBjBQJJIvJUbjtZJ/O+L2WxqzSvqe
wzYaTm6Te3kZeG/cULNMIL+xU7XsUmslbGPAurYmHA1jNKFpAkEA48aUogSv8VFn
R2QuYmilz20LkCzffK2aq2+9iSz1ZjCvo+iuFt71Y3+etWomzcZCuJ5sn0w7lcSx
nqyzCFDspQJBAN3O2VdQF3gua0Q5VHmK9AvsoXLmCfRa1RiKuFOtrtC609RfX4DC
FxDxH09UVu/8Hmdau8t6OFExcBriIYJQwDMCQQCZLjFDDHfuiFo2js8K62mnJ6SB
H0xlIrND2+/RUuTuBov4ZUC+rM7GTUtEodDazhyM4C4Yq0HfJNp25Zm5XALpAkBG
atLpO04YI3R+dkzxQUH1PyyKU6m5X9TjM7cNKcikD4wMkjK5p+S2xjYQc1AeZEYq
vc187dJPRIi4oC3PN1+tAkBuW51/5vBj+zmd73mVcTt28OmSKOX6kU29F0lvEh8I
oHiLOo285vG5ZtmXiY58tAiPVQXa7eU8hPQHTHWa9qp6
-----END RSA PRIVATE KEY-----
`;

var pubKey = `-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDFWnl8fChyKI/Tgo1ILB+IlGr8
ZECKnnO8XRDwttBbf5EmG0qV8gs0aGkh649rb75I+tMu2JSNuVj61CncL/7Ct2kA
Z6CZZo1vYgtzhlFnxd4V7Ra+aIwLZaXT/h3eE+/cFsL4VAJI5wXh4Mq4Vtu7uEje
ogAOgXACaIqiFyrk3wIDAQAB
-----END PUBLIC KEY-----
`;

// 加密
function encrypt(data, pubKey){
    return crypto.publicEncrypt(pubKey, Buffer.from(data));
}
// 解密
function decrypt(encrypted, privKey){
    return crypto.privateDecrypt(privKey, encrypted);
}

// 签名
function signer(algorithm,key,data){
    var sign = crypto.createSign(algorithm);
    sign.update(data);
    sig = sign.sign(key, 'hex');
    return sig;
}

// 验签
function verify(algorithm,pubkey,sig,data){
    var verify = crypto.createVerify(algorithm);
    verify.update(data);
    return verify.verify(pubkey, sig, 'hex')
}

// 加密
// let en = encrypt("你好", pubKey);
// console.log(en);    // 661728d44eacc82388b6de09e06f78dc

// 解密
// let de = decrypt(en, privKey);
// console.log(de.toString());  // hello world

var algorithm = 'SHA256';
var data = "abcdef";   //传输的数据

// 签名
var sig = signer(algorithm, privKey, data);

// 验签
console.log(verify(algorithm, pubKey, sig, data));         //验证数据，通过公钥、数字签名 =》是原始数据
console.log(verify(algorithm, pubKey, sig, data + "2"));    //验证数据，通过公钥、数字签名  =》不是原始数据