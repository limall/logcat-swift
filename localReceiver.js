var net =require('net');
var fs=require('fs')

var BLOCK_LEN=128

//设置连接口令，预防简单的ddos攻击,口令为9位十进制数字
var key=396792774
var argv=process.argv.splice(2)
if(argv&&argv!='')
    key=Number(argv)

function createFolder(path){
    var exist=fs.existsSync(path)
    if(!exist)
        fs.mkdirSync(path,{recursive:true})
}

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

//所有数据块缓存到saveCache中，每过500毫秒将缓存保存起来并清空。
var saveCache=[]
//通过isSaving保证缓存保存好后才能处理下一次缓存
var isSaving=false
function BlockCache(path,data){
    this.path=path
    this.data=data
}
function save(){
    if(isSaving)
        return
    else
        isSaving=true

    var cache=[]
    for(var i=0;i<saveCache.length;i++){
        cache[i]=saveCache[i]
    }
    if(cache.length==0){
        isSaving=false
        return
    }    
    saveCache=[]

    var index=0
    var callBack=function(err){
        if(err)
            console.log('error ccours when append file:'+cache[index].path+',error:'+err.toString())
        else{
            index++
            if(index<cache.length)
                fs.appendFile(cache[index].path,cache[index].data,callBack)
            else{
                console.log("cache saved,length:"+cache.length)
                isSaving=false
            }    
        }
    }
    fs.appendFile(cache[index].path,cache[index].data,callBack)
}
setInterval(function(){
    save()
},500)

//因为socket可能将多次收到的数据合并后再触发，于是设计该函数
function handleBlock(data,parentFolder,socket){
    if(data.length<=12){
        console.log('find lawless connection,address:'+socket.address().address)
        socket.destroy()
        return
    }

    var getKey=0
    for(var i=0;i<4;i++){
        getKey+=data[i]<<(8*(4-i-1))
    }
    if(getKey!=key){
        console.log('find lawless connection,address:'+socket.address().address)
        socket.destroy()
        return
    }

    var folderName=0
    for(var i=0;i<3;i++){
        folderName+=data[i+4]<<(8*(3-i-1))
    }

    var fileName=0
    for(var i=0;i<4;i++){
        fileName+=data[i+7]<<(8*(4-i-1))
    }

    var blockLen=data[11]
    var block=Buffer.alloc(blockLen)
    for(var i=0;i<blockLen;i++){
        block[i]=data[i+12]
    }

    var folderPath='./'+parentFolder+'/'+folderName
    createFolder(folderPath)
    var path=folderPath+'/'+fileName
    saveCache.push(new BlockCache(path,block))

    if(data.length>BLOCK_LEN+12){
        var nextData=Buffer.alloc(data.length-12-BLOCK_LEN)
        for(var i=0;i<nextData.length;i++)
            nextData[i]=data[i+BLOCK_LEN+12]
        return nextData
    }
}

var server=net.createServer();
server.listen(11230,function(){
    console.log('local receiver listening 11230');
});
server.on('error',function(){
    console.log('server error!');
});
server.on('close',function(){
    console.log('server close!');
});
server.on('connection',function(socket){
    console.log("connecting address:"+socket.remoteAddress);

    var parentFolder=getId()+''
    packs[parentFolder]=Buffer.alloc(0)

    socket.on('data',function(data){
        var block=getBlock(data,parentFolder)
        if(block){
            var next=handleBlock(block,parentFolder,socket)
            while (next){
                next=handleBlock(next,parentFolder,socket)
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