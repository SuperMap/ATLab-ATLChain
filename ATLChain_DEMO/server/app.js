'use strict';
var log4js = require('log4js');
var logger = log4js.getLogger('SampleWebApp');
var express = require('express');
var session = require('express-session');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var http = require('http');
var util = require('util');
var app = express();
var expressJWT = require('express-jwt');
var jwt = require('jsonwebtoken');
var bearerToken = require('express-bearer-token');
var cors = require('cors');
var fs = require('fs');

require('./config.js');
var hfc = require('fabric-client');
var hbase = require('./app/hbase.js');
var hdfs = require('./app/hdfs.js');
var ipfs = require('./app/ipfs.js');

var helper = require('./app/helper.js');
var createChannel = require('./app/create-channel.js');
var join = require('./app/join-channel.js');
var updateAnchorPeers = require('./app/update-anchor-peers.js');
var install = require('./app/install-chaincode.js');
var instantiate = require('./app/instantiate-chaincode.js');
var invoke = require('./app/invoke-transaction.js');
var query = require('./app/query.js');
var account = require('./app/account.js');
var crypto = require('./app/crypto.js');

var port = process.env.PORT || hfc.getConfigSetting('port');
var host = process.env.HOST || hfc.getConfigSetting('host');
var hbaseClient = new hbase('hbase.example.com', '8080');
var hbaseTable = 'atlchain';
var hbaseCF = 'data:data';
var hdfsClient = new hdfs('root', 'hadoop.example.com', '50070');
var hdfsDir = '/user/root';

var ipfsClient = new ipfs("127.0.0.1");

hbaseClient.get(hbaseTable, 'rowkey', hbaseCF, getCallback);
function getCallback(err, val) {
	if (err != null) {
		console.log("err: " + err);
		hbaseClient.createTable(hbaseTable, "data", getCallback);
		hbaseClient.put(hbaseTable, 'rowkey', hbaseCF, 'test data', putCallback);
	}
	console.log(val);
}

function putCallback() {
	console.log("finish");
}

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// SET CONFIGURATONS ////////////////////////////
///////////////////////////////////////////////////////////////////////////////
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: 'true' }));

app.options('*', cors());
app.use(cors());
//support parsing of application/json type post data
app.use(bodyParser.json());
//support parsing of application/x-www-form-urlencoded post data
app.use(bodyParser.urlencoded({
	extended: false
}));
// set secret variable
app.set('secret', 'thisismysecret');
app.use(expressJWT({
	secret: 'thisismysecret'
}).unless({
	path: ['/login', '/users']
}));
app.use(bearerToken());
app.use(function (req, res, next) {
	logger.debug(' ------>>>>>> new request for %s', req.originalUrl);
	if (req.originalUrl.indexOf('/login') >= 0 || req.originalUrl.indexOf('/users') >= 0) {
		return next();
	}

	var token = req.token;
	jwt.verify(token, app.get('secret'), function (err, decoded) {
		if (err) {
			res.send({
				success: false,
				message: 'Failed to authenticate token. Make sure to include the ' +
					'token returned from /users call in the authorization header ' +
					' as a Bearer token'
			});
			return;
		} else {
			// add the decoded user name and org name to the request object
			// for the downstream code to use
			req.username = decoded.username;
			req.orgname = decoded.orgname;
			logger.debug(util.format('Decoded from JWT token: username - %s, orgname - %s', decoded.username, decoded.orgname));
			return next();
		}
	});
});

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// START SERVER /////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
var server = http.createServer(app).listen(port, function () { });
logger.info('****************** SERVER STARTED ************************');
logger.info('***************  http://%s:%s  ******************', host, port);
server.timeout = 240000;

function getErrorMessage(field) {
	var response = {
		success: false,
		message: field + ' field is missing or Invalid in the request'
	};
	return response;
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////// REST ENDPOINTS START HERE ///////////////////////////
///////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////// APIs about user //////////////////////////////////////////
// Login
app.post('/login', async function (req, res) {
	var cert = req.body.cert;

	// login with Certificate
	// var signature = req.body.signature;

	console.log("==========lognin========");

	// Check the cert
	if (!crypto.certCheck(cert)) {
		res.json({ success: false, message: "Invalid Certificate" });
		return;
	}

	// Verify the signature by cert
	// if(!crypto.signatureVerify(cert, cert, signature)) {
	//  	res.json({success: false, message: "Invalid Signature"});
	//     return;
	// }

	var certJsonObj = JSON.parse(cert);
	var username = certJsonObj.name;
	var orgname = certJsonObj.mspid;

	var jsonObj = JSON.parse(cert);
	var filename = jsonObj.enrollment.signingIdentity + "-pub";
	var address = account.getAddress('./fabric-client-kv-orga/' + filename);

	console.log("address:" + address);

	// Generate JWT
	var token = jwt.sign({
		exp: Math.floor(Date.now() / 1000) + parseInt(hfc.getConfigSetting('jwt_expiretime')),
		username: username,
		orgname: orgname
	}, app.get('secret'));

	var response = {
		token: token,
		username: username,
		orgname: orgname,
		address: address,
		message: "login sucessfully"
	}
	res.json({ success: true, message: response });
})

// Register and enroll user
app.post('/users', async function (req, res) {
	logger.debug('==================== REGISTER USERS ==================');
	var username = req.body.username;
	var orgName = req.body.orgName;
	logger.debug('End point : /users');
	logger.debug('User name : ' + username);
	logger.debug('Org name  : ' + orgName);
	if (!username) {
		res.json(getErrorMessage('\'username\''));
		return;
	}
	if (!orgName) {
		res.json(getErrorMessage('\'orgName\''));
		return;
	}

	let response = await helper.getRegisteredUser(username, orgName, true);
	logger.debug('-- returned from registering the username %s for organization %s', username, orgName);
	if (response && typeof response !== 'string') {

		var fdata = fs.readFileSync('./fabric-client-kv-orga/' + username);
		var jsonObj = JSON.parse(fdata);
		var filename = jsonObj.enrollment.signingIdentity + "-priv";
		var pubkeyFile = jsonObj.enrollment.signingIdentity + "-pub";

		logger.debug("private key file: " + filename);

		fs.writeFileSync('../web/tx/msp/' + username, fdata);
		fs.writeFileSync('../web/tx/msp/' + filename, fs.readFileSync('./fabric-client-kv-orga/' + filename));

		logger.debug('Successfully registered the username %s for organization %s', username, orgName);
		response.filename = filename;
		response.address = account.getAddress('./fabric-client-kv-orga/' + pubkeyFile);
		console.log("username:" + username);
		logger.debug("address: " + response.address);
		res.json(response);
	} else {
		logger.debug('Failed to register the username %s for organization %s with::%s', username, orgName, response);
		res.json({ success: false, message: response });
	}
});

////////////////////////////////////////// APIs about operate chaincode //////////////////////////////////////////
// Query on chaincode on target peers
app.post('/channels/:channelName/chaincodes/:chaincodeName/GetRecord', async function (req, res) {
	logger.debug('==================== QUERY BY CHAINCODE ==================');
	var channelName = req.params.channelName;
	var chaincodeName = req.params.chaincodeName;
	let args = req.body.args;
	let username = req.body.username;
	let orgname = req.body.orgname;

	var fcn = "Get";
	let peer = 'peer0.orga.example.com';

	if (!chaincodeName) {
		res.json(getErrorMessage('\'chaincodeName\''));
		return;
	}
	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!fcn) {
		res.json(getErrorMessage('\'fcn\''));
		return;
	}
	if (!args) {
		res.json(getErrorMessage('\'args\''));
		return;
	}

	let message = await query.queryChaincode(peer, channelName, chaincodeName, args, fcn, username, orgname);
	res.send(message);
});

