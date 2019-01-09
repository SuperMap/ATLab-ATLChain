// enroll
//

// var RESTURL = "http://148.70.109.243:4000";
// var FileURL = "http://148.70.109.243:8080";
var RESTURL = "http://127.0.0.1:4000";
var FileURL = "http://127.0.0.1:8080";

$(document).ready(function(){
    // 设置预设值
    $("#username_input").val(getCookie("username"));
    $("#orgname_input").val(getCookie("orgname"));
    $("#BuyerAddr_tx_input").val(getCookie("address"));
    $("#useraddress_input").val(getCookie("address"));
    $("#BuyerAddr_query_addr_input").val(getCookie("address"));
    $("#BuyerAddr_query_hash_addr_input").val(getCookie("address"));

    $("#enroll_btn").click(function(){
        $.ajax({
            type:'post',
            url: RESTURL + '/users',
            data:{
                username:$("#username_input").val(),
                orgName:$("#orgName_input").val()
            },
            success:function(data){
                

                var username = $("#username_input").val();
                $("#accountAddress_input").val(data.address);
                alert($("#username_input").val() + "登记成功\n请保存好下载的证书和密钥文件\n请牢记账户地址:" + data.address);

                // 下载多个文件
                let triggerDelay = 100;
                let removeDelay = 1000;
                //存放多个下载的url，
                let url_arr=[FileURL + "/msp/" + username,  FileURL + "/msp/" + data.filename];
                
                url_arr.forEach(function(item,index){
                    _createIFrame(item, index * triggerDelay, removeDelay);
                })

                $("#indexJump_p").show(); 
                
            },
            error:function(err){
                console.log(err)
            }
        });
    });


    $("#ECert_input").change(function(){
        var objFiles = document.getElementById("ECert_input");
        var fileName = objFiles.files[0].name;
        var isFileValide = true;    // 交互click和ajax之间的信息
        
        // 读取文件内容
        var reader = new FileReader();//新建一个FileReader
        reader.readAsText(objFiles.files[0], "UTF-8");//读取文件 
        reader.onload = function(evt){ //读取完文件之后会回来这里
            var fileString = evt.target.result; // 读取文件内容
            try {
                var jsonFile = JSON.parse(fileString);
            } catch(err){
                alert("请选择正确的证书文件");
                return;
            }
            $("#ECert_text").val(fileString);
        }
    });
    
    $("#pkey_input").change(function(){
        var objFiles = document.getElementById("pkey_input");
        var fileName = objFiles.files[0].name;
        
        // 读取文件内容
        var reader = new FileReader();//新建一个FileReader
        reader.readAsText(objFiles.files[0], "UTF-8");//读取文件 
        reader.onload = function(evt){ //读取完文件之后会回来这里
            var fileString = evt.target.result; // 读取文件内容
            $("#pkey_text").val(fileString);
        }
    });

    // login
    $("#login_btn").click(function(){
        console.log("click Run");
        delCookie("token");
        delCookie("address");
        delCookie("username");
        delCookie("orgname");

        if($("#ECert_text").val() == "" || $("#pkey_text").val() == ""){
            alert("请选择证书和私钥文件");
            return;
        }

        var prvKey = getPrvKeyFromPEM($("#pkey_text").val());
        console.log("prvKey: ", prvKey);
        var signature = ECSign(prvKey, $("#ECert_text").val());
        console.log("signature: ", signature);

        $.ajax({
            type:'post',
            url: RESTURL + '/login',
            data:{
                signature: signature,
                cert: $("#ECert_text").val()
            },
            success:function(data){
                console.log(data);
                if(data.success){
                    alert("login success");
                    window.location.href="./putRecord.html";
                } else {
                    alert("login failed");
                }
                //document.cookie = "token=" + data.token;
                //document.cookie = "address=" + data.address;
                //document.cookie = "username=" + fileName;
                //document.cookie = "orgname=" + "OrgA";
                //if(data.address == undefined){
                //    alert("证书有误");
                //} else {
                //    window.location.href="./putRecord.html";
                //}
            },
            error:function(err){
                console.log(err)
            }
        });
    })

    $("#File_tx_input").change(function(){
        console.log("button click");
        var objFiles = document.getElementById("File_tx_input");
        // 读取文件内容
        var reader = new FileReader();//新建一个FileReader
        reader.readAsText(objFiles.files[0], "UTF-8");//读取文件 
        reader.onload = function(evt){ //读取完文件之后会回来这里
            var fileString = evt.target.result; // 读取文件内容
            $("#Hash_tx_input").val(hex_sha256(fileString)); // 计算hash
        }
    })

    // tx
    $("#tx_btn").click(function(){
        var objFiles = document.getElementById("File_tx_input");
        // 读取文件内容
        var reader = new FileReader();//新建一个FileReader
        reader.readAsText(objFiles.files[0], "UTF-8");//读取文件 
        reader.onload = function(evt){ //读取完文件之后会回来这里
            var fileString = evt.target.result; // 读取文件内容
        
            $.ajax({
                type:'post',
                
                url: RESTURL + '/atlchannel/atlchain/putRecord',
                data:JSON.stringify({
                    'peers': ['peer0.orga.atlchain.com'],
                    'args':[$("#BuyerAddr_tx_input").val(), $("#SellerAddr_tx_input").val(), $("#Price_tx_input").val(), "20181123150000",$("#Hash_tx_input").val()],
                    'hash':$("#Hash_tx_input").val(),
                    'data':fileString
                    // TODO: 在交易内容上附上签名和公钥
                    // ,'signature':signature
                    // ,'Cert':file1
                }),
                headers: {
                    "authorization": "Bearer " + getCookie("token"),
                    "content-type": "application/json"
                },
                success:function(data){
                    console.log(data);
                    alert(data + ": 写入成功");
                    $("#txID_input").val(data);
                },
                error:function(err){
                    console.log(err);
                }
            });
        }
    });

    // query by buyer addr
    $("#query_addr_btn").click(function(){
        $.ajax({
            type:'get',
            
            url: RESTURL + '/atlchannel/atlchain/getHistoryByBuyerAddr?peer=peer0.orga.atlchain.com&args=["' + $("#BuyerAddr_query_addr_input").val() + '"]',
            data:JSON.stringify(),
            headers: {
                "authorization": "Bearer " + getCookie("token") ,
                "content-type": "application/json"
            },
            success:function(data){
                console.log(data);
                alert("查询成功");
                
                $("#result_input").html(FormatOutput(data));
            },
            error:function(err){
                console.log(err);
            }
        });
    });

    // query by hash
    $("#query_hash_btn").click(function(){
        $.ajax({
            type:'get',
            
            url: RESTURL + '/atlchannel/atlchain/getHistoryByHash?peer=peer0.orga.atlchain.com&args=["' + $("#hash_query_hash_input").val() + '"]',
            data:JSON.stringify({}),
            headers: {
                "authorization": "Bearer " + getCookie("token"),
                "content-type": "application/json"
            },
            success:function(data){
                console.log(data);
                alert("查询成功");
                $("#result_input").html(FormatOutput2(data));
            },
            error:function(err){
                console.log(err);
            }
        });
    });

    // query by seller addr
    $("#query_SellerAddr_btn").click(function(){
        $.ajax({
            type:'get',
            
            url: RESTURL + '/atlchannel/atlchain/getHistoryBySellerAddr?peer=peer0.orga.atlchain.com&args=["' + $("#SellerAddr_query_input").val() + '"]',
            data:JSON.stringify({}),
            headers: {
                "authorization": "Bearer " + getCookie("token"),
                "content-type": "application/json"
            },
            success:function(data){
                console.log(data);
                alert("查询成功");
                $("#result_input").html(FormatOutput2(data));
            },
            error:function(err){
                console.log(err);
            }
        });
    });

    // get hbase data by hash
    $("#get_hbase_data_btn").click(function(){
        $.ajax({
            type:'get',
            
            url: RESTURL + '/getDataByHash?hash=' + $("#get_hbase_data_input").val(),
            data:JSON.stringify({}),
            headers: {
                "authorization": "Bearer " + getCookie("token"),
                "content-type": "application/json"
            },
            success:function(data){
                console.log(JSON.stringify(data));
                alert("查询成功");
                //$("#result_input").html(FormatOutputForHBaseData(data));
                $("#result_input").html(data[0].$);
            },
            error:function(err){
                console.log(err);
            }
        });
    });

    // get hbase data by hash
    $("#quit_btn").click(function(){
        var res = confirm("您确定要退出么？");
        if(res == true){
            delCookie("token");
            delCookie("address");
            delCookie("username");
            delCookie("orgname");
            window.location.href = "./index.html";
        } else {
            return;
        }
    });
});

