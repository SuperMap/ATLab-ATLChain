'use strict'
var log4js = require('log4js')
var logger = log4js.getLogger('ATLChainApp')
var express = require('express')
var http = require('http')
var util = require('util')
var app = express()

var port = process.env.PORT
var host = 'localhost'

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////// START SERVER /////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
var server = http.createServer(app).listen(port, function() {})
logger.info('****************** SERVER STARTED ************************')
logger.info('***************  http://%s:%s  ******************',host,port)
server.timeout = 240000

function getErrorMessage(field) {
	var response = {
		success: false,
		message: field + ' field is missing or Invalid in the request'
	}
	return response
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////// REST ENDPOINTS START HERE ///////////////////////////
///////////////////////////////////////////////////////////////////////////////

app.get('/users', async function(req, res) {
    logger.debug('Get users')
    res.json({success: false, message: 'message'});
})
