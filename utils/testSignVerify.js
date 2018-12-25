'user strict'

var hfc = require('fabric-client');
var CryptoSuite_ECDSA_AES = require('fabric-client/lib/impl/CryptoSuite_ECDSA_AES');
var CryptoKeyStore = require('fabric-client/lib/impl/CryptoKeyStore');

var cs = new CryptoSuite_ECDSA_AES(256, "SHA2");
//console.log(cs);
var cstore = CryptoKeyStore.CryptoKeyStore;
cs.setCryptoKeyStore(cstore);
cs.generateKey();