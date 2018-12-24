var fs = require('fs');
var readline = require('readline');
var crypto = require('crypto');
var base58 = require('base58-native');
var assert = require('assert');
const hbase = require('hbase');

// HBase地址
var hostIP = 127.0.0.1;

// 存入HBase的json文件地址
var dataPath = "./RbeijingL-sampleJson.json";

// Instantiate a new client
client = hbase({ host: hostIP, port: 8000 })


// put 'test', 'row1', 'Feature', 328882, 'geometry:Line_p1x', 117.4695833333333, 'attributes:a0', ''
// create 'test', 'Feature', 'geometry', 'attributes'


function putData (){
    var fRead = fs.createReadStream(dataPath);
    
    // 按行读文件
    var objReadline = readline.createInterface({
        input:fRead
    });
    var lineNum = 0;
    objReadline.on('line',function (line) {
        // 计算hash
        var sha = crypto.createHash('sha256').update(line).digest('hex');
        sha = crypto.createHash('rmd160').update(sha).digest('hex');
        console.log("line" + lineNum.toString() + ": " + sha);
        var row = new hbase.Row(client, 'test', sha);
    
        // 解析Json
        var jsonObj = JSON.parse(line);
    
        // put多组数据的集合
        var cells = 
            [
                { column: 'Feature:F0', $: jsonObj.Feature.toString()}
            ];
        for (var i=0;i<jsonObj.geometry.Line[0].length;i++) {
            cells.push({ column: 'geometry:Line_p' + i.toString() + 'x', $: jsonObj.geometry.Line[0][i][0].toString()});
            cells.push({ column: 'geometry:Line_p' + i.toString() + 'y', $: jsonObj.geometry.Line[0][i][1].toString()});
        }
    
        // 处理attribute中的一些空值，0值等特殊值
        for (var i=0;i<jsonObj.attributes.length;i++) {
            var attr = jsonObj.attributes[i];
            if (attr === ''){
                cells.push({ column: 'attributes:a' + i.toString(), $: attr});
            } else if (attr === null){
                cells.push({ column: 'attributes:a' + i.toString(), $: "null"});
            } else {
                cells.push({ column: 'attributes:a' + i.toString(), $: attr.toString()});
            }
        }
            
        // 写入HBase
        row.put(cells, (error, sucess) => {
                console.log("error:" + error);
                // assert.strictEqual(true, sucess);
            }
        )
    
        lineNum ++;
    });
}

function getData(hash) {

    client
        .table('test')
        .scan({
          startRow: '021126a76bc471b41d0cd79f77095266b4f685de',
          endRow: '021126a76bc471b41d0cd79f77095266b4f685de',
          maxVersions: 1
        }, (err, rows) =>
          console.info(rows)
        )

    // const scanner = new hbase.Scanner(client, {table: 'test'})
    // console.info(scanner)
    // const rows = []
    // scanner.on( 'readable', function(chunk) {
    //     while(chunk = scanner.read())
    //         rows.push(chunk)
    //         console.info(chunk)
    // })
    // scanner.on( 'end', function(rows) {
    //     console.info(rows)
    //     }
    // )
    // var row = new hbase.Row(client, 'test', hash);
    // row.get('Feature', (error, value) => {
    //     console.info(value);
    // })
}

// putData();
// getData('d4c483c100451f3c633b3606732c2ce53f1d5d82');