// Trace
app.post('/channels/:channelName/chaincodes/:chaincodeName/TraceRecord', async function (req, res) {
	logger.info('==================== TRACING HISTORY ==================');
	var channelName = req.params.channelName;
	var chaincodeName = req.params.chaincodeName;
	let username = req.body.username;
	let orgname = req.body.orgname;
	let peer = 'peer0.orga.example.com';
	let args = req.body.args;
	let fcn = "getHistoryByKey";

	let message = await query.queryChaincode(peer, channelName, chaincodeName, args, fcn, username, orgname);
	res.send(message);
})

// Put transcation
app.post('/channels/:channelName/chaincodes/:chaincodeName/putTx', async function (req, res) {
	logger.debug('==================== INVOKE ON CHAINCODE ==================');
	var peers = req.body.peers;
	var channel = req.params.channelName;
	var chaincode = req.params.chaincodeName;
	var fcn = req.body.fcn; // Put
	var args = req.body.args;
	var cert = req.body.cert;
	var signature = req.body.signature;
	var hash = req.body.hash;
	var data = req.body.txdata;
	var storageType = req.body.storageType;
	var username = req.body.username;
	var orgname = req.body.orgname;

	var peers = ['peer0.orga.example.com'];
	var fcn = "Put";

	if (!args) {
		res.json(getErrorMessage('\'args\''));
		return;
	}

	var jsonArgs = JSON.parse(args[1]);

	var signature = jsonArgs.signature;
	var storageType = jsonArgs.storageType;
	var hash = jsonArgs.hash;
	var recordID = jsonArgs.recordID;
	console.log("recordID: " + recordID);
	var cert = args[3];

	console.log("++++++++++++++++++++++++");
	console.log(args);
	console.log("++++++++++++++++++++++++");

	// TODO: 验证参数中的证书和签名，通过后再执行交易
	if (!crypto.certCheck(cert) || !crypto.signatureVerify(cert, args, signature)) {
		res.json(getErrorMessage('\'signature\''));
		return;
	}

	switch (storageType) {
		case "onchain":
		case "hbase":
			// Put data into HBase
			// statement about create database:
			// 1. create 'atlchain', 'data'
			// 2. put 'atlchain', 'hash1', 'data:data', "json string value"
			hbaseClient.put(hbaseTable, hash, hbaseCF, data, function (err) {
				if (err != null) {
					console.log("err: " + err);
					hbaseClient.put(hbaseTable, hash, hbaseCF, data, function (err) {
						if (err != null) {
							logger.info(err);
						} else {
							logger.info("Put into hbase finish");
						}
					})
				}
			})
			break;
		case "hdfs":
			await fs.writeFileSync('../web/reg/tmp/' + hash, data);

			// hdfsClient.put("/tmp/" + hash, hdfsDir + hash, function(){
			//     logger.info("Put into HDFS finish");
			// });

			break;
		case "ipfs":
			await fs.writeFileSync('../web/reg/tmp/' + hash, data);

			// hdfsClient.put("/tmp/" + hash, hdfsDir + hash, function(){
			//     logger.info("Put into HDFS finish");
			// });

			break;
		default:
			break;
	}

	// invoke
	console.log(storageType);
	let message = await invoke.invokeChaincode(peers, channel, chaincode, fcn, args, username, orgname);
	res.send(recordID);
});

