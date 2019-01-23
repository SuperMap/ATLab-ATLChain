// enroll

var RESTURL = "http://148.70.109.243:4000";
var FileURL = "http://148.70.109.243:8888";
// var RESTURL = "http://127.0.0.1:4000";
// var FileURL = "http://127.0.0.1:4000";

$(document).ready(function(){

    // 设置预设值
    $("#username_input").val(getCookie("username"));
    $("#orgname_input").val(getCookie("orgname"));
    $("#BuyerAddr_tx_input").val(getCookie("address"));
    $("#useraddress_input").val(getCookie("address"));
    $("#BuyerAddr_query_addr_input").val(getCookie("address"));
    $("#BuyerAddr_query_hash_addr_input").val(getCookie("address"));

    $("#header").html("<ul> \
        <li><a href=\"\"><b> >>== 区块链系统DEMO ==<< </b></a></li> \
        <li><a href=\"put.html\" id=\"tx_bar\">写入</a></li> \
        <li><a href=\"get.html\" id=\"query_addr_bar\">查询</a></li> \
        <li><a href=\"userCenter.html\" id=\"query_addr_hash_bar\">个人信息</a></li> \
        </ul>"); 

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
                    document.cookie = "token=" + data.message.token;
                    //document.cookie = "address=" + data.address;
                    document.cookie = "username=" + data.message.username;
                    document.cookie = "orgname=" + data.message.orgname;
                    window.location.href="./put.html";
                } else {
                    alert("login failed");
                }
            },
            error:function(err){
                console.log(err)
            }
        });
    });

    $("#File_op0_put_input").change(function(){
        var objFiles = document.getElementById("File_op0_put_input");
        // 读取文件内容
        var reader = new FileReader();//新建一个FileReader
        reader.readAsText(objFiles.files[0], "UTF-8");//读取文件 
        reader.onload = function(evt){ //读取完文件之后会回来这里
            var fileString = evt.target.result; // 读取文件内容
            $("#Hash_op0_put_input").val(hex_sha256(fileString)); // 计算hash
        }
    });
    
    // put
    $("#put_select").change(function(){
        switch ($("#put_select").val()) {
            case "transaction":
                $("#content_put_div").html(" \
                    <p> \
                        <label for=\"AddrSend_op0_put_label\">发送方地址:</label> \
                        <input type=\"text\" id=\"AddrSend_op0_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"AddrRec_op0_put_label\">接收方地址:</label> \
                        <input type=\"text\" id=\"AddrRec_op0_put_input\" value=\"1Lyji2Uei5sKo8uxyS1MAdP1e2gNLvhc5p\"> \
                    </p> \
                    <p> \
                        <label for=\"Price_op0_put_label\">价格:</label> \
                        <input type=\"text\" id=\"Price_op0_put_input\" value=\"10000\"> \
                    </p> \
                    <p> \
                        <label for=\"File_op0_put_label\">数据文件:</label> \
                        <input type=\"file\" id=\"File_op0_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"Hash_op0_put_label\">数据哈希:</label> \
                        <textarea id=\"Hash_op0_put_input\" rows=\"3\" cols=\"38\" readonly=\"readonly\" style=\"vertical-align: top;\"></textarea> \
                    </p> \
                ")
                break;
            case "estate":
                $("#content_put_div").html(" \
                    <p> \
                        <label for=\"estateid_op1_put_label\">证书编号:</label> \
                        <input type=\"text\" id=\"estateid_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"ower_op1_put_label\">权利人:</label> \
                        <input type=\"text\" id=\"ower_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"position_op1_put_label\">坐落:</label> \
                        <input type=\"text\" id=\"position_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"area_op1_put_label\">面积:</label> \
                        <input type=\"text\" id=\"area_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"Image_op0_put_label\">上传图片:</label> \
                        <input type=\"file\" id=\"Image_op0_put_input\"> \
                    </p> \
                ")
                break;
            default:
                break;
        } 
    });
    
    // TODO: 1. 如何追溯
    $("#put_btn").click(function(){
        var storageTypeChecked = $("[name='storageType']").filter(":checked");
        var storageType = storageTypeChecked.attr("value");

        var objFiles_PrvkeyPEM = document.getElementById("Prvkey_put_input");
        var reader_PrvkeyPEM = new FileReader();
        reader_PrvkeyPEM.readAsText(objFiles_PrvkeyPEM.files[0], "UTF-8");
        reader_PrvkeyPEM.onload = function(evt_Prvkey){
            var fileString_PrvkeyPEM = evt_Prvkey.target.result;
            var Prvkey = getPrvKeyFromPEM(fileString_PrvkeyPEM);

            var objFiles_PubkeyPEM = document.getElementById("Pubkey_put_input");
            var reader_PubkeyPEM = new FileReader();
            reader_PubkeyPEM.readAsText(objFiles_PubkeyPEM.files[0], "UTF-8");
            reader_PubkeyPEM.onload = function(evt_Pubkey){
                var fileString_PubkeyPEM = evt_Pubkey.target.result;

                var args = "";
                var signature = "";
                switch ($("#put_select").val()) {
                    case "transaction":
                        args = '{"addrsend":"' + $("#AddrSend_op0_put_input").val() + '","addrrec":"' + $("#AddrRec_op0_put_input").val() + '","price":"' + $("#Price_op0_put_input").val()+ '","hash":"' + $("#Hash_op0_put_input").val() + '"}';

                        signature = ECSign(Prvkey, args);

                        args = '{"addrsend":"' + $("#AddrSend_op0_put_input").val() + '","addrrec":"' + $("#AddrRec_op0_put_input").val() + '","price":"' + $("#Price_op0_put_input").val()+ '","hash":"' + $("#Hash_op0_put_input").val() + '","signature":"' + signature + '"}';

                        var objFiles_Data = document.getElementById("File_op0_put_input");
                        var reader_Data = new FileReader();
                        reader_Data.readAsText(objFiles_Data.files[0], "UTF-8");
                        reader_Data.onload = function(evt_Data){
                            var fileString_Data = evt_Data.target.result;
                            $.ajax({
                                type:'post',
                                
                                url: RESTURL + '/channels/atlchannel/chaincodes/atlchainCC/putTx',
                                data:JSON.stringify({
                                    'fcn': 'Put',
                                    'peers': ['peer0.orga.atlchain.com'],
                                    'args':[args, signature, fileString_PubkeyPEM],
                                    'cert':fileString_PubkeyPEM,
                                    'signature':signature,
                                    'hash':$("#Hash_op0_put_input").val(),
                                    'txdata':fileString_Data,
                                    'storageType':storageType,
                                    'username':getCookie("username"),
                                    'orgname':getCookie("orgname")
                                }),
                                headers: {
                                    "authorization": "Bearer " + getCookie("token"),
                                    "content-type": "application/json"
                                },
                                success:function(data){
                                    console.log(data);
                                    alert(data + ": 写入成功");
                                    $("#txID_put_input").val(data);
                                },
                                error:function(err){
                                    console.log(err);
                                }
                            });
                        }
                        break;
                    case "estate":
                        var objFiles_Image = document.getElementById("Image_op0_put_input");
                        var reader_Image = new FileReader();
                        reader_Image.readAsText(objFiles_Image.files[0], "UTF-8");
                        reader_Image.onload = function(evt_Image){
                            var fileString_Image = evt_Image.target.result;
                            console.log(fileString_Image);
                            var b = new Base64();  
                            var fileString_Image_Base64 = b.encode(fileString_Image);  
                            console.log(fileString_Image_Base64);

                            args = '{"estateid":"'+ $("#estateid_op1_put_input").val() + '","ower":"' + $("#ower_op1_put_input").val() + '","position":"' + $("#position_op1_put_input").val() + '","area":"' + $("#area_op1_put_input").val() + '"hash":"' + hex_sha256(fileString_Image) + '"}';
                            signature = ECSign(Prvkey, args);

                            args = '{"estateid":"'+ $("#estateid_op1_put_input").val() + '","ower":"' + $("#ower_op1_put_input").val() + '","position":"' + $("#position_op1_put_input").val() + '","area":"' + $("#area_op1_put_input").val() + '","hash":"' + hex_sha256(fileString_Image) + '","signature":"' + signature + '"}';
                            console.log(args);

                            $.ajax({
                                type:'post',
                                
                                url: RESTURL + '/channels/atlchannel/chaincodes/atlchainCC/putEstate',
                                data:JSON.stringify({
                                    'fcn': 'Put',
                                    'peers': ['peer0.orga.atlchain.com'],
                                    'args':[args, signature, fileString_PubkeyPEM],
                                    'cert':fileString_PubkeyPEM,
                                    'signature':signature,
                                    'hash':hex_sha256(fileString_Image),
                                    'imgdata':fileString_Image_Base64,
                                    'storageType':storageType,
                                    'username':getCookie("username"),
                                    'orgname':getCookie("orgname")
                                }),
                                headers: {
                                    "authorization": "Bearer " + getCookie("token"),
                                    "content-type": "application/json"
                                },
                                success:function(data){
                                    console.log(data);
                                    alert(data + ": 写入成功");
                                    $("#txID_put_input").val(data);
                                },
                                error:function(err){
                                    console.log(err);
                                }
                            });
                        }
                        break;
                    default:
                        break;
                }

            }
        }
    });

    // get
    $("#get_select").change(function(){
        switch ($("#get_select").val()) {
            case "transaction":
                $("#content_get_div").html(" \
                    <p> \
                        <label for=\"AddrSend_op0_get_label\">发送方地址:</label> \
                        <input type=\"text\" id=\"AddrSend_op0_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"AddrRec_op0_get_label\">接收方地址:</label> \
                        <input type=\"text\" id=\"AddrRec_op0_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"Price_op0_get_label\">价格:</label> \
                        <input type=\"text\" id=\"Price_op0_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"Hash_op0_get_label\">数据哈希:</label> \
                        <textarea id=\"Hash_op0_get_input\" rows=\"3\" cols=\"38\" style=\"vertical-align: top;\"></textarea> \
                    </p> \
                ")
                break;
            case "estate":
                $("#content_get_div").html(" \
                    <p> \
                        <label for=\"id_op1_get_label\">证书编号:</label> \
                        <input type=\"text\" id=\"id_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"ower_op1_get_label\">权利人:</label> \
                        <input type=\"text\" id=\"ower_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"position_op1_get_label\">坐落:</label> \
                        <input type=\"text\" id=\"position_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"area_op1_get_label\">面积:</label> \
                        <input type=\"text\" id=\"area_op1_get_input\"> \
                    </p> \
                ")
                break;
            default:
                break;
        } 
    });

    $("#get_btn").click(function(){
        switch($("#get_select").val()){
            case "transaction":
                var args = '{';
                var args0 = "";
                var args1 = "";
                var args2 = "";
                var args3 = "";
                var shouldAddComma = false;
                if($("#AddrSend_op0_get_input").val() != ""){
                    args0 = '"addrsend":"' + $("#AddrSend_op0_get_input").val() + '"';     
                    shouldAddComma = true;
                    args += args0;
                }
                if($("#AddrRec_op0_get_input").val() != ""){
                    args1 = '"addrrec":"' + $("#AddrRec_op0_get_input").val() + '"';     
                    if(shouldAddComma){
                        args += ',';
                    }
                    shouldAddComma = true;
                    args += args1;
                }
                if($("#Price_op0_get_input").val() != ""){
                    args2 = '"price":"' + $("#Price_op0_get_input").val() + '"';     
                    if(shouldAddComma){
                        args += ',';
                    }
                    shouldAddComma = true;
                    args += args2;
                }
                if($("#Hash_op0_get_input").val() != ""){
                    args3 = '"hash":"' + $("#Hash_op0_get_input").val() + '"';     
                    if(shouldAddComma){
                        args += ',';
                    }
                    shouldAddComma = true;
                    args += args3;
                }
                args += '}';

                $.ajax({
                    type:'post',
                    url: RESTURL + '/channels/atlchannel/chaincodes/atlchainCC/get',
                    data:JSON.stringify({
                        'fcn': 'Get',
                        'peer': 'peer0.orga.atlchain.com',
                        'args':[args],
                        'username':getCookie("username"),
                        'orgname':getCookie("orgname")
                    }),
                    headers: {
                        "authorization": "Bearer " + getCookie("token") ,
                        "content-type": "application/json"
                    },
                    success:function(data){
                        console.log(data);
                        
                        $("#result_input").html(FormatOutputTx(data));
                    },
                    error:function(err){
                        console.log(err);
                    }
                });
                break;
            case "estate":
                var args = '{';
                var args0 = "";
                var args1 = "";
                var args2 = "";
                var args3 = "";
                var shouldAddComma = false;
                if($("#id_op1_get_input").val() != ""){
                    args0 = '"estateid":"' + $("#id_op1_get_input").val() + '"';
                    shouldAddComma = true;
                    args += args0;
                }
                if($("#ower_op1_get_input").val() != ""){
                    args1 = '"ower":"' + $("#ower_op1_get_input").val() + '"';     
                    if(shouldAddComma){
                        args += ',';
                    }
                    shouldAddComma = true;
                    args += args1;
                }
                if($("#position_op1_get_input").val() != ""){
                    args2 = '"position":"' + $("#position_op1_get_input").val() + '"';     
                    if(shouldAddComma){
                        args += ',';
                    }
                    shouldAddComma = true;
                    args += args2;
                }
                if($("#area_op1_get_input").val() != ""){
                    args3 = '"area":"' + $("#area_op1_get_input").val() + '"';
                    if(shouldAddComma){
                        args += ',';
                    }
                    shouldAddComma = true;
                    args += args3;
                }
                args += '}';

                $.ajax({
                    type:'post',
                    url: RESTURL + '/channels/atlchannel/chaincodes/atlchainCC/get',
                    data:JSON.stringify({
                        'fcn': 'Get',
                        'peer': 'peer0.orga.atlchain.com',
                        'args':[args],
                        'username':getCookie("username"),
                        'orgname':getCookie("orgname")
                    }),
                    headers: {
                        "authorization": "Bearer " + getCookie("token") ,
                        "content-type": "application/json"
                    },
                    success:function(data){
                        console.log(data);
                        alert("查询成功");
                        
                        $("#result_input").html(FormatOutputEstate(data));
                    },
                    error:function(err){
                        console.log(err);
                    }
                });
                break;
            default:
                break;
        }
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

function FormatOutputTx(data){
    var jsonData = JSON.parse(data);
    console.log(jsonData);
    var str ="<tr><td class=\"btbg font-center titfont\">序号</td><td class=\"btbg font-center titfont\">发送方</td><td class=\"btbg font-center titfont\">接受方</td><td class=\"btbg font-center titfont\">价格</td><td class=\"btbg font-center titfont\">哈希</td><td class=\"btbg font-center titfont\">签名</td></tr>";
    for(var index in jsonData){
        str = str + "<tr><td class='font-center'>" + index +"</td><td class='font-center'>" + jsonData[index].Record.addrsend + "</td><td class='font-center'>" + jsonData[index].Record.addrrec + "</td><td class='font-center'>" + jsonData[index].Record.price + "</td><td class='font-center'>" + jsonData[index].Record.hash + "</td><td class='font-center'>" + jsonData[index].Record.signature + "</td></tr>";    
    }
    return str;
}

function FormatOutputEstate(data){
    var jsonData = JSON.parse(data);
    var str ="<tr><td class=\"btbg font-center titfont\">序号</td><td class=\"btbg font-center titfont\">证书编号</td><td class=\"btbg font-center titfont\">权利人</td><td class=\"btbg font-center titfont\">坐落</td><td class=\"btbg font-center titfont\">面积</td></tr>";
    for(var index in jsonData){
        str = str + "<tr><td class='font-center'>" + index +"</td><td class='font-center'>" + jsonData[index].Record.estateid + "</td><td class='font-center'>" + jsonData[index].Record.ower + "</td><td class='font-center'>" + jsonData[index].Record.position + "</td><td class='font-center'>" + jsonData[index].Record.area + "</td></tr>";    
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
