// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// All of the Node.js APIs are available in this process.

let filter=require('./filter.js');
const ipc = require('electron').ipcRenderer
const fs=require('fs')
var net =require('net');

let MASTHEAD_HEADOFLOG = 0;
let MASTHEAD_BODYOFLOG = 1;
let MASTHEAD_RESETLOGID = 2;
let BLOCK_LEN = 128;

//存放日志对象，以及缓存接收来的数据块
var loggers={objs:[]};

//存放过滤关键字
var filters={};

var server=net.createServer();
server.listen(20131,function(){
    console.log('listening 20131');
});
server.on('error',function(){
    console.log('server error!');
});
server.on('close',function(){
    console.log('server close!');
});

//每个连接都有个id来区别连接
var _id=0
function getId(){
    _id++
    return _id
}

//用来处理分包
var packs={}
function getBlock(data,connectionId){
    var leftLen=packs[connectionId].length
    var addLen=data.length
    var nowLen=leftLen+addLen
    if(nowLen>=140){
        leftLen=nowLen%140
        var blockLen=nowLen-leftLen
        var nowData=Buffer.concat([packs[connectionId],data])
        var block=Buffer.alloc(blockLen)
        packs[connectionId]=Buffer.alloc(leftLen)
        for(var i=0;i<blockLen;i++)
            block[i]=nowData[i]
        for(var i=blockLen;i<nowLen;i++)
            packs[connectionId][i-blockLen]=nowData[i]
        return block
    }else
        packs[connectionId]=Buffer.concat([packs[connectionId],data])
}

//该函数可以处理粘包
//block的前8位为是否是开头，接下来就是32位logid,接下来是32位id，接下来是16位总长度，接下来是8位order，接下来是128byte的数据。
//logid用来分辨发送设备，当有多个设备发送信息时，记得要将这些设备设置不同的logid
function handleBlock(data,parentFolder){
    let masthead=data[0];

    var i=0;

    var logid=0;
    for(;i<4;i++){
        logid+=data[i+1]<<(8 * (4 - i - 1));
    }
    if(masthead==MASTHEAD_RESETLOGID){
        console.log("recieve message to reset logid:"+logid);
        if(loggers[logid]){
            delete loggers[logid];
            console.log("delete logid:"+logid);
        }
    }else{
        var id=0;
        for(i=0;i<4;i++){
            id+=data[i+5]<<(8 * (4 - i - 1));
        }

        var totalsize=0;
        for(i=0;i<2;i++){
            totalsize+=data[i+9]<<(8 * (2 - i - 1));
        }

        let order=data[11];

        var thissize=BLOCK_LEN;
        var block=Buffer.alloc(thissize);
        for(var i=0;i<thissize;i++)
            block[i]=data[i+12]
    
        loggers[logid]=loggers[logid]||{};
        //当单个日志信息超过120byte时，发送端会把信息分拆后发送，所以这里需要使用OneLog对分拆的信息进行整合
        loggers[logid][id]=loggers[logid][id]||new OneLog(totalsize);
        var logBuffer=loggers[logid][id].addData(block,order);

        if(logBuffer){
            try {
                const msgStr=logBuffer.toString('utf8')
                var obj=JSON.parse(msgStr);

                if(obj){
                    obj.logid=''+logid;
                    loggers.objs.push(obj);
                    delete loggers[logid][id];

                    let filtered=filterAll([obj]);
                    if(filtered.length>0)
                    showOneLog(obj);
                }else{
                    console.log('got lawless msg:'+msgStr);
                    return;
                }     
            } catch (error) {
                console.log(error.toString())
            }
        }
    }

    if(data.length>BLOCK_LEN+12){
        var nextData=Buffer.alloc(data.length-12-BLOCK_LEN)
        for(var i=0;i<nextData.length;i++)
            nextData[i]=data[i+BLOCK_LEN+12]
        return nextData
    }
}

server.on('connection',function(socket){
    console.log("connecting address:"+socket.remoteAddress);

    var connectionId=getId()+''
    packs[connectionId]=Buffer.alloc(0)

    socket.on('data',function(data){
        var block=getBlock(data,connectionId)
        if(block){
            var next=handleBlock(block,connectionId,socket)
            while (next){
                next=handleBlock(next,connectionId,socket)
            }
        }    
    });
    socket.on('error',function(){
        console.log('socket error!');
    });
    socket.on('close',function(){
        console.log('client disconnected!');
    });
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
    str+=HTMLA+obj.tag+HTMLB;
    str+=HTMLA+obj.place+HTMLB;
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

function processFileLogs(path){
    fs.readFile(path,function(err,data){
        if(err){
            console.log('error occurs when read from file,error:'+err)
        }else{
            var originStr=data.toString('utf8')
            var end=originStr.lastIndexOf('}')+1;
            var str='['+originStr.substring(0,end)+']'
            var objs=JSON.parse(str)
            loggers.objs=[]
            objs.forEach(function(obj){
                loggers.objs.push(obj)
            })
            refresh()
        }
    })
}
ipc.on('selected-file',function(event,paths){
    console.log("ipc callback")
    processFileLogs(paths[0])
})

//为交互控件设置事件处理
$("#clear").click(function(event){
    loggers.objs=[];
    refresh();
});
$("#openFile").click(function(event){
    ipc.send('select-file');
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
