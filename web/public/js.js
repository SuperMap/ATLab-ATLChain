// enroll

var RESTURL = "http://148.70.109.243:4000";
var FileURL = "http://148.70.109.243:8080";
// var RESTURL = "http://127.0.0.1:4000";
// var FileURL = "http://127.0.0.1:8080";

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
    })

    $("#File_op0_put_input").change(function(){
        var objFiles = document.getElementById("File_op0_put_input");
        // 读取文件内容
        var reader = new FileReader();//新建一个FileReader
        reader.readAsText(objFiles.files[0], "UTF-8");//读取文件 
        reader.onload = function(evt){ //读取完文件之后会回来这里
            var fileString = evt.target.result; // 读取文件内容
            $("#Hash_op0_put_input").val(hex_sha256(fileString)); // 计算hash
        }
    })
    
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
                    <p> \
                        <label for=\"Stroage_op0_put_label\">存储方式:</label> \
                        <input type=\"radio\" id=\"onchain_op0_put_label\" name=\"storageType\" value=\"onchain\" style=\"width:20px; height:15px\">onchain \
                        <input type=\"radio\" id=\"hbase_op0_put_label\" name=\"storageType\" value=\"hbase\" style=\"width:20px; height:15px\">HBase \
                        <input type=\"radio\" id=\"hdfs_op0_put_label\" name=\"storageType\" value=\"hdfs\" style=\"width:20px; height:15px\">HDFS \
                    </p> \
                ")
                break;
            case "estate":
                $("#content_put_div").html(" \
                    <p> \
                        <label for=\"org_op1_put_label\">发证机构:</label> \
                        <input type=\"text\" id=\"org_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"ower_op1_put_label\">权利人:</label> \
                        <input type=\"text\" id=\"ower_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"common_op1_put_label\">共有情况:</label> \
                        <input type=\"text\" id=\"common_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"position_op1_put_label\">坐落:</label> \
                        <input type=\"text\" id=\"position_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"unitNum_op1_put_label\">不动产单元号:</label> \
                        <input type=\"text\" id=\"unitNum_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"rightType_op1_put_label\">权利类型:</label> \
                        <input type=\"text\" id=\"rightType_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"rightNature_op1_put_label\">权利性质:</label> \
                        <input type=\"text\" id=\"rightNature_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"usage_op1_put_label\">用途:</label> \
                        <input type=\"text\" id=\"usage_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"area_op1_put_label\">面积:</label> \
                        <input type=\"text\" id=\"area_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"deadline_op1_put_label\">使用期限:</label> \
                        <input type=\"text\" id=\"deadline_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"other_op1_put_label\">权利其他状况:</label> \
                        <input type=\"text\" id=\"other_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"attachment_op1_put_label\">附记:</label> \
                        <input type=\"text\" id=\"attachment_op1_put_input\"> \
                    </p> \
                ")
                break;
            default:
                break;
        } 
    })
    
    // TODO: 1. put data into HBase and HDFS. 2. parent txID
    $("#put_btn").click(function(){
        var objFiles_PrvkeyPEM = document.getElementById("Prvkey_put_input");
        var reader_PrvkeyPEM = new FileReader();
        reader_PrvkeyPEM.readAsText(objFiles_PrvkeyPEM.files[0], "UTF-8");
        reader_PrvkeyPEM.onload = function(evt_Prvkey){
            var fileString_PrvkeyPEM = evt_Prvkey.target.result;
            var Prvkey = getPrvKeyFromPEM(fileString_PrvkeyPEM);
            var storageTypeChecked = $("[name='storageType']").filter(":checked");
            var storageType = storageTypeChecked.attr("value");

            var args = "";
            switch ($("#put_select").val()) {
                case "transaction":
                    args = '{"addrsend:"' + $("#AddrSend_op0_put_input").val() + '",addrrec:"' + $("#AddrRec_op0_put_input").val() + '",price:"' + $("#Price_op0_put_input").val()+ '",hash:"' + $("#Hash_op0_put_input").val() + '}';
                    break;
                case "estate":
                    args = '{"org:"'+ $("org_op1_put_input").val() + ',"ower:"' + $("#ower_op1_put_input").val() + ',"common:"' + $("#common_op1_put_input").val() + ',"position:"' + $("#position_op1_put_input").val() + ',"uniNum:"' + $("#unitNum_op1_put_input").val() + ',"rightType:"' + $("#rightType_op1_put_input").val() + ',"rightNature_op1_put_input:"' + $("#rightNature_op1_put_input").val() + ',"usage:"' + $("#usage_op1_put_input").val() + ',"area:"' + $("#area_op1_put_input").val() + ',"deadline:"' + $("#deadline_op1_put_input").val() + ',"other:"' + $("#other_op1_put_input").val() + ',"attachment:"' + $("#attachment_op1_put_input").val() +'}';
                    storageType = "onchain";
                    break;
                default:
                    break;
            }

            var signature = ECSign(Prvkey, args);

            var objFiles_PubkeyPEM = document.getElementById("Pubkey_put_input");
            var reader_PubkeyPEM = new FileReader();
            reader_PubkeyPEM.readAsText(objFiles_PubkeyPEM.files[0], "UTF-8");
            reader_PubkeyPEM.onload = function(evt_Pubkey){
                var fileString_PubkeyPEM = evt_Pubkey.target.result;

                $.ajax({
                    type:'post',
                    
                    url: RESTURL + '/channels/atlchannel/chaincodes/atlchain/put',
                    data:JSON.stringify({
                        'fcn': 'Put',
                        'peers': ['peer0.orga.atlchain.com'],
                        'args':[args, signature, fileString_PubkeyPEM],
                        'cert':fileString_PubkeyPEM,
                        'signature':signature,
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
                        <label for=\"org_op1_get_label\">发证机构:</label> \
                        <input type=\"text\" id=\"org_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"ower_op1_get_label\">权利人:</label> \
                        <input type=\"text\" id=\"ower_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"common_op1_get_label\">共有情况:</label> \
                        <input type=\"text\" id=\"common_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"position_op1_get_label\">坐落:</label> \
                        <input type=\"text\" id=\"position_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"unitNum_op1_get_label\">不动产单元号:</label> \
                        <input type=\"text\" id=\"unitNum_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"rightType_op1_get_label\">权利类型:</label> \
                        <input type=\"text\" id=\"rightType_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"rigthNature_op1_get_label\">权利性质:</label> \
                        <input type=\"text\" id=\"rightNature_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"usage_op1_get_label\">用途:</label> \
                        <input type=\"text\" id=\"usage_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"area_op1_get_label\">面积:</label> \
                        <input type=\"text\" id=\"area_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"deadline_op1_get_label\">使用期限:</label> \
                        <input type=\"text\" id=\"deadline_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"other_op1_get_label\">权利其他状况:</label> \
                        <input type=\"text\" id=\"other_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"attachment_op1_get_label\">附记:</label> \
                        <input type=\"text\" id=\"attachment_op1_get_input\"> \
                    </p> \
                ")
                break;
            default:
                break;
        } 
    })

    // TODO: test
    $("#get_btn").click(function(){
        var args = '["{' + "addrsend:" + $("#AddrSend_op0_get_input").val() +",addrrec:" + $("AddrRec_op0_get_input").val() + ",price:" + $("#Price_op0_get_input") +",hash:" + $("#Hash_op0_get_input") + '}"]';

        $.ajax({
            type:'get',
            url: RESTURL + '/channels/atlchannel/chaincodes/atlchain/Get?peer=peer0.orga.atlchain.com&args=' + args,
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
