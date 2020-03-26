// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.

//for debug
let DEBUG=false;
let printer=require('./printer.js');
printer.resetDst('127.0.0.1',20130,20);
function log(msg){
    if(DEBUG)
        printer.si(msg);
}

let filter=require('./filter.js');
let dgram = require('dgram');

let MASTHEAD_HEADOFLOG = 0;
let MASTHEAD_BODYOFLOG = 1;
let MASTHEAD_RESETLOGID = 2;
let BLOCK_LEN = 128;

//存放日志对象，以及缓存接收来的数据块
var loggers={objs:[]};

//存放过滤关键字
var filters={};

let logSocket = dgram.createSocket('udp4');
logSocket.bind(20131);

//消息的前8位为是否是开头，接下来就是32位logid,接下来是32位id，接下来是16位总长度，接下来是8位order，接下来是128byte的数据。
//logid用来分辨发送设备，当有多个设备发送信息时，记得要将这些设备设置不同的logid
logSocket.on('message', function(msg, rinfo){
    log("get msg length:"+msg.length)
    let masthead=msg[0];

    var i=0;

    var logid=0;
    for(;i<4;i++){
        logid+=msg[i+1]<<(8 * (4 - i - 1));
    }
    if(masthead==MASTHEAD_RESETLOGID){
        log("recieve message to reset logid:"+logid);
        if(loggers[logid]){
            delete loggers[logid];
            log("delete logid:"+logid);
        }
        return;
    }

    var id=0;
    for(i=0;i<4;i++){
        id+=msg[i+5]<<(8 * (4 - i - 1));
    }

    var totalsize=0;
    for(i=0;i<2;i++){
        totalsize+=msg[i+9]<<(8 * (2 - i - 1));
    }

    let order=msg[11];

    var thissize=msg.length-12;
    var block=new Buffer(thissize);
    for(var i=12;i<thissize+12;i++){
        block[i-12]=msg[i];
    }
    
    loggers[logid]=loggers[logid]||{};
    //当单个日志信息超过120byte时，发送端会把信息分拆后发送，所以这里需要使用OneLog对分拆的信息进行整合
    loggers[logid][id]=loggers[logid][id]||new OneLog(totalsize);
    var logBuffer=loggers[logid][id].addData(block,order);

    if(logBuffer){
        try {
            var obj=JSON.parse(logBuffer.toString('utf8'));

            if(obj){
                obj.logid=''+logid;
                loggers.objs.push(obj);
                log(JSON.stringify(obj));
                delete loggers[logid][id];

                let filtered=filterAll([obj]);
                if(filtered.length>0)
                    showOneLog(obj);
            }else
                return;
        } catch (error) {
            log(error.toString())
        }
    }
});

//对分拆的信息进行整合
function OneLog(totalsize){
    this.totalsize=totalsize;
    this.gotData=[];
    this.got=0;
    this.addData=function(buffer,order){
        if(this.gotData[order])
            return;
        else{
            this.gotData[order]=buffer;
            this.got+=buffer.length;
            if(this.got>=this.totalsize){
                return Buffer.concat(this.gotData,this.totalsize);
            }
        }
    }
}

//应用所有过滤条件对日志对象进行过滤
function filterAll(srcs){
    var filtered=srcs;
    if(filters.level)
        filtered=filter.filterLevel(filtered,filters.level);
    if(filtered.length>0&&filters.msg)
        filtered=filter.filterMsg(filtered,filters.msg);
    //因为tag与logid进行筛选时逻辑一样，所以这里把它们放到general中，在一个函数中过滤了
    if(filtered.length>0&&filters.general)
        filtered=filter.filter(filtered,filters.general);
    return filtered;
}

//通过往index.html中插入文本来打印一个log
function showOneLog(obj){
    var html;
    switch(obj.level){
        case 'i':
        html=getIStr(obj,obj.stress);
        break;
        case 'd':
        html=getDStr(obj,obj.stress);
        break;
        case 'w':
        html=getWStr(obj,obj.stress);
        break;
        case 'e':
        html=getEStr(obj,obj.stress);
        break;
    }
    $("#log").prepend(html);
}

function getIStr(obj,stress){
    return getHtmlStr(obj,'success',stress);
}

function getDStr(obj,stress){
    return getHtmlStr(obj,'info',stress);
}

function getWStr(obj,stress){
    return getHtmlStr(obj,'warning',stress);
}

function getEStr(obj,stress){
    return getHtmlStr(obj,'danger',stress);
}

function getHtmlStr(obj,level,stress){
    let HTML1 = '<tr class="logItem '+level+'">';
    let HTML2 = '</tr>';
    let HTMLA='<td>';
    let HTMLB='</td>';

    var str=HTML1;
    str+=HTMLA+ new Date(obj.time*1000).toLocaleString()+HTMLB;
    str+=HTMLA+obj.level+HTMLB;
    str+=HTMLA+obj.tag+HTMLB;
    //当在search输入框中输入key时，在打印的日志中红色显示搜索到的key
    if(stress){
        var a='';
        let msg1=obj.msg.substring(0,stress.start);
        let msg2=obj.msg.substring(stress.start,stress.end);
        let msg3=obj.msg.substring(stress.end);
        str+=HTMLA+msg1+'<font color="red">'+msg2+'</font>'+msg3+HTMLB;
    }else
        str+=HTMLA+obj.msg+HTMLB;
    str+=HTML2;
    return str;
}

//刷新页面
function refresh(){
    $(".logItem").remove();
    let srcs=filterAll(loggers.objs);
    srcs.forEach(function(src){
        showOneLog(src);
    });
}

//为交互控件设置事件处理
$("#clear").click(function(event){
    loggers.objs=[];
    refresh();
});
$("#i").click(function(event){
    $("#level").html('Level:i&nbsp&nbsp<span class="caret"></span>');
    filters.level='i';
    refresh();
});
$("#d").click(function(event){
    $("#level").html('Level:d&nbsp&nbsp<span class="caret"></span>');
    filters.level='d';
    refresh();
});
$("#w").click(function(event){
    $("#level").html('Level:w&nbsp&nbsp<span class="caret"></span>');
    filters.level='w';
    refresh();
});
$("#e").click(function(event){
    $("#level").html('Level:e&nbsp&nbsp<span class="caret"></span>');
    filters.level='e';
    refresh();
});
$("#tag").keyup(function(){    
    var tag = $("#tag").val();    
    if(filters.general)
        filters.general.tag=tag;
    else
        filters.general={tag:tag};
    refresh();  
});
$("#logid").keyup(function(){    
    var logid = $("#logid").val();    
    if(filters.general)
        filters.general.logid=logid;
    else
        filters.general={logid:logid};
    refresh();  
});
$("#search").keyup(function(){    
    var msg = $("#search").val();    
    filters.msg=msg;
    if(!msg)
        loggers.objs.forEach(function(obj){
            if(obj.stress)
                delete obj.stress;
        });
    refresh();  
});
