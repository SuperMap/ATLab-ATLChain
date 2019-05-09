var express = require("express");
var app = express();

app.use(express.static("../web")).listen(7001);

console.log("http starting at http://localhost:7001")
