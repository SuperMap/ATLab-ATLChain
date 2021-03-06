// enroll

var RESTURL = "http://127.0.0.1:4000";
var FileURL = "http://127.0.0.1:4444";
// var RESTURL = "http://175.154.161.50:7002";
// var FileURL = "http://175.154.161.50:7001";

$(document).ready(function(){
    // 设置预设值
    $("#username_input").val(getCookie("username"));
    $("#orgname_input").val(getCookie("orgname"));
    $("#BuyerAddr_tx_input").val(getCookie("address"));
    $("#useraddress_input").val(getCookie("address"));
    $("#BuyerAddr_query_addr_input").val(getCookie("address"));
    $("#BuyerAddr_query_hash_addr_input").val(getCookie("address"));

    $("#bar").html("<h1><center> \
        税务部门 \
    </h1></center>");

    $("#header").html("<ul> \
        <li><a href=\"\"><b> >>== 区块链系统DEMO v2.0 ==<< </b></a></li> \
        <li><a href=\"put.html\" id=\"tax_bar\">新增记录</a></li> \
        <li><a href=\"get.html\" id=\"query_bar\">查询记录</a></li> \
        <li><a href=\"trace.html\" id=\"trace_bar\">追溯记录</a></li> \
        <li><a href=\"getDataFromHBase.html\" id=\"getDataFromHBase_bar\">获取HBASE数据</a></li> \
        <li><a href=\"getDataFromHDFS.html\" id=\"getDataFromHDFS_bar\">获取HDFS数据</a></li> \
        <li><a href=\"getDataFromIPFS.html\" id=\"getDataFromIPFS_bar\">获取IPFS数据</a></li> \
        <li><a href=\"userCenter.html\" id=\"userCenter_bar\">个人信息</a></li> \
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
                console.log(data);
                var username = $("#username_input").val();
                $("#accountAddress_input").val(data.address);
                alert($("#username_input").val() + "登记成功\n请保存好下载的证书和密钥文件\n请牢记账户地址:" + data.address);

                // 下载多个文件
                let triggerDelay = 100;
                let removeDelay = 1000;
                //存放多个下载的url，
                let url_arr=[FileURL + "/tax/msp/" + username,  FileURL + "/tax/msp/" + data.filename];
                
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
                alert("请选择正确的证书");
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

    // login >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    $("#login_btn").click(function(){
        delCookie("token");
        delCookie("address");
        delCookie("username");
        delCookie("orgname");

        // 只使用证书登录
        // if($("#ECert_text").val() == "" || $("#pkey_text").val() == ""){
        if($("#ECert_text").val() == ""){
            alert("请选择证书文件");
            return;
        }

        // var prvKey = getPrvKeyFromPEM($("#pkey_text").val());
        // console.log("prvKey: ", prvKey);
        // var signature = ECSign(prvKey, $("#ECert_text").val());
        // console.log("signature: ", signature);

        $.ajax({
            type:'post',
            url: RESTURL + '/login',
            data:{
                // signature: signature,
                cert: $("#ECert_text").val()
            },
            success:function(data){
                console.log(data);
                if(data.success){
                    document.cookie = "token=" + data.message.token;
                    document.cookie = "address=" + data.message.address;
                    document.cookie = "username=" + data.message.username;
                    document.cookie = "orgname=" + data.message.orgname;
                    // document.cookie = "cert=" + $("#ECert_text");
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
    // login <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    // put >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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
                        <label for=\"ParentID_op0_put_label\">父交易ID（无父交易请空白）:</label> \
                        <textarea id=\"ParentID_op0_put_input\" rows=\"3\" cols=\"38\" style=\"vertical-align: top;\"></textarea> \
                    </p> \
                ");
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
                break;
            case "estate":
                $("#content_put_div").html(" \
                    <p> \
                        <label for=\"ZZBH_op1_put_label\">证照编号:</label> \
                        <input type=\"text\" id=\"ZZBH_op1_put_input\"> \
                    </p> \
                    <p> \
                        <label for=\"KZ_BDCQZH_op1_put_label\">不动产权证号:</label> \
                        <input type=\"text\" id=\"KZ_BDCQZH_op1_put_input\" value=\"蒙(2016)XXXX旗不动产证明第0000118号\"> \
                    </p> \
                    <p> \
                        <label for=\"CZZT_op1_put_label\">持证主体:</label> \
                        <input type=\"text\" id=\"CZZT_op1_put_input\" value=\"张三\"> \
                    </p> \
                    <p> \
                        <label for=\"KZ_QLRZJH_op1_put_label\">权利人证件号:</label> \
                        <input type=\"text\" id=\"KZ_QLRZJH_op1_put_input\" value=\"121522********727E\"> \
                    </p> \
                    <p> \
                        <label for=\"ZZBFJG_op1_put_label\">证照颁发机构:</label> \
                        <input type=\"text\" id=\"ZZBFJG_op1_put_input\" value=\"XXX不动产登记机构\"> \
                    </p> \
                    <p> \
                        <label for=\"ZZBFRQ_op1_put_label\">证照颁发日期:</label> \
                        <input type=\"text\" id=\"ZZBFRQ_op1_put_input\" value=\"2019年1月16日\"> \
                    </p> \
                    <p> \
                        <label for=\"KZ_ZL_op1_put_label\">坐落:</label> \
                        <input type=\"text\" id=\"KZ_ZL_op1_put_input\" value=\"XXX小区A12号楼1单元602室\"> \
                    </p> \
                    <p> \
                        <label for=\"KZ_MJ_op1_put_label\">面积:</label> \
                        <input type=\"text\" id=\"KZ_MJ_op1_put_input\" value=\"宗地面积23942.21㎡\"> \
                    </p> \
                    <p> \
                        <label for=\"ParentID_op0_put_label\">父交易ID（无父交易请空白）:</label> \
                        <textarea id=\"ParentID_op0_put_input\" rows=\"3\" cols=\"38\" style=\"vertical-align: top;\"></textarea> \
                    </p> \
                    <p> \
                        <label for=\"Image_op1_put_label\">选择图片:</label> \
                        <input type=\"file\" id=\"Image_op1_put_input\"> \
                    </p> \
                ");
                break;
            default:
                break;
        } 
    });

    $("#Pubkey_put_input").change(function(){
        var objFiles = document.getElementById("Pubkey_put_input");
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
        }
    });

    $("#put_btn").click(function(){
        var storageTypeChecked = $("[name='storageType']").filter(":checked");
        var storageType = storageTypeChecked.attr("value");
        var parentRecordID = "";

        var objFiles_PrvkeyPEM = document.getElementById("Prvkey_put_input");
        var reader_PrvkeyPEM = new FileReader();
        try{
            reader_PrvkeyPEM.readAsText(objFiles_PrvkeyPEM.files[0], "UTF-8");
        } catch(err) {
            alert("请选择签名密钥");
            return;
        }
        reader_PrvkeyPEM.onload = function(evt_Prvkey){
            var fileString_PrvkeyPEM = evt_Prvkey.target.result;
            var Prvkey = getPrvKeyFromPEM(fileString_PrvkeyPEM);

            var objFiles_PubkeyPEM = document.getElementById("Pubkey_put_input");
            var reader_PubkeyPEM = new FileReader();

            try{
                reader_PubkeyPEM.readAsText(objFiles_PubkeyPEM.files[0], "UTF-8");
            } catch(err) {
                alert("请选择身份证书");
                return;
            }

            reader_PubkeyPEM.onload = function(evt_Pubkey){
                var fileString_PubkeyPEM = evt_Pubkey.target.result;
                try {
                    var jsonFile = JSON.parse(fileString_PubkeyPEM);
                } catch(err){
                    alert("请选择正确的身份证书");
                    return;
                }
                var args = "";
                var signature = "";
                switch ($("#put_select").val()) {
                    case "transaction":
                        if($("#ParentID_op0_put_input").val() != ""){
                            parentRecordID = $("#ParentID_op0_put_input").val();
                        }
                        args = '{"hash":"' + $("#Hash_op0_put_input").val() + '","addrrec":"' + $("#AddrRec_op0_put_input").val() + '","price":"' + $("#Price_op0_put_input").val() + '","storageType":"' + storageType + '","addrsend":"' + $("#AddrSend_op0_put_input").val() + '","parentRecordID":"'+ parentRecordID +'"}';

                        signature = ECSign(Prvkey, args);

                        var argsHash = hex_sha256(args);

                        args = '{"hash":"' + $("#Hash_op0_put_input").val() + '","recordID":"' + argsHash + '","addrrec":"' + $("#AddrRec_op0_put_input").val() + '","price":"' + $("#Price_op0_put_input").val() + '","storageType":"' + storageType + '","addrsend":"' + $("#AddrSend_op0_put_input").val() + '","parentRecordID":"' + parentRecordID + '","signature":"'  + signature + '"}';

                        console.log("args:" + args);

                        var objFiles_Data = document.getElementById("File_op0_put_input");
                        var reader_Data = new FileReader();
                        try {
                            reader_Data.readAsText(objFiles_Data.files[0], "UTF-8");
                        } catch(err) {
                            alert("请选择数据文件");
                            return;
                        }
                        reader_Data.onload = function(evt_Data){
                            var fileString_Data = evt_Data.target.result;
                            var dataHash = $("#Hash_op0_put_input").val();
                            $.ajax({
                                type:'post',
                                
                                url: RESTURL + '/channels/txchannel/chaincodes/atlchainCC/putTx',
                                data:JSON.stringify({
                                    'fcn': 'Put',
                                    'peers':['peer0.orgb.example.com'],
                                    'args':[argsHash, args, signature, fileString_PubkeyPEM],
                                    'cert':fileString_PubkeyPEM,
                                    'signature':signature,
                                    'hash':dataHash,
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
                        if($("#ParentID_op1_put_input").val() != ""){
                            parentRecordID = $("#ParentID_op1_put_input").val();
                        }
                        var objFiles_Image = document.getElementById("Image_op1_put_input");
                        var reader_Image = new FileReader();
                        try {
                            reader_Image.readAsBinaryString(objFiles_Image.files[0]);
                        } catch(err) {
                            alert("请选择图片");
                            return;
                        }
                        reader_Image.onload = function(evt_Image){
                            var fileString_Image = evt_Image.target.result;
                            var GFHTH = $("#GFHTH_op1_put_input").val();

                            // console.log(fileString_Image);
                            // image base64 encode
                            // var b = new Base64();  
                            // var fileString_Image_Base64 = b.encode(fileString_Image);  
                            // console.log(fileString_Image_Base64);

                            args = '{"GFHTH":"'+ GFHTH + '","FWSYQZH":"' + $("#FWSYQZH_op1_put_input").val() + '","JZMJ":"' + $("#JZMJ_op1_put_input").val() + '","CJJG":"' + $("#CJJG_op1_put_input").val() + '","FWDZ":"' + $("#FWDZ_op1_put_input").val() + '","CQR":"' + $("#CQR_op1_put_input").val() + '","QS":"' + $("#QS_op1_put_input").val() + '","TDCRJ":"' + $("#TDCRJ_op1_put_input").val() + '","GRSDS":"' + $("#GRSDS_op1_put_input").val() + '","YHS":"' + $("#YHS_op1_put_input").val() + '","GGWXJJ":"' + $("#GGWXJJ_op1_put_input").val() + '","storageType":"' + storageType + '","status":"已纳税' + '","hash":"' + hex_sha256(fileString_Image) + '","parentRecordID":"' + parentRecordID + '"}';

                            signature = ECSign(Prvkey, args);
                            var argsHash = hex_sha256(args);

                            args = '{"GFHTH":"'+ GFHTH + '","FWSYQZH":"' + $("#FWSYQZH_op1_put_input").val() + '","JZMJ":"' + $("#JZMJ_op1_put_input").val() + '","CJJG":"' + $("#CJJG_op1_put_input").val() + '","FWDZ":"' + $("#FWDZ_op1_put_input").val() + '","CQR":"' + $("#CQR_op1_put_input").val() + '","QS":"' + $("#QS_op1_put_input").val() + '","TDCRJ":"' + $("#TDCRJ_op1_put_input").val() + '","GRSDS":"' + $("#GRSDS_op1_put_input").val() + '","YHS":"' + $("#YHS_op1_put_input").val() + '","GGWXJJ":"' + $("#GGWXJJ_op1_put_input").val() + '","storageType":"' + storageType + '","status":"已纳税' + '","hash":"' + hex_sha256(fileString_Image) + '","parentRecordID":"' + parentRecordID + '","recordID":"' + argsHash + '","signature":"' + signature + '"}';
                            console.log(args);

                            $.ajax({
                                type:'post',
                                
                                url: RESTURL + '/channels/txchannel/chaincodes/atlchainCC/AddRecord',
                                data:JSON.stringify({
                                    'args':[argsHash, args, signature, fileString_PubkeyPEM],
                                    'imgdata':fileString_Image,
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

    function taxButtonClick(){
        var storageTypeChecked = $("[name='storageType']").filter(":checked");
        var storageType = storageTypeChecked.attr("value");
        var parentRecordID = "";

        var objFiles_PrvkeyPEM = document.getElementById("Prvkey_put_input");
        var reader_PrvkeyPEM = new FileReader();
        try{
            reader_PrvkeyPEM.readAsText(objFiles_PrvkeyPEM.files[0], "UTF-8");
        } catch(err) {
            alert("请选择签名密钥");
            return;
        }
        reader_PrvkeyPEM.onload = function(evt_Prvkey){
            var fileString_PrvkeyPEM = evt_Prvkey.target.result;
            var Prvkey = getPrvKeyFromPEM(fileString_PrvkeyPEM);

            var objFiles_PubkeyPEM = document.getElementById("Pubkey_put_input");
            var reader_PubkeyPEM = new FileReader();

            try{
                reader_PubkeyPEM.readAsText(objFiles_PubkeyPEM.files[0], "UTF-8");
            } catch(err) {
                alert("请选择身份证书");
                return;
            }

            reader_PubkeyPEM.onload = function(evt_Pubkey){
                var fileString_PubkeyPEM = evt_Pubkey.target.result;
                try {
                    var jsonFile = JSON.parse(fileString_PubkeyPEM);
                } catch(err){
                    alert("请选择正确的身份证书");
                    return;
                }
                var args = "";
                var signature = "";

                var GFHTH = $("#GFHTH_op1_put_input").val();
                var FWSYQZH = $("#FWSYQZH_op1_put_input").val();
                var JZMJ = $("#JZMJ_op1_put_input").val();
                var CJJG = $("#CJJG_op1_put_input").val();
                var FWDZ = $("#FWDZ_op1_put_input").val();
                var CQR = $("#CQR_op1_put_input").val();
                var QS = $("#QS_op1_put_input").val();
                var TDCRJ = $("#TDCRJ_op1_put_input").val();
                var GRSDS = $("#GRSDS_op1_put_input").val();
                var YHS = $("#YHS_op1_put_input").val();
                var GGWXJJ = $("#GGWXJJ_op1_put_input").val();
                var parentRecordID = $("#tax_parentID")[0].innerHTML;

                args = '{"GFHTH":"'+ GFHTH + '","FWSYQZH":"' + FWSYQZH + '","JZMJ":"' + JZMJ + '","CJJG":"' + CJJG + '","FWDZ":"'+ FWDZ + '","CQR":"' + CQR + '","QS":"' + QS + '","TDCRJ":"' + TDCRJ + '","GRSDS":"' + GRSDS + '","YHS":"' + YHS + '","GGWXJJ":"' + GGWXJJ + '","status":"已纳税' + '","parentRecordID":"' + parentRecordID + '"}';
                signature = ECSign(Prvkey, args);
                var argsHash = hex_sha256(args);
                // var argsHash = parentRecordID;
                args = '{"GFHTH":"'+ GFHTH + '","FWSYQZH":"' + FWSYQZH + '","JZMJ":"' + JZMJ + '","CJJG":"' + CJJG + '","FWDZ":"'+ FWDZ + '","CQR":"' + CQR + '","QS":"' + QS + '","TDCRJ":"' + TDCRJ + '","GRSDS":"' + GRSDS + '","YHS":"' + YHS + '","GGWXJJ":"' + GGWXJJ + '","status":"已纳税' + '","parentRecordID":"' + parentRecordID + '","recordID":"' + argsHash + '","signature":"' + signature + '"}';
                console.log("args:" + args);

                $.ajax({
                    type:'post',
                    
                    url: RESTURL + '/channels/txchannel/chaincodes/atlchainCC/AddRecord',
                    data:JSON.stringify({
                        'args':[argsHash, args, signature, fileString_PubkeyPEM],
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
                        $("#result_txID_div").html(" \
                            <p style=\"text-align: center\"> \
                                        <label for=\"txID_put_label\">记录ID:</label> \
                                        <textarea rows=\"3\" cols=\"50\" readonly=\"readonly\" style=\"vertical-align: top;\">" + data + "</textarea> \
                                    </p> \
                            ");
                        $("#result_div").html("");
                    },
                    error:function(err){
                        console.log(err);
                    }
                });
            }
        }
    }

    $('body').on('click' , '#tax_commit_btn' , function(){
        taxButtonClick();
    });

    // put <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // trace >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    // $("#trace_select").change(function(){
        //     switch ($("#trace_select").val()) {
        //         case "transaction":
        //             $("#content_trace_div").html(" \
        //                 <p> \
        //                     <label for=\"txid_op0_trace_label\">记录号:</label> \
        //                     <textarea id=\"txid_op0_trace_input\" rows=\"3\" cols=\"38\" style=\"vertical-align: top;\"></textarea> \
        //                 </p> \
        //                 <p> \
        //                     根据记录号追溯数据交易历史 \
        //                 </p> \
        //             ")
        //             break;
        //         case "estate":
        //             $("#content_trace_div").html(" \
        //                 <p> \
        //                     <label for=\"ZZBH_op1_trace_label\">证书编号:</label> \
        //                     <input type=\"text\" id=\"ZZBH_op1_trace_input\"> \
        //                 </p> \
        //                 <p> \
        //                     根据不动产证书编号追溯数据交易历史 \
        //                 </p> \
        //             ")
        //             break;
        //         default:
        //             break;
        //     } 
    // });

    function getTractionOneKey(txid, pData){
        $.ajax({
            type:'post',
            url: RESTURL + '/channels/txchannel/chaincodes/atlchainCC/TraceRecord',
            data:JSON.stringify({
                // 'fcn': 'getHistoryByKey',
                // 'peer': 'peer0.orgb.example.com',
                'args':[txid],
                'username':getCookie("username"),
                'orgname':getCookie("orgname")
            }),
            headers: {
                "authorization": "Bearer " + getCookie("token") ,
                "content-type": "application/json"
            },
            success:function(data){
                console.log(data);
                
                if(data == "[]"){
                    alert("未查询到结果");
                }
                if (pData == "") {
                    cdata = pData + data.substring(1, data.length - 1);
                } else {
                    cdata = pData + "," + data.substring(1, data.length - 1);
                }
                // console.log(cdata);
                var jsonData = JSON.parse(data);
                var pID = jsonData[0]["Value"]["parentRecordID"];
                if(pID != "" && pID.length == 64){
                    getTraction(pID, cdata);

                } else {
                    $("#result_input").html(FormatOutputUsual("[" + cdata + "]"));
                }
            },
            error:function(err){
                console.log(err);
            }
        });
    }

    function getTractionStepByStep(txid, pData){
        $.ajax({
            type:'post',
            url: RESTURL + '/channels/txchannel/chaincodes/atlchainCC/TraceRecord',
            data:JSON.stringify({
                // 'fcn': 'getHistoryByKey',
                // 'peer': 'peer0.orgb.example.com',
                'args':[txid],
                'username':getCookie("username"),
                'orgname':getCookie("orgname")
            }),
            headers: {
                "authorization": "Bearer " + getCookie("token") ,
                "content-type": "application/json"
            },
            success:function(data){
                console.log(data);
                
                if(data == "[]"){
                    alert("未查询到结果");
                }

                var jsonData = JSON.parse(data);
                var pID = jsonData[0]["Value"]["parentRecordID"];
                if(pID != "" && pID.length == 64){
                    $("#result_input").html(FormatOutputUsualWithUrl(data));
                } else {
                    $("#result_input").html(FormatOutputUsual(data));
                }
            },
            error:function(err){
                console.log(err);
            }
        });
    }

    $('body').on('click' , '#traceParentTxID' , function(){
        console.log("tracing parent tx id...");
        getTractionStepByStep($("#traceParentTxIDContent").html().trim(), "");
    });

    $("#trace_btn").click(function(){
        pTxID = $("#recordID_trace_input").val()
        getTractionStepByStep(pTxID, "");
    });
    // trace <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    // get >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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
                        <label for=\"RecordID_op0_get_label\">交易ID:</label> \
                        <input type=\"text\" id=\"RecordID_op0_get_input\"> \
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
                        <label for=\"ZZBH_op1_get_label\">证照编号:</label> \
                        <input type=\"text\" id=\"ZZBH_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"CZZT_op1_get_label\">持证主体:</label> \
                        <input type=\"text\" id=\"CZZT_op1_get_input\"> \
                    </p> \
                    <p> \
                        <label for=\"RecordID_op1_get_label\">交易ID:</label> \
                        <input type=\"text\" id=\"RecordID_op1_get_input\"> \
                    </p> \
                ")
                break;
            default:
                break;
        } 
    });

    $("#get_btn").click(function(){
        if($("#RecordID_op1_get_input").val() == "" &&  $("#GFHTH_op1_get_input").val() == ""){
            alert("请输入任一查询条件");
            return;
        }
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
                if($("#RecordID_op0_get_input").val() != ""){
                    args2 = '"recordID":"' + $("#RecordID_op0_get_input").val() + '"';     
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
                    url: RESTURL + '/channels/txchannel/chaincodes/atlchainCC/GetRecord',
                    data:JSON.stringify({
                        'fcn': 'Get',
                        'peer': 'peer0.orgb.example.com',
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
                        $("#result_input").html(FormatOutputUsual(data));
                        if(data == "[]"){
                            alert("未查询到结果");
                        }
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
                var shouldAddComma = false;
                if($("#GFHTH_op1_get_input").val() != ""){
                    args0 = '"GFHTH":"' + $("#GFHTH_op1_get_input").val() + '"';
                    shouldAddComma = true;
                    args += args0;
                }
                if($("#CQR_op1_get_input").val() != ""){
                    args1 = '"CQR":"' + $("#CQR_op1_get_input").val() + '"';     
                    if(shouldAddComma){
                        args += ',';
                    }
                    shouldAddComma = true;
                    args += args1;
                }
                if($("#RecordID_op1_get_input").val() != ""){
                    args1 = '"recordID":"' + $("#RecordID_op1_get_input").val() + '"';     
                    if(shouldAddComma){
                        args += ',';
                    }
                    shouldAddComma = true;
                    args += args1;
                }
                if(true){
                    if(shouldAddComma){
                        args += ',';
                    }
                    shouldAddComma = true;
                    args += '"status":"已纳税"';
                }

                args += '}';

                $.ajax({
                    type:'post',
                    url: RESTURL + '/channels/txchannel/chaincodes/atlchainCC/GetRecord',
                    data:JSON.stringify({
                        'fcn': 'Get',
                        'peer': 'peer0.orgb.example.com',
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
                        $("#get_result_title").text("查询结果");
                        $("#result_input").html(FormatOutputTable(data));
                        $("#show_result_button").html("");
                        if(data == "[]"){
                            alert("未查询到结果");
                        }
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

    $("#get_put_btn").click(function(){
        switch($("#get_select").val()){
            case "estate":
                var args = '{';
                args += '"recordID":"' + $("#RecordID_op1_put_input").val() + '"';     
                args += ',"status":"已交易"';     
                args += '}';
                console.log(args);

                $.ajax({
                    type:'post',
                    url: RESTURL + '/channels/txchannel/chaincodes/atlchainCC/GetRecord',
                    data:JSON.stringify({
                        'fcn': 'Get',
                        'peer': 'peer0.orgb.example.com',
                        'args':[args],
                        'username':getCookie("username"),
                        'orgname':getCookie("orgname")
                    }),
                    headers: {
                        "authorization": "Bearer " + getCookie("token") ,
                        "content-type": "application/json"
                    },
                    success:function(data){
                        console.log("data:" + data);
                        var jsonData = JSON.parse(data);
                        var args = '{';
                        try{
                            args += '"GFHTH":"' + jsonData[0]["Record"]["HTH"] + '"';
                        } catch(e) {
                           alert("请输入正确的交易部门交易ID！");
                            return;
                        }
                        args += '}';
                        $.ajax({
                            type:'post',
                            url: RESTURL + '/channels/txchannel/chaincodes/atlchainCC/GetRecord',
                            data:JSON.stringify({
                                'fcn': 'Get',
                                'peer': 'peer0.orgb.example.com',
                                'args':[args],
                                'username':getCookie("username"),
                                'orgname':getCookie("orgname")
                            }),
                            headers: {
                                "authorization": "Bearer " + getCookie("token") ,
                                "content-type": "application/json"
                            },
                            success:function(data2){
                                console.log("data2:" + data2);
                                if(data2 == "[]"){
                                    console.log(data);
                                    $("#get_result_title").text("查询结果");
                                    $("#result_input").html(FormatOutputTableDetail(data));
                                    $("#show_result_button").html("");
                                    if(data == "[]"){
                                        alert("未查询到结果");
                                    }else{
                                        $("#show_result_button").html(FormatOutputTableTaxButton());
                                    }
                                }else{
                                    $("#result_input").html(FormatOutputTableDetail2(data));
                                    alert("该交易已纳税");
                                }

                                $("#show_pic").html(" \
                                    <p style=\"text-align:left\"><b>附件：</b></p> \
                                    <img width=\"900px\" height=\"600px\" src=\"../tmp/" + $("#dataHash")[0].innerHTML + "\"> \
                                ");
                            },
                            error:function(err){
                                console.log(err);
                            }
                        });


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

    function showDetail(txid){
        txid = window.event.srcElement.id;
        var args = '{';
        args += '"recordID":"' + txid + '"';     
        args += '}';
        console.log("txID: " + args);
        $.ajax({
            type:'post',
            url: RESTURL + '/channels/txchannel/chaincodes/atlchainCC/GetRecord',
            data:JSON.stringify({
                'fcn': 'Get',
                'peer': 'peer0.orgb.example.com',
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
                $("#get_result_title").text("详细结果");
                $("#result_input").html(FormatOutputTableDetail(data));
                if(data == "[]"){
                    alert("未查询到结果");
                }else{
                    var jsonData = JSON.parse(data);
                    if(jsonData[0]["Record"]["status"]=="已交易"){
                        $("#show_result_button").html(FormatOutputTableDetailButton());
                    }
                }
            },
            error:function(err){
                console.log(err);
            }
        });
    }

    $('body').on('click', '.detailLink' , function(){
        showDetail($(".detailLink").html().trim(), "");
    });

    $("#hbase_btn").click(function(){
        $.ajax({
            type:'get',
            
            url: RESTURL + '/GetDataFromHBase?hash=' + $("#key_hbase_input").val(),
            data:JSON.stringify({}),
            headers: {
                "authorization": "Bearer " + getCookie("token"),
                "content-type": "application/json"
            },
            success:function(data){
                console.log(JSON.stringify(data));
                $("#result_input").html(FormatOutputText(data[0].$));
            },
            error:function(err){
                console.log(err);
            }
        });
    });

    $("#hdfs_btn").click(function(){
        $.ajax({
            type:'get',
            
            url: RESTURL + '/GetFileFromHDFS?filename=' + $("#fileName_hdfs_input").val(),
            data:JSON.stringify({}),
            headers: {
                "authorization": "Bearer " + getCookie("token"),
                "content-type": "application/json"
            },
            success:function(data){
                console.log(data);
                $("#result_input").html(FormatOutputHDFS(data));
            },
            error:function(err){
                console.log(err);
            }
        });
    });

    $("#ipfs_btn").click(function(){
        $.ajax({
            type:'get',
            
            url: RESTURL + '/GetFileFromIPFS?filename=' + $("#fileName_ipfs_input").val(),
            data:JSON.stringify({}),
            headers: {
                "authorization": "Bearer " + getCookie("token"),
                "content-type": "application/json"
            },
            success:function(data){
                console.log(data);
                $("#result_input").html(FormatOutputHDFS(data));
            },
            error:function(err){
                console.log(err);
            }
        });
    });

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
    // get <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
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

function FormatOutputHDFS(data){
    var str = "<a href=../public/tmp/" + data + ">" + data + "</a>";
    return str;
}

function FormatOutputText(data){
    return "<p>" + data + "</p>"
}

function FormatOutputUsual(data){
    var jsonData = JSON.parse(data);
    // console.log(jsonData);

    var str = "";
    var keyName = "";
    for(var i = 0; i < jsonData.length; i++){
        str += "<p><label><b>序号： </b></label>" + (i+1) + "</p>";
        for(var key in jsonData[i]){
            if(key == "Key"){
                continue;
            }
            if(key == "TxId"){
                continue;
            }
            switch(key) {
                case "TxId":
                    keyName = "FabricTxID";
                    break;
                case "Timestamp":
                    keyName = "时间戳";
                    break;
                case "IsDelete":
                    keyName = "是否删除";
                    break;
                default:
                    break;
            }
            if(key == "Value" || key == "Record"){
                str += "<p><label><b>记录ID:</b></label>" + jsonData[i][key]["recordID"] + "</p>";
                if(!jsonData[i][key].hasOwnProperty("parentRecordID")){
                    str += "<p><label><b>交易ID:</b></label>" + jsonData[i][key]["parentTxID"] + "</p>";
                } else {
                    str += "<p><label><b>交易ID:</b></label>" + jsonData[i][key]["parentRecordID"] + "</p>";
                }
                for(var key2 in jsonData[i][key]){
                    switch(key2) {
                        case "signature":
                            keyName = "数字签名";
                            break;
                        // transaction
                        case "hash":
                            keyName = "数据哈希";
                            break;
                        case "parentRecordID":
                        case "parentTxID":
                            keyName = "交易ID";
                            break;
                        case "price":
                            keyName = "价格";
                            break;
                        case "addrrec":
                            keyName = "接收方地址";
                            break;
                        case "addrsend":
                            keyName = "发送方地址";
                            break;
                        case "storageType":
                            keyName = "存储类型";
                            break;
                        case "recordID":
                            keyName = "记录ID";
                            break;
                        // estate
                            // tx
                        case "HTH":
                            keyName = "合同号";
                            break;
                        case "FWSYQZH":
                            keyName = "房屋所有权证号";
                            break;
                        case "QYRQ":
                            keyName = "签约日期";
                            break;
                        case "JZMJ":
                            keyName = "建筑面积";
                            break;
                        case "DYQK":
                            keyName = "抵押情况";
                            break;
                        case "CJJG":
                            keyName = "成交价格（万元）";
                            break;
                        case "FWDZ":
                            keyName = "房屋地址";
                            break;
                        case "CMR":
                            keyName = "出卖人";
                            break;
                        case "MSR":
                            keyName = "买受人";
                            break;
                        case "QYJG":
                            keyName = "签约机构";
                            break;
                            // tax
                        case "GFHTH":
                            keyName = "购房合同号";
                            break;
                        case "FWSYQZH":
                            keyName = "房屋所有权证号";
                            break;
                        case "JZMJ":
                            keyName = "建筑面积";
                            break;
                        case "CJJG":
                            keyName = "成交价格（万元）";
                            break;
                        case "FWDZ":
                            keyName = "房屋地址";
                            break;
                        case "CQR":
                            keyName = "产权人";
                            break;
                        case "QS":
                            keyName = "契税（万元）";
                            break;
                        case "TDCRJ":
                            keyName = "土地出让金（万元）";
                            break;
                        case "GRSDS":
                            keyName = "个人所得税（万元）";
                            break;
                        case "YHS":
                            keyName = "印花税（万元）";
                            break;
                        case "GGWXJJ":
                            keyName = "公共维修基金（万元）";
                            break;
                            // reg
                        case "ZZBH":
                            keyName = "证照编号";
                            break;
                        case "KZ_BDCQZH":
                            keyName = "不动产权证号";
                            break;
                        case "CZZT":
                            keyName = "持证主体";
                            break;
                        case "KZ_QLRZJH":
                            keyName = "权利人证件号";
                            break;
                        case "ZZBFJG":
                            keyName = "证照颁发机构";
                            break;
                        case "ZZBFRQ":
                            keyName = "证照颁发日期";
                            break;
                        case "KZ_ZL":
                            keyName = "坐落";
                            break;
                        case "KZ_MJ":
                            keyName = "面积";
                            break; 
                        case "status":
                            keyName = "状态";
                            break;
                        case "taxType":
                            keyName = "税务类型";
                            break;
                        case "taxAmount":
                            keyName = "缴税金额（万）";
                            break;
                        default:
                            break;
                    }
                    if(keyName == "记录ID" || keyName == "交易ID"){
                        continue;
                    }

                    str += "<p><label><b>" + keyName + ":</b></label>" + jsonData[i][key][key2] + "</p>";
                    keyName = "null";
                }
            } else {
                str += "<p><label><b>" + keyName + ":</b></label>" + jsonData[i][key] + "</p>";
                keyName = "null";
            }
        }
    str += "<hr><p></p>"
    }
    return str;
}

function FormatOutputUsualWithUrl(data){
    var jsonData = JSON.parse(data);
    // console.log(jsonData);

    var str = "";
    var keyName = "";
    for(var i = 0; i < jsonData.length; i++){
        str += "<p><label><b>序号： </b></label>" + (i+1) + "</p>";
        for(var key in jsonData[i]){
            if(key == "Key"){
                continue;
            }
            if(key == "TxId"){
                continue;
            }
            switch(key) {
                case "TxId":
                    keyName = "FabricTxID";
                    break;
                case "Timestamp":
                    keyName = "时间戳";
                    break;
                case "IsDelete":
                    keyName = "是否删除";
                    break;
                default:
                    break;
            }
            if(key == "Value" || key == "Record"){
                str += "<p><label><b>记录ID:</b></label>" + jsonData[i][key]["recordID"] + "</p>";
                if(!jsonData[i][key].hasOwnProperty("parentRecordID")){
                    str += "<p><label><b>交易ID:</b></label>" + jsonData[i][key]["parentTxID"] + "</p>";
                } else {
                    str += "<p id=\"traceParentTxID\"><label><b>交易ID:</b></label><label id=\"traceParentTxIDContent\" style=\"color:blue\">" + jsonData[i][key]["parentRecordID"] + "</label></p>";
                }
                for(var key2 in jsonData[i][key]){
                    switch(key2) {
                        case "signature":
                            keyName = "数字签名";
                            break;
                        // transaction
                        case "hash":
                            keyName = "数据哈希";
                            break;
                        case "parentRecordID":
                        case "parentTxID":
                            keyName = "交易ID";
                            break;
                        case "price":
                            keyName = "价格";
                            break;
                        case "addrrec":
                            keyName = "接收方地址";
                            break;
                        case "addrsend":
                            keyName = "发送方地址";
                            break;
                        case "storageType":
                            keyName = "存储类型";
                            break;
                        case "recordID":
                            keyName = "记录ID";
                            break;
                        // estate
                            // tx
                        case "HTH":
                            keyName = "合同号";
                            break;
                        case "FWSYQZH":
                            keyName = "房屋所有权证号";
                            break;
                        case "QYRQ":
                            keyName = "签约日期";
                            break;
                        case "JZMJ":
                            keyName = "建筑面积";
                            break;
                        case "DYQK":
                            keyName = "抵押情况";
                            break;
                        case "CJJG":
                            keyName = "成交价格（万元）";
                            break;
                        case "FWDZ":
                            keyName = "房屋地址";
                            break;
                        case "CMR":
                            keyName = "出卖人";
                            break;
                        case "MSR":
                            keyName = "买受人";
                            break;
                        case "QYJG":
                            keyName = "签约机构";
                            break;
                            // tax
                        case "GFHTH":
                            keyName = "购房合同号";
                            break;
                        case "FWSYQZH":
                            keyName = "房屋所有权证号";
                            break;
                        case "JZMJ":
                            keyName = "建筑面积";
                            break;
                        case "CJJG":
                            keyName = "成交价格（万元）";
                            break;
                        case "FWDZ":
                            keyName = "房屋地址";
                            break;
                        case "CQR":
                            keyName = "产权人";
                            break;
                        case "QS":
                            keyName = "契税（万元）";
                            break;
                        case "TDCRJ":
                            keyName = "土地出让金（万元）";
                            break;
                        case "GRSDS":
                            keyName = "个人所得税（万元）";
                            break;
                        case "YHS":
                            keyName = "印花税（万元）";
                            break;
                        case "GGWXJJ":
                            keyName = "公共维修基金（万元）";
                            break;
                            // reg
                        case "ZZBH":
                            keyName = "证照编号";
                            break;
                        case "KZ_BDCQZH":
                            keyName = "不动产权证号";
                            break;
                        case "CZZT":
                            keyName = "持证主体";
                            break;
                        case "KZ_QLRZJH":
                            keyName = "权利人证件号";
                            break;
                        case "ZZBFJG":
                            keyName = "证照颁发机构";
                            break;
                        case "ZZBFRQ":
                            keyName = "证照颁发日期";
                            break;
                        case "KZ_ZL":
                            keyName = "坐落";
                            break;
                        case "KZ_MJ":
                            keyName = "面积";
                            break;
                        case "status":
                            keyName = "状态";
                            break;
                        case "taxType":
                            keyName = "税务类型";
                            break;
                        case "taxAmount":
                            keyName = "缴税金额（万）";
                            break;
                        default:
                            break;
                    }
                    if(keyName == "记录ID" || keyName == "交易ID"){
                        continue;
                    }

                    str += "<p><label><b>" + keyName + ":</b></label>" + jsonData[i][key][key2] + "</p>";
                    keyName = "null";
                }
            } else {
                str += "<p><label><b>" + keyName + ":</b></label>" + jsonData[i][key] + "</p>";
                keyName = "null";
            }
        }
    str += "<hr><p></p>"
    }
    return str;
}

function FormatOutputTable(data){
    var jsonData = JSON.parse(data);
    // console.log(jsonData);

    var str = "<tr>";
    var keyName = "";
    var txID="";
    for(var i = 0; i < jsonData.length; i++){
        str += "<td><b> 序号： </b>" + (i+1) + "</td>";
        for(var key in jsonData[i]){
            if(key == "Key"){
                keyName = "记录ID";
                txID = jsonData[i][key];
                str += "<td hidden=\"hidden\"><b> " + keyName + "：</b><span class=\"detailTxID\">" + jsonData[i][key] + "</span></td>";
                continue;
            }
            if(key == "TxId"){
                continue;
            }
            if(key == "Value" || key == "Record"){
                for(var key2 in jsonData[i][key]){
                    switch(key2) {
                        case "GFHTH":
                            keyName = "购房合同号";
                            str += "<td><b> " + keyName + "：</b>" + jsonData[i][key][key2] + "</td>";
                            keyName = "null";
                            break;
                        case "CQR":
                            keyName = "产权人";
                            str += "<td><b> " + keyName + "：</b>" + jsonData[i][key][key2] + "</td>";
                            keyName = "null";
                            break;
                        case "status":
                            keyName = "状态";
                            str += "<td><b> " + keyName + "：</b>" + jsonData[i][key][key2] + "</td>";
                            keyName = "null";
                            break;
                        default:
                            break;
                    }
                }
            } else {
                str += "<td><b> " + keyName + "：</b>" + jsonData[i][key][key2] + "</td>";
                keyName = "null";
            }
        }
        str += "<td class=\"detailLink\" id=\"" + txID + "\" style=\"cursor:pointer;color:blue\"> 详情 </td></tr>"
    }
    return str;
}

function FormatOutputTableDetail(data){
    var jsonData = JSON.parse(data);
    // console.log(jsonData);

    var str = "";
    var keyName = "";
    for(var i = 0; i < jsonData.length; i++){
        //str += "<tr><td><b>序号： </b>" + (i+1) + "</td></tr>";
        for(var key in jsonData[i]){
            if(key == "Key"){
                continue;
            }
            if(key == "TxId"){
                continue;
            }
            switch(key) {
                case "TxId":
                    keyName = "FabricTxID";
                    break;
                case "Timestamp":
                    keyName = "时间戳";
                    break;
                case "IsDelete":
                    keyName = "是否删除";
                    break;
                default:
                    break;
            }
            if(key == "Value" || key == "Record"){
                str += "<tr><td><b>记录ID：</b><span id=\"tax_parentID\">" + jsonData[i][key]["recordID"] + "</span></td></tr>";
                if(!jsonData[i][key].hasOwnProperty("parentRecordID")){
                    str += "<tr><td><b>交易ID： </b>" + jsonData[i][key]["parentTxID"]  + "</td></tr>";
                } else {
                    str += "<tr><td><b>交易ID： </b>" + jsonData[i][key]["parentRecordID"]  + "</td></tr>";
                }
                for(var key2 in jsonData[i][key]){
                    switch(key2) {
                        case "signature":
                            keyName = "数字签名";
                            break;
                        // transaction
                        case "hash":
                            keyName = "数据哈希";
                            break;
                        case "parentRecordID":
                        case "parentTxID":
                            keyName = "交易ID";
                            break;
                        case "price":
                            keyName = "价格";
                            break;
                        case "addrrec":
                            keyName = "接收方地址";
                            break;
                        case "addrsend":
                            keyName = "发送方地址";
                            break;
                        case "storageType":
                            keyName = "存储类型";
                            break;
                        case "recordID":
                            keyName = "记录ID";
                            break;
                        // estate
                            // tx
                        case "HTH":
                            keyName = "合同号";
                            break;
                        case "FWSYQZH":
                            keyName = "房屋所有权证号";
                            break;
                        case "QYRQ":
                            keyName = "签约日期";
                            break;
                        case "JZMJ":
                            keyName = "建筑面积";
                            break;
                        case "DYQK":
                            keyName = "抵押情况";
                            break;
                        case "CJJG":
                            keyName = "成交价格（万元）";
                            break;
                        case "FWDZ":
                            keyName = "房屋地址";
                            break;
                        case "CMR":
                            keyName = "出卖人";
                            break;
                        case "MSR":
                            keyName = "买受人";
                            break;
                        case "QYJG":
                            keyName = "签约机构";
                            break;
                            // tax
                        case "GFHTH":
                            keyName = "购房合同号";
                            break;
                        case "FWSYQZH":
                            keyName = "房屋所有权证号";
                            break;
                        case "JZMJ":
                            keyName = "建筑面积";
                            break;
                        case "CJJG":
                            keyName = "成交价格（万元）";
                            break;
                        case "FWDZ":
                            keyName = "房屋地址";
                            break;
                        case "CQR":
                            keyName = "产权人";
                            break;
                        case "QS":
                            keyName = "契税（万元）";
                            break;
                        case "TDCRJ":
                            keyName = "土地出让金（万元）";
                            break;
                        case "GRSDS":
                            keyName = "个人所得税（万元）";
                            break;
                        case "YHS":
                            keyName = "印花税（万元）";
                            break;
                        case "GGWXJJ":
                            keyName = "公共维修基金（万元）";
                            break;
                            // reg
                        case "ZZBH":
                            keyName = "证照编号";
                            break;
                        case "KZ_BDCQZH":
                            keyName = "不动产权证号";
                            break;
                        case "CZZT":
                            keyName = "持证主体";
                            break;
                        case "KZ_QLRZJH":
                            keyName = "权利人证件号";
                            break;
                        case "ZZBFJG":
                            keyName = "证照颁发机构";
                            break;
                        case "ZZBFRQ":
                            keyName = "证照颁发日期";
                            break;
                        case "KZ_ZL":
                            keyName = "坐落";
                            break;
                        case "KZ_MJ":
                            keyName = "面积";
                            break;
                        case "status":
                            keyName = "状态";
                            break;
                        case "taxType":
                            keyName = "税务类型";
                            break;
                        case "taxAmount":
                            keyName = "缴税金额（万）";
                            break;
                        default:
                            break;
                    }
                    if(keyName == "记录ID" || keyName == "交易ID"){
                        continue;
                    }
                    if(keyName == "持证主体"){
                        str += "<tr><td><b>持证主体：</b><span id=\"taxCZZT\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "证照编号"){
                        str += "<tr><td><b>证照编号：</b><span id=\"taxZZBH\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "合同号"){
                        str += "<tr><td><b>合同号：</b><span id=\"taxHTH\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "房屋所有权证号"){
                        str += "<tr><td><b>房屋所有权证号：</b><span id=\"taxFWSYQZH\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "房屋地址"){
                        str += "<tr><td><b>房屋地址：</b><span id=\"taxFWDZ\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "建筑面积"){
                        str += "<tr><td><b>建筑面积：</b><span id=\"taxJZMJ\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "成交价格（万元）"){
                        str += "<tr><td><b>成交价格（万元）：</b><span id=\"taxCJJG\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "出卖人"){
                        str += "<tr><td><b>出卖人：</b><span id=\"taxCMR\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "数据哈希"){
                        str += "<tr><td><b>数据哈希：</b><span id=\"dataHash\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }

                    str += "<tr><td><b>" + keyName + "：</b>" + jsonData[i][key][key2] + "</td></tr>";
                    keyName = "null";
                }
            } else {
                str += "<tr><td><b>" + keyName + "：</b>" + jsonData[i][key] + "</td></tr>";
                keyName = "null";
            }
        }
    str += "</tr>"
    }
    return str;
}

function FormatOutputTableDetail2(data){
    var jsonData = JSON.parse(data);
    // console.log(jsonData);

    var str = "";
    var keyName = "";
    for(var i = 0; i < jsonData.length; i++){
        //str += "<tr><td><b>序号： </b>" + (i+1) + "</td></tr>";
        for(var key in jsonData[i]){
            if(key == "Key"){
                continue;
            }
            if(key == "TxId"){
                continue;
            }
            switch(key) {
                case "TxId":
                    keyName = "FabricTxID";
                    break;
                case "Timestamp":
                    keyName = "时间戳";
                    break;
                case "IsDelete":
                    keyName = "是否删除";
                    break;
                default:
                    break;
            }
            if(key == "Value" || key == "Record"){
                str += "<tr><td><b>记录ID：</b><span id=\"tax_parentID\">" + jsonData[i][key]["recordID"] + "</span></td></tr>";
                if(!jsonData[i][key].hasOwnProperty("parentRecordID")){
                    str += "<tr><td><b>交易ID： </b>" + jsonData[i][key]["parentTxID"]  + "</td></tr>";
                } else {
                    str += "<tr><td><b>交易ID： </b>" + jsonData[i][key]["parentRecordID"]  + "</td></tr>";
                }
                for(var key2 in jsonData[i][key]){
                    switch(key2) {
                        case "signature":
                            keyName = "数字签名";
                            break;
                        // transaction
                        case "hash":
                            keyName = "数据哈希";
                            break;
                        case "parentRecordID":
                        case "parentTxID":
                            keyName = "交易ID";
                            break;
                        case "price":
                            keyName = "价格";
                            break;
                        case "addrrec":
                            keyName = "接收方地址";
                            break;
                        case "addrsend":
                            keyName = "发送方地址";
                            break;
                        case "storageType":
                            keyName = "存储类型";
                            break;
                        case "recordID":
                            keyName = "记录ID";
                            break;
                        // estate
                            // tx
                        case "HTH":
                            keyName = "合同号";
                            break;
                        case "FWSYQZH":
                            keyName = "房屋所有权证号";
                            break;
                        case "QYRQ":
                            keyName = "签约日期";
                            break;
                        case "JZMJ":
                            keyName = "建筑面积";
                            break;
                        case "DYQK":
                            keyName = "抵押情况";
                            break;
                        case "CJJG":
                            keyName = "成交价格（万元）";
                            break;
                        case "FWDZ":
                            keyName = "房屋地址";
                            break;
                        case "CMR":
                            keyName = "出卖人";
                            break;
                        case "MSR":
                            keyName = "买受人";
                            break;
                        case "QYJG":
                            keyName = "签约机构";
                            break;
                            // tax
                        case "GFHTH":
                            keyName = "购房合同号";
                            break;
                        case "FWSYQZH":
                            keyName = "房屋所有权证号";
                            break;
                        case "JZMJ":
                            keyName = "建筑面积";
                            break;
                        case "CJJG":
                            keyName = "成交价格（万元）";
                            break;
                        case "FWDZ":
                            keyName = "房屋地址";
                            break;
                        case "CQR":
                            keyName = "产权人";
                            break;
                        case "QS":
                            keyName = "契税（万元）";
                            break;
                        case "TDCRJ":
                            keyName = "土地出让金（万元）";
                            break;
                        case "GRSDS":
                            keyName = "个人所得税（万元）";
                            break;
                        case "YHS":
                            keyName = "印花税（万元）";
                            break;
                        case "GGWXJJ":
                            keyName = "公共维修基金（万元）";
                            break;
                            // reg
                        case "ZZBH":
                            keyName = "证照编号";
                            break;
                        case "KZ_BDCQZH":
                            keyName = "不动产权证号";
                            break;
                        case "CZZT":
                            keyName = "持证主体";
                            break;
                        case "KZ_QLRZJH":
                            keyName = "权利人证件号";
                            break;
                        case "ZZBFJG":
                            keyName = "证照颁发机构";
                            break;
                        case "ZZBFRQ":
                            keyName = "证照颁发日期";
                            break;
                        case "KZ_ZL":
                            keyName = "坐落";
                            break;
                        case "KZ_MJ":
                            keyName = "面积";
                            break;
                        case "status":
                            keyName = "状态";
                            break;
                        case "taxType":
                            keyName = "税务类型";
                            break;
                        case "taxAmount":
                            keyName = "缴税金额（万）";
                            break;
                        default:
                            break;
                    }
                    if(keyName == "记录ID" || keyName == "交易ID"){
                        continue;
                    }
                    if(keyName == "持证主体"){
                        str += "<tr><td><b>持证主体：</b><span id=\"taxCZZT\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "证照编号"){
                        str += "<tr><td><b>证照编号：</b><span id=\"taxZZBH\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "合同号"){
                        str += "<tr><td><b>合同号：</b><span id=\"taxHTH\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "房屋所有权证号"){
                        str += "<tr><td><b>房屋所有权证号：</b><span id=\"taxFWSYQZH\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "房屋地址"){
                        str += "<tr><td><b>房屋地址：</b><span id=\"taxFWDZ\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "建筑面积"){
                        str += "<tr><td><b>建筑面积：</b><span id=\"taxJZMJ\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "成交价格（万元）"){
                        str += "<tr><td><b>成交价格（万元）：</b><span id=\"taxCJJG\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "出卖人"){
                        str += "<tr><td><b>出卖人：</b><span id=\"taxCMR\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }
                    if(keyName == "状态"){
                        str += "<tr><td><b>状态：</b><span> 已纳税 </span></td></tr>";
                        continue;
                    }
                    if(keyName == "数据哈希"){
                        str += "<tr><td><b>数据哈希：</b><span id=\"dataHash\">" + jsonData[i][key][key2] + "</span></td></tr>";
                        continue;
                    }

                    str += "<tr><td><b>" + keyName + "：</b>" + jsonData[i][key][key2] + "</td></tr>";
                    keyName = "null";
                }
            } else {
                str += "<tr><td><b>" + keyName + "：</b>" + jsonData[i][key] + "</td></tr>";
                keyName = "null";
            }
        }
    str += "</tr>"
    }
    return str;
}

function FormatOutputTableDetailButton(){
    str = "";
    str += " \
        <p><span style=\"color:#255e95;font-size:26px;font-weight:bold\">完税信息</span></p> \
        <p> \
            <label for=\"type_op1_tax_label\">税务类型:</label> \
            <input type=\"text\" id=\"type_op1_tax_input\"> \
        </p> \
        <p> \
            <label for=\"amount_op1_tax_label\">缴税金额（万）:</label> \
            <input type=\"text\" id=\"amount_op1_tax_input\" value=\"10\"> \
        </p> \
        <p><label for=\"Prvkey_put_label\">签名密钥（本地签名，不上传）:</label><input type=\"file\" id=\"Prvkey_put_input\"></p> \
        <p><label for=\"Pubkey_put_label\">身份证书:</label><input type=\"file\" id=\"Pubkey_put_input\"></p> \
        <p><button type=\"button\" id=\"tax_commit_btn\">提交</button></p> \
    ";
    return str;
}

function FormatOutputTableTaxButton(){
    var HTH = $("#taxHTH")[0].innerHTML;
    var FWSYQZH = $("#taxFWSYQZH")[0].innerHTML;
    var JZMJ = $("#taxJZMJ")[0].innerHTML;
    var CJJG = $("#taxCJJG")[0].innerHTML;
    var FWDZ = $("#taxFWDZ")[0].innerHTML;
    var CQR = $("#taxCMR")[0].innerHTML;
    var QS = $("#QS_op1_put_input").val();
    var TDCRJ = $("#TDCRJ_op1_put_input").val();
    var GRSDS = $("#GRSDS_op1_put_input").val();
    var YHS = $("#YHS_op1_put_input").val();
    var GGWXJJ = $("#GGWXJJ_op1_put_input").val();
    var parentRecordID = $("#tax_parentID")[0].innerHTML;

    str = "";
    str += " \
        <p><span style=\"color:#255e95;font-size:26px;font-weight:bold\">完税信息</span></p> \
        <p> \
            <label for=\"GFHTH_op1_put_label\">购房合同号:</label> \
            <input type=\"text\" id=\"GFHTH_op1_put_input\" value=\"" + HTH + "\"> \
        </p> \
        <p> \
            <label for=\"FWSYQZH_op1_put_label\">房屋所有权证号:</label> \
            <input type=\"text\" id=\"FWSYQZH_op1_put_input\" value=\"" + FWSYQZH + "\"> \
        </p> \
        <p> \
            <label for=\"JZMJ_op1_put_label\">建筑面积:</label> \
            <input type=\"text\" id=\"JZMJ_op1_put_input\" value=\"" + JZMJ + "\"> \
        </p> \
        <p> \
            <label for=\"CJJG_op1_put_label\">成交价格（万元）:</label> \
            <input type=\"text\" id=\"CJJG_op1_put_input\" value=\"" + CJJG + "\"> \
        </p> \
        <p> \
            <label for=\"FWDZ_op1_put_label\">房屋地址:</label> \
            <input type=\"text\" id=\"FWDZ_op1_put_input\" value=\"" + FWDZ + "\"> \
        </p> \
        <p> \
            <label for=\"CQR_op1_put_label\">产权人:</label> \
            <input type=\"text\" id=\"CQR_op1_put_input\" value=\"" + CQR + "\"> \
        </p> \
        <p> \
            <label for=\"QS_op1_put_label\">契税（万元）:</label> \
            <input type=\"text\" id=\"QS_op1_put_input\" value=\"1\"> \
        </p> \
        <p> \
            <label for=\"TDCRJ_op1_put_label\">土地出让金（万元）:</label> \
            <input type=\"text\" id=\"TDCRJ_op1_put_input\" value=\"1\"> \
        </p> \
        <p> \
            <label for=\"GRSDS_op1_put_label\">个人所得税（万元）:</label> \
            <input type=\"text\" id=\"GRSDS_op1_put_input\" value=\"0\"> \
        </p> \
        <p> \
            <label for=\"YHS_op1_put_label\">印花税（万元）:</label> \
            <input type=\"text\" id=\"YHS_op1_put_input\" value=\"0.1\"> \
        </p> \
        <p> \
            <label for=\"GGWXJJ_op1_put_label\">公共维修基金（万元）:</label> \
            <input type=\"text\" id=\"GGWXJJ_op1_put_input\" value=\"1\"> \
        </p> \
        <p hidden=\"hidden\"> \
            <label for=\"ParentID_op1_put_label\">父交易ID（无父交易请空白）:</label> \
            <textarea id=\"ParentID_op1_put_input\" rows=\"3\" cols=\"38\" style=\"vertical-align: top;\"></textarea> \
        </p> \
        <p> \
            <label for=\"Image_op1_put_label\">选择图片（选填）:</label> \
            <input type=\"file\" id=\"Image_op1_put_input\"> \
        </p> \
        <p style=\"margin-right:100px\"> \
            <label for=\"Stroage_op0_put_label\">存储方式:</label> \
            <input type=\"radio\" id=\"hdfs_op0_put_label\" name=\"storageType\" value=\"hdfs\" style=\"width:20px; height:15px\" checked=\"checked\">HDFS \
            <input type=\"radio\" id=\"onchain_op0_put_label\" name=\"storageType\" value=\"onchain\" style=\"width:20px; height:15px\">onchain \
            <input type=\"radio\" id=\"hbase_op0_put_label\" name=\"storageType\" value=\"hbase\" style=\"width:20px; height:15px\">HBase \
        </p> \
        <p><label for=\"Prvkey_put_label\">签名密钥（本地签名，不上传）:</label><input type=\"file\" id=\"Prvkey_put_input\"></p> \
        <p><label for=\"Pubkey_put_label\">身份证书:</label><input type=\"file\" id=\"Pubkey_put_input\"></p> \
        <p><button type=\"button\" id=\"tax_commit_btn\">提交</button></p> \
    ";
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