// window.onbeforeunload= function(event){ 
//     delCookie("token");
//     delCookie("address");
//     delCookie("username");
//     delCookie("orgname");
// }

function _createIFrame(url, triggerDelay, removeDelay) {
    //动态添加iframe，设置src，然后删除
    setTimeout(function() {
        var frame = $('<iframe style="display: none;" class="multi-download"></iframe>');
        frame.attr('src', url);
        $(document.body).after(frame);
        setTimeout(function() {
            frame.remove();
        }, removeDelay);
    }, triggerDelay);
}

function FormatOutput(data){
    var jsonData = JSON.parse(data);
    var str ="<tr><td class=\"btbg font-center titfont\">序号</td><td class=\"btbg font-center titfont\">卖方</td><td class=\"btbg font-center titfont\">买方</td><td class=\"btbg font-center titfont\">价格</td><td class=\"btbg font-center titfont\">时间</td><td class=\"btbg font-center titfont\">哈希</td></tr>";
    for(var index in jsonData){
        str = str + "<tr><td class='font-center'>" + index +"</td><td class='font-center'>" + jsonData[index].Value.Seller + "</td><td class='font-center'>" + jsonData[index].Value.Buyer + "</td><td class='font-center'>" + jsonData[index].Value.Price + "</td><td class='font-center'>" + jsonData[index].Value.Time + "</td><td class='font-center'>" + jsonData[index].Value.Hash + "</td></tr>";    
    }
    return str;
}

