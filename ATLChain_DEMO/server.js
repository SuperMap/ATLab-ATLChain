var express = require("express");
var app = express();

app.use(express.static("public")).listen(8888);

console.log("http starting at http://localhost:8888")
