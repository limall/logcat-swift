// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.

//用于debug，打印日志信息
let DEBUG=true;
let printer=require('./printer.js');
printer.resetDst('127.0.0.1',20130,20);
function log(msg){
    if(DEBUG)
        printer.si(msg);
}

let MASTHEAD_HEADOFLOG = 0;
let MASTHEAD_BODYOFLOG = 1;
let MASTHEAD_RESETLOGID = 2;
let BLOCK_LEN = 128;

let dgram = require('dgram');
let logSocket = dgram.createSocket('udp4');
let filter=require('./filter.js');
var loggers={objs:[]};
var filters={};
logSocket.bind(20131);

logSocket.on('message', function(msg, rinfo){
    var i=0;
    
    let masthead=msg[0];

    var logid=0;
    for(;i<4;i++){
        logid+=msg[i+1]<<(8 * (4 - i - 1));
    }
    
    if(masthead==MASTHEAD_RESETLOGID){
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

    var thissize=totalsize;
    if(thissize>BLOCK_LEN)
        thissize=BLOCK_LEN;

    var block=new Buffer(thissize);
    for(var i=12;i<thissize+12;i++){
        block[i-12]=msg[i];
    }

    loggers[logid]=loggers[logid]||{};
    loggers[logid][id]=loggers[logid][id]||new OneLog(totalsize);
    
    var logBuffer=loggers[logid][id].addData(block,order);
    if(logBuffer){
        try {
            var obj=JSON.parse(logBuffer.toString('utf8'));
            if(obj){
                obj.logid=''+logid;
                loggers.objs.push(obj);
                log(JSON.stringify(obj));
            }else
                return;
            let filtered=filterAll([obj]);
            if(filtered.length>0)
                showOneLog(obj);
        } catch (error) {
            console.log(err);
        }
    }
});

function refresh(){
    $(".logItem").remove();
    let srcs=filterAll(loggers.objs);
    srcs.forEach(function(src){
        showOneLog(src);
    });
}

function filterAll(srcs){
    var filtered=srcs;
    if(filters.level)
        filtered=filter.filterLevel(filtered,filters.level);
    if(filtered.length>0&&filters.msg)
        filtered=filter.filterMsg(filtered,filters.msg);
    if(filtered.length>0&&filters.general)
        filtered=filter.filter(filtered,filters.general);
    return filtered;
}

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

function getHtmlStr(obj,level,stress){
    let HTML1 = '<tr class="logItem '+level+'">';
    let HTML2 = '</tr>';
    let HTMLA='<td>';
    let HTMLB='</td>';

    var str=HTML1;
    str+=HTMLA+ new Date(obj.time*1000).toLocaleString()+HTMLB;
    str+=HTMLA+obj.level+HTMLB;
    str+=HTMLA+obj.tag+HTMLB;
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