function FormatOutput2(data){
    var jsonData = JSON.parse(data);
    var str ="<tr><td class=\"btbg font-center titfont\">序号</td><td class=\"btbg font-center titfont\">卖方</td><td class=\"btbg font-center titfont\">买方</td><td class=\"btbg font-center titfont\">价格</td><td class=\"btbg font-center titfont\">时间</td><td class=\"btbg font-center titfont\">哈希</td></tr>";
    for(var index in jsonData){
        str = str + "<tr><td class='font-center'>" + index +"</td><td class='font-center'>" + jsonData[index].Record.Seller + "</td><td class='font-center'>" + jsonData[index].Record.Buyer + "</td><td class='font-center'>" + jsonData[index].Record.Price + "</td><td class='font-center'>" + jsonData[index].Record.Time + "</td><td class='font-center'>" + jsonData[index].Record.Hash + "</td></tr>";    
    }
    return str;
}

function FormatOutputForHBaseData(data){
    var str = "hash值" + data[0].key + " 对应的Json数据为:</br> {";
    var column = "";
    var line_arr = Array();
    var attr_arr = Array();
    for(var index in data){
        column = data[index].column;
        if(column.split(":")[0] == "Feature"){
            str = str + "\"Feature\":" + data[index].$; 
        } else if(column.split(":")[0] == "attributes"){
            var _tmp2 = column.split(":")[1];
            var _index = Number(_tmp2.substr(1, _tmp2.length));
            console.log(_index);
            attr_arr[_index] = data[index].$;
        } else if(column.split(":")[0] == "geometry"){
            var _tmp = column.split(":")[1];
            var _tmp_tmp = _tmp.split("_")[1];
            var p_index = Number(_tmp_tmp.substr(1, _tmp_tmp.length - 2));
            var p_xy = _tmp_tmp.charAt(_tmp_tmp.length - 1);
            if(p_xy == "x"){
                line_arr[p_index * 2] = data[index].$; 
            } else if(p_xy == "y"){
                line_arr[p_index * 2 + 1] = data[index].$;
            }
        }
    }
    str = str + ",\"geometry\":{\"Line\":[[[";
    for(var i=0; i< line_arr.length; i+=2){
        str = str + line_arr[i] + "," + line_arr[i+1] + "]";
        if((i+2) < line_arr.length){
            str = str + ",[";
        }
    }
    str = str + "]]},\"attributes\":[";
    for(var i=0; i< attr_arr.length; i++){
        str = str + "\""+ attr_arr[i] + "\"";
        if((i+1) < attr_arr.length){
            str = str + ",";
        }
    }
    str = str + "]}";
    return str;
}

function getCookie(name){
    var arr,reg=new RegExp("(^| )"+name+"=([^;]*)(;|$)");
    if(arr=document.cookie.match(reg))
        return unescape(arr[2]);
    else
        return null;
}

function delCookie(name){
    var exp = new Date();
    exp.setTime(exp.getTime() - 1);
    var cval=getCookie(name);
    if(cval!=null)
        document.cookie= name + "="+cval+";expires="+exp.toGMTString();
}

// {"key":"169d9703961ba0a947ea99a7d79ec889fbbba657","column":"geometry:Line_p2x","timestamp":1542712825171,"$":"115.9238454861111"},

//{"key":"169d9703961ba0a947ea99a7d79ec889fbbba657","column":"attributes:a1","timestamp":1542712825171,"$":"110111"},{"key":"169d9703961ba0a947ea99a7d79ec889fbbba657","column":"attributes:a10","timestamp":1542712825171,"$":"-5187"},

//{"Feature":4514,"geometry":{"Line":[[[115.9247200520833,39.67575303819444],[115.9243576388889,39.675625],[115.9238454861111,39.67543619791667],[115.9228472222222,39.675078125],[115.9220985243056,39.67479166666666]]]},"attributes":["","110111","110111","1","0","1","1","0","59554700376",-1,-5187,0,"3","59554705291","0401","1","1","1","1","0.248",-15410076,6,0.3,"595547",0,2,0,"","","0","1",null,"59554704858","60","40","3","3","0","5","0","1","2","0","","","","","11110001110000000000000000000000","55"]}
//{"Feature":4514,"geometry":{"Line":[[[115.9247200520833,39.67575303819444],[115.9243576388889,39.675625],[115.9238454861111,39.67543619791667],[115.9228472222222,39.675078125],[115.9220985243056,39.67479166666666]]]},"attributes":["","110111","110111","1","0","1","1","0","59554700376","-1","-5187","0","3","59554705291","0401","1","1","1","1","0.248","-15410076","6","0.3","595547","0","2","0","","","0","1","null","59554704858","60","40","3","3","0","5","0","1","2","0","","","","","11110001110000000000000000000000","55"]}