// Put estate
// Define: RecordID AddRecord(string strRecord, Signature sig, PublicKey key)
app.post('/channels/:channelName/chaincodes/:chaincodeName/AddRecord', async function (req, res) {
	logger.debug('==================== INVOKE ON CHAINCODE ==================');
	var channel = req.params.channelName;     // atlchannel
	var chaincode = req.params.chaincodeName; // atlchainCC
	var args = req.body.args;
	var imgdata = req.body.imgdata;
	var username = req.body.username;
	var orgname = req.body.orgname;

	console.log("+++++++++++++++++++++++");
	console.log(args)
	console.log("+++++++++++++++++++++++");

	var peers = ['peer0.orga.example.com'];
	var fcn = "Put";

	if (!args) {
		res.json(getErrorMessage('\'args\''));
		return;
	}

	var jsonArgs = JSON.parse(args[1]);

	var signature = jsonArgs.signature;
	var storageType = jsonArgs.storageType;
	var hash = jsonArgs.hash;
	var recordID = jsonArgs.recordID;
	var cert = args[3];

	// Put data on chain
	// if(storageType == "onchain") {
	//     jsonArgs.image = imgdata;
	// }

	var args_1 = JSON.stringify(jsonArgs);
	args[1] = args_1;

	// decode based64 image
	// base64 image data decode
	// var img = new Buffer(imgdata, 'base64');
	// console.log("=================================" + img);


	// TODO: 验证参数中的证书和签名，通过后再执行交易
	if (!crypto.certCheck(cert) || !crypto.signatureVerify(cert, args, signature)) {
		res.json(getErrorMessage('\'signature\''));
		return;
	}

	switch (storageType) {
		case "onchain":
		case "hbase":
			// Put data into HBase
			// statement about create database:
			// 1. create 'atlchain', 'data'
			// 2. put 'atlchain', 'hash1', 'data:data', "json string value"
			hbaseClient.put(hbaseTable, hash, hbaseCF, imgdata, function () {
				logger.info("Put into hbase finish");
			})
			break;
		case "hdfs":
			await fs.writeFileSync('../web/tx/tmp/' + hash, imgdata, 'binary');

			// hdfsClient.put("/tmp/" + hash, hdfsDir + hash, function(){
			//     logger.info("Put into HDFS finish");
			// });
			break;
		case "ipfs":
			await fs.writeFileSync('../web/public/tmp/' + hash, imgdata, 'binary');
			await ipfsClient.add("../web/public/tmp/" + hash, (res) => {
				jsonArgs.hash = res;
				console.log("=======>" + res);
				args_1 = JSON.stringify(jsonArgs);
				args[1] = args_1;
			});


			// hdfsClient.put("/tmp/" + hash, hdfsDir + hash, function(){
			//     logger.info("Put into HDFS finish");
			// });
			break;
		default:
			break;
	}

	// invoke
	let message = await invoke.invokeChaincode(peers, channel, chaincode, fcn, args, username, orgname);
	res.send(recordID);
});

// TODO: Get data from remote HDFS, now it is only avaliable for localhost hdfs
app.get('/GetFileFromHDFS', async function (req, res) {
	logger.info('==================== GET HDFS DATA ==================');
	let filename = req.query.filename;
	if (!filename) {
		res.json(getErrorMessage('\'getDataFromHDFS\''));
		return;
	}

	res.json(filename);
	// hdfsClient.get(hdfsDir + filename, "../web/public/tmp/" + filename, function(){
	//     res.json(filename);
	//     logger.info("Got file from HDFS");
	// });
});

// Get data from HBase by hash
app.get('/GetDataFromHBase', async function (req, res) {
	logger.debug('==================== GET HBASE DATA ==================');
	let hash = req.query.hash;
	if (!hash) {
		res.json(getErrorMessage('\'getDataFromHBase\''));
		return;
	}

	hbaseClient.get(hbaseTable, hash, hbaseCF, (err, value) => {
		if (err != null) {
			logger.info(err);
		} else {
			logger.info("Got file from HBase");
			res.json(value);
		}
	})
});

app.get('/GetFileFromIPFS', async function (req, res) {
	logger.info('==================== GET IPFS DATA ==================');
	let filename = req.query.filename;
	if (!filename) {
		res.json(getErrorMessage('\'getDataFromHDFS\''));
		return;
	}

	res.json(filename);
	ipfsClient.get(filename, "../web/public/tmp/" + filename, "");
});


////////////////////////////////////////// APIs about environment building //////////////////////////////////////////
// Create Channel
app.post('/channels', async function (req, res) {
	logger.info('<<<<<<<<<<<<<<<<< C R E A T E  C H A N N E L >>>>>>>>>>>>>>>>>');
	logger.debug('End point : /channels');
	var channelName = req.body.channelName;
	var channelConfigPath = req.body.channelConfigPath;
	logger.debug('Channel name : ' + channelName);
	logger.debug('channelConfigPath : ' + channelConfigPath); //../artifacts/channel/mychannel.tx
	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!channelConfigPath) {
		res.json(getErrorMessage('\'channelConfigPath\''));
		return;
	}

	let message = await createChannel.createChannel(channelName, channelConfigPath, req.username, req.orgname);
	res.send(message);
});
// Join Channel
app.post('/channels/:channelName/peers', async function (req, res) {
	logger.info('<<<<<<<<<<<<<<<<< J O I N  C H A N N E L >>>>>>>>>>>>>>>>>');
	var channelName = req.params.channelName;
	var peers = req.body.peers;
	logger.debug('channelName : ' + channelName);
	logger.debug('peers : ' + peers);
	logger.debug('username :' + req.username);
	logger.debug('orgname:' + req.orgname);

	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!peers || peers.length == 0) {
		res.json(getErrorMessage('\'peers\''));
		return;
	}

	let message = await join.joinChannel(channelName, peers, req.username, req.orgname);
	res.send(message);
});
// Update anchor peers
app.post('/channels/:channelName/anchorpeers', async function (req, res) {
	logger.debug('==================== UPDATE ANCHOR PEERS ==================');
	var channelName = req.params.channelName;
	var configUpdatePath = req.body.configUpdatePath;
	logger.debug('Channel name : ' + channelName);
	logger.debug('configUpdatePath : ' + configUpdatePath);
	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!configUpdatePath) {
		res.json(getErrorMessage('\'configUpdatePath\''));
		return;
	}

	let message = await updateAnchorPeers.updateAnchorPeers(channelName, configUpdatePath, req.username, req.orgname);
	res.send(message);
});
// Install chaincode on target peers
app.post('/chaincodes', async function (req, res) {
	logger.debug('==================== INSTALL CHAINCODE ==================');
	var peers = req.body.peers;
	var chaincodeName = req.body.chaincodeName;
	var chaincodePath = req.body.chaincodePath;
	var chaincodeVersion = req.body.chaincodeVersion;
	var chaincodeType = req.body.chaincodeType;
	logger.debug('peers : ' + peers); // target peers list
	logger.debug('chaincodeName : ' + chaincodeName);
	logger.debug('chaincodePath  : ' + chaincodePath);
	logger.debug('chaincodeVersion  : ' + chaincodeVersion);
	logger.debug('chaincodeType  : ' + chaincodeType);
	if (!peers || peers.length == 0) {
		res.json(getErrorMessage('\'peers\''));
		return;
	}
	if (!chaincodeName) {
		res.json(getErrorMessage('\'chaincodeName\''));
		return;
	}
	if (!chaincodePath) {
		res.json(getErrorMessage('\'chaincodePath\''));
		return;
	}
	if (!chaincodeVersion) {
		res.json(getErrorMessage('\'chaincodeVersion\''));
		return;
	}
	if (!chaincodeType) {
		res.json(getErrorMessage('\'chaincodeType\''));
		return;
	}
	let message = await install.installChaincode(peers, chaincodeName, chaincodePath, chaincodeVersion, chaincodeType, req.username, req.orgname)
	res.send(message);
});
// Instantiate chaincode on target peers
app.post('/channels/:channelName/chaincodes', async function (req, res) {
	logger.debug('==================== INSTANTIATE CHAINCODE ==================');
	var peers = req.body.peers;
	var chaincodeName = req.body.chaincodeName;
	var chaincodeVersion = req.body.chaincodeVersion;
	var channelName = req.params.channelName;
	var chaincodeType = req.body.chaincodeType;
	var fcn = req.body.fcn;
	var args = req.body.args;
	logger.debug('peers  : ' + peers);
	logger.debug('channelName  : ' + channelName);
	logger.debug('chaincodeName : ' + chaincodeName);
	logger.debug('chaincodeVersion  : ' + chaincodeVersion);
	logger.debug('chaincodeType  : ' + chaincodeType);
	logger.debug('fcn  : ' + fcn);
	logger.debug('args  : ' + args);
	if (!chaincodeName) {
		res.json(getErrorMessage('\'chaincodeName\''));
		return;
	}
	if (!chaincodeVersion) {
		res.json(getErrorMessage('\'chaincodeVersion\''));
		return;
	}
	if (!channelName) {
		res.json(getErrorMessage('\'channelName\''));
		return;
	}
	if (!chaincodeType) {
		res.json(getErrorMessage('\'chaincodeType\''));
		return;
	}
	if (!args) {
		res.json(getErrorMessage('\'args\''));
		return;
	}

	let message = await instantiate.instantiateChaincode(peers, channelName, chaincodeName, chaincodeVersion, chaincodeType, fcn, args, req.username, req.orgname);
	res.send(message);
});
//  Query Get Block by BlockNumber
app.get('/channels/:channelName/blocks/:blockId', async function (req, res) {
	logger.debug('==================== GET BLOCK BY NUMBER ==================');
	let blockId = req.params.blockId;
	let peer = req.query.peer;
	logger.debug('channelName : ' + req.params.channelName);
	logger.debug('BlockID : ' + blockId);
	logger.debug('Peer : ' + peer);
	if (!blockId) {
		res.json(getErrorMessage('\'blockId\''));
		return;
	}

	let message = await query.getBlockByNumber(peer, req.params.channelName, blockId, req.username, req.orgname);
	res.send(message);
});
// Query Get Transaction by Transaction ID
app.get('/channels/:channelName/transactions/:trxnId', async function (req, res) {
	logger.debug('================ GET TRANSACTION BY TRANSACTION_ID ======================');
	logger.debug('channelName : ' + req.params.channelName);
	let trxnId = req.params.trxnId;
	let peer = req.query.peer;
	if (!trxnId) {
		res.json(getErrorMessage('\'trxnId\''));
		return;
	}

	let message = await query.getTransactionByID(peer, req.params.channelName, trxnId, req.username, req.orgname);
	res.send(message);
});
// Query Get Block by Hash
app.get('/channels/:channelName/blocks', async function (req, res) {
	logger.debug('================ GET BLOCK BY HASH ======================');
	logger.debug('channelName : ' + req.params.channelName);
	let hash = req.query.hash;
	let peer = req.query.peer;
	if (!hash) {
		res.json(getErrorMessage('\'hash\''));
		return;
	}

	let message = await query.getBlockByHash(peer, req.params.channelName, hash, req.username, req.orgname);
	res.send(message);
});
//Query for Channel Information
app.get('/channels/:channelName', async function (req, res) {
	logger.debug('================ GET CHANNEL INFORMATION ======================');
	logger.debug('channelName : ' + req.params.channelName);
	let peer = req.query.peer;

	let message = await query.getChainInfo(peer, req.params.channelName, req.username, req.orgname);
	res.send(message);
});
//Query for Channel instantiated chaincodes
app.get('/channels/:channelName/chaincodes', async function (req, res) {
	logger.debug('================ GET INSTANTIATED CHAINCODES ======================');
	logger.debug('channelName : ' + req.params.channelName);
	let peer = req.query.peer;

	let message = await query.getInstalledChaincodes(peer, req.params.channelName, 'instantiated', req.username, req.orgname);
	res.send(message);
});
// Query to fetch all Installed/instantiated chaincodes
app.get('/chaincodes', async function (req, res) {
	var peer = req.query.peer;
	var installType = req.query.type;
	logger.debug('================ GET INSTALLED CHAINCODES ======================');

	let message = await query.getInstalledChaincodes(peer, null, 'installed', req.username, req.orgname)
	res.send(message);
});
// Query to fetch channels
app.get('/channels', async function (req, res) {
	logger.debug('================ GET CHANNELS ======================');
	logger.debug('peer: ' + req.query.peer);
	var peer = req.query.peer;
	if (!peer) {
		res.json(getErrorMessage('\'peer\''));
		return;
	}

	let message = await query.getChannels(peer, req.username, req.orgname);
	res.send(message);
});
