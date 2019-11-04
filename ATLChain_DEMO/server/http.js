var express = require("express");
var app = express();

app.use(express.static("../web")).listen(4444);

console.log("http starting at http://localhost:4444")
