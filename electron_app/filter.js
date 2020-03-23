
//for debug
let DEBUG=true;
let printer=require('./printer.js');
printer.resetDst('127.0.0.1',20130,20);
function log(msg){
    if(DEBUG)
        printer.si(msg);
}

module.exports.filter=function(srcs,filters){
    var newArray=[];
    srcs.forEach(function(src){
        for(var filtername in filters){
            log('filtername:'+filtername);
            log('src:'+src[filtername]);
            log('filter:'+filters[filtername]);
            if(src[filtername].indexOf(filters[filtername])<0)
                return;
        }
        newArray.push(src);
    });
    return newArray;
}
module.exports.filterLevel=function(srcs,level){
    var levelPower={
        i:1,
        d:2,
        w:3,
        e:4
    };
    var newArray=[];
    srcs.forEach(function(src){
        if(levelPower[src.level]>=levelPower[level])
            newArray.push(src);
    });
    return newArray;
}
module.exports.filterMsg=function(srcs,str){
    var newArray=[];
    srcs.forEach(function(src){
        let index=src.msg.indexOf(str);
        if(index<0){
            if(src.stress)
                delete src.stress;
            return;
        }else{
            src.stress={start:index,end:index+str.length};
            newArray.push(src);
        }  
    });
    log(JSON.stringify(newArray));
    return newArray;
}
