'use strict';
var log4js = require('log4js');
var logger = log4js.getLogger('SampleWebApp');
var express = require('express');
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
const hbase = require('hbase');

var helper = require('./app/helper.js');
var query = require('./app/query.js');
var invoke = require('./app/invoke-transaction.js');
var account = require('./app/account.js');

var port = process.env.PORT || hfc.getConfigSetting('port');
var host = process.env.HOST || hfc.getConfigSetting('host');
var hbaseClient = hbase({ host: '127.0.0.1', port: 8000 });

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// SET CONFIGURATONS ////////////////////////////
///////////////////////////////////////////////////////////////////////////////
app.options('*', cors());
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
    extended: false
}));
app.set('secret', 'thisismysecret');
app.use(expressJWT({
    secret: 'thisismysecret'
}).unless({
    path:['/users']
}));
app.use(bearerToken());
app.use(function(req, res, next) {
	logger.debug(' ------>>>>>> new request for %s',req.originalUrl);
	if (req.originalUrl.indexOf('/users') >= 0) {
		return next();
	}

	var token = req.token;
	jwt.verify(token, app.get('secret'), function(err, decoded) {
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
			req.orgname = decoded.orgName;
			logger.debug(util.format('Decoded from JWT token: username - %s, orgname - %s', decoded.username, decoded.orgName));
			return next();
		}
	});
});

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// START SERVER /////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
var server = http.createServer(app).listen(port, function() {});
logger.info('****************** SERVER STARTED ************************');
logger.info('***************  http://%s:%s  ******************',host,port);
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
// Register and enroll user
app.post('/users', async function(req, res) {
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
	var token = jwt.sign({
		exp: Math.floor(Date.now() / 1000) + parseInt(hfc.getConfigSetting('jwt_expiretime')),
		username: username,
		orgName: orgName
	}, app.get('secret'));
	let response =  await helper.getRegisteredUser(username, orgName, true);
	logger.debug('-- returned from registering the username %s for organization %s',username,orgName);
	if (response && typeof response !== 'string') {

        var fdata = fs.readFileSync('./fabric-client-kv-orga/' + username);
        var jsonObj = JSON.parse(fdata);
        var filename = jsonObj.enrollment.signingIdentity + "-priv";
        
		logger.debug("private key file: " + filename);
        
        fs.writeFileSync('./web/public/msp/' + username, fdata);
        fs.writeFileSync('./web/public/msp/' + filename, fs.readFileSync('./fabric-client-kv-orga/' + filename));

		logger.debug('Successfully registered the username %s for organization %s',username,orgName);
		response.token = token;
        response.filename = filename;
		response.address = account.getAddress('./fabric-client-kv-orga/' + filename);
		logger.debug("address: " + response.address);
		res.json(response);
	} else {
		logger.debug('Failed to register the username %s for organization %s with::%s',username,orgName,response);
		res.json({success: false, message: response});
	}
});

// Query on chaincode on target peers
app.get('/:channelName/:chaincodeName/:fcn', async function(req, res) {
	logger.debug('==================== QUERY BY CHAINCODE ==================');
	var channelName = req.params.channelName;
	var chaincodeName = req.params.chaincodeName;
	var fcn = req.params.fcn;
	let args = req.query.args;
	let peer = req.query.peer;

	logger.debug('channelName : ' + channelName);
	logger.debug('chaincodeName : ' + chaincodeName);
	logger.debug('fcn : ' + fcn);
	logger.debug('args : ' + args);

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
	args = args.replace(/'/g, '"');
	args = JSON.parse(args);
	logger.debug("args: " + args);

    switch (fcn) {
        case "getHistoryByBuyerAddr":
            break;
        case "getHistoryByHash":
            break;
        case "getHistoryBySellerAddr":
            break;
        default:
           res.send("Invalid request");
    }

	let message = await query.queryChaincode(peer, channelName, chaincodeName, args, fcn, req.username, req.orgname);
	res.send(message);
});

// Invoke transaction on chaincode on target peers
app.post('/atlchannel/atlchain/putRecord', async function(req, res) {
	logger.debug('==================== INVOKE ON CHAINCODE ==================');
	var peers = req.body.peers;
	var args = req.body.args;
	var hash = req.body.hash;
	var data = req.body.data;
	logger.debug('peers  : ' + peers);
	logger.debug('args  : ' + args);
	logger.debug('hash  : ' + hash);
	logger.debug('data  : ' + data);

	if (!args) {
		res.json(getErrorMessage('\'args\''));
		return;
	}

	// Put data into HBase
	// statement about create database:
	// 1. create 'atlchain', 'data'
	// 2. put 'atlchain', 'hash1', 'data:data', "json string value"
	hbaseClient
        .table('atlchain')
		.row(args[4])
		.put('data:data', data, (error, success) => {
			console.log("hbaseClient put: ", success);
		  })

    // TODO: 验证参数中的证书和签名，通过后再执行交易
    // if ( verifyCert() && verifySignature() ){
	//      let message = await invoke.invokeChaincode(peers, "atlchannel", "atlchain", "putRecord", args, req.username, req.orgname);
    // }
	
	// invoke
	let message = await invoke.invokeChaincode(peers, "atlchannel", "atlchain", "putRecord", args, req.username, req.orgname);
	res.send(message);
});

// Get data from HBase by hash
app.get('/getDataByHash', async function(req, res) {
	logger.debug('==================== QUERY BY CHAINCODE ==================');
	let hash = req.query.hash;

	logger.debug('hash: ' + hash);

	if (!hash) {
		res.json(getErrorMessage('\'hash\''));
		return;
	}

    hbaseClient
        .table('atlchain')
        .scan({
          startRow: hash,
          endRow: hash,
          maxVersions: 1
        }, (err, rows) => {
            res.send(rows) 
        })
});
