//
//  MsgSender.swift
//  Logcat_iosProj
//
//  Created by 左启凡 on 2020/3/24.
//  Copyright © 2020 zqf. All rights reserved.
//

import Foundation
import Network

public class Logcat{
    private enum Masthead:Int {
        case headOfLog=0
        case bodyOfLog=1
        case resetLogId=2
    }
    //日志打印的去向，None不作任何操作，Udp发送至打印端，Local存储至本地
    public enum OutputKind{
        case None
        case Udp
        case Local
    }
    
    public enum OutputLevel:Int{
        case information=0
        case debug
        case warning
        case error
    }
    
    private static var outputLevel=OutputLevel.information
    private static let BLOCK_LEN=128
    public static var outputKind=OutputKind.Udp
    //identify a device which sends log message
    public static var logId:UInt32=0
    //identify one log message
    private static var _id:UInt32=0
    private static var connection:NWConnection?
    private static var dispatchQueue=DispatchQueue(label: "com.logcat-swift")
    
    //create a global single id for one message
    internal static func getSingleId()->UInt32{
        var toReturn:UInt32=0
        objc_sync_enter(self)
        toReturn=_id
        _id += 1
        objc_sync_exit(self)
        return toReturn
    }
    
    //init NWConnect to prepare for sending message
    private static func initConnection(toHost:NWEndpoint.Host,toPort:NWEndpoint.Port){
        connection=NWConnection(host: toHost, port: toPort, using: .tcp)
        connection!.stateUpdateHandler = { (newState) in
            switch (newState) {
                case .ready:
                    debugPrint("logcat:NWConnection ready")
                case .setup:
                    debugPrint("logcat:NWConnection setup")
                case .cancelled:
                    debugPrint("logcat:NWConnection cancelled")
                case .preparing:
                    debugPrint("logcat:NWConnection preparing")
                default:
                    print("logcat:ERROR! State not defined!\n")
            }
        }
        connection!.start(queue: .global())
    }
    
    //send a block of one log message,固定总长度为140
//block前8位为是否是开头，接下来就是32位logid,接下来是32位id，接下来是16位总长度，接下来是8位order，接下来是128byte的数据。
    private static func sendBlock(block:Data,isBegin:Bool,id:UInt32,totoalLength:UInt16,order:UInt8){
        //add head description
        var buffer=Data(count: 12)
        buffer[0] = isBegin ? UInt8(Masthead.headOfLog.rawValue) : UInt8(Masthead.bodyOfLog.rawValue)
        let mask:UInt32=0xff
        for i in 0..<4{
            buffer[i+1]=UInt8(UInt32(logId>>(8*(4-i-1)))&mask)
        }
        for i in 0..<4{
            buffer[i+5]=UInt8(UInt32(id>>(8*(4-i-1)))&mask)
        }
        buffer[9]=UInt8(totoalLength>>8)
        buffer[10]=UInt8(UInt32(totoalLength)&mask)
        buffer[11]=order
        
        buffer.append(block)
        
        if block.count<BLOCK_LEN{
            let tail=Data(count: BLOCK_LEN+12-buffer.count)
            buffer.append(tail)
        }
        
        connection!.send(content: buffer, completion: NWConnection.SendCompletion.contentProcessed({(NWError)in
            if NWError != nil{
                print("logcat:error:send block failure,id:\(id),order:\(order)")
            }
        }))
    }
    
    //send one log message
    private static func sendMsg(msg:String){
        if let msgBuffer=msg.data(using: String.Encoding.utf8){
            let id=getSingleId()
            let size=msgBuffer.count
            var start=0
            var order=0
            while start<size {
                var length=size-start
                if length>BLOCK_LEN{
                    length=BLOCK_LEN
                }
                var buf=Data(count: length)
                for i in 0..<length{
                    buf[i]=msgBuffer[i+start]
                }
                let isBegin = start==0
                start += length
                sendBlock(block: buf, isBegin: isBegin, id: id, totoalLength: UInt16(size), order: UInt8(order))
                order += 1
            }
        }else{
            print("logcat:error:send invalid message")
        }
        
    }
    
    private struct Msg:Codable{
        let msg:String
        let tag:String
        let level:String
        let time:UInt
        let place:String
    }
    
    //encapsulation log message into a Json string
    private static func makeJsonStr(msg:String,tag:String,level:String,time:UInt,place:String)->String{
        let msgStruct=Msg(msg: msg, tag: tag, level: level, time: time,place:place)
        let encoder=JSONEncoder()
        var str=""
        do{
            let data = try encoder.encode(msgStruct)
            if let _str=String(data: data, encoding: .utf8){
                str=_str
            }else{
                print("logcat:Error occurs when get string from encode")
            }
        }catch{
            print("logcat:Error occurs when encode msg,error:\(error)")
        }
        return str
    }
    
    private static func saveMsg(msg:String){
        LocalSaver.singleInstance.addSaveCache(msg: msg)
    }
    
    //从#file字符串找截取fileName
    private static func getFileName(filePath:String)->String{
        if let index=filePath.lastIndex(of: "/"){
            let startIndex=filePath.index(index, offsetBy: 1)
            let sub=filePath.suffix(from: startIndex)
            let fileName=String(sub)
            return fileName
        }else{
            return filePath
        }
    }
    //从#function中截取functionName
    private static func getFuncName(funcId:String)->String{
        if let index=funcId.firstIndex(of: "("){
            let sub=funcId.prefix(upTo: index)
            let funcName=String(sub)+"()"
            return funcName
        }else{
            return funcId
        }
    }
    
    //set where device send log to and init connection or reset connection
    //logid用来分辨发送设备，当有多个设备发送信息时，记得要将这些设备设置不同的logid
    public static func resetDst(toIp ip:NWEndpoint.Host="127.0.0.1",toPort port:NWEndpoint.Port=20131,logId:UInt32){
        Logcat.logId=logId
        initConnection(toHost: ip, toPort: port)

        var buf=Data(count: 140)
        buf[0]=UInt8(Masthead.resetLogId.rawValue)
        let mask=0xff
        for i in 0..<4{
            buf[i+1]=UInt8(Int(logId>>(8*(4-i-1)))&mask)
        }
        connection!.send(content: buf, completion: NWConnection.SendCompletion.contentProcessed({(NWError)in
            if NWError != nil{
                print("logcat:send resetLogId failure")
            }
        }))
    }
    
    //组织一条log信息
    private static func proccessMsg(msg:String,level:String,tag:String,filePath:String,function:String,line:Int)->String{
        let t=time(nil)
        let place="\(getFileName(filePath: filePath)):\(getFuncName(funcId: function)):\(line)"
        let msgStr=makeJsonStr(msg: msg, tag: tag, level: level, time: UInt(t),place:place)
        return msgStr
    }
    
    //send log message of level i
    public static func i(_ msg:String,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        if outputKind == .None||OutputLevel.information.rawValue<outputLevel.rawValue{
            return
        }else{
            dispatchQueue.async {
                let msgStr=proccessMsg(msg: msg, level: "i", tag: tag, filePath: filePath, function: function, line: line)
                if outputKind == .Udp{
                    sendMsg(msg: msgStr)
                }else{
                    saveMsg(msg: msgStr)
                }
            }
        }
    }
    
    //send log message of level d
    public static func d(_ msg:String,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        if outputKind == .None||OutputLevel.debug.rawValue<outputLevel.rawValue{
            return
        }else{
            dispatchQueue.async {
                let msgStr=proccessMsg(msg: msg, level: "d", tag: tag, filePath: filePath, function: function, line: line)
                if outputKind == .Udp{
                    sendMsg(msg: msgStr)
                }else{
                    saveMsg(msg: msgStr)
                }
            }
        }
    }
    
    //send log message of level w
    public static func w(_ msg:String,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        if outputKind == .None||OutputLevel.warning.rawValue<outputLevel.rawValue{
            return
        }else{
            dispatchQueue.async {
                let msgStr=proccessMsg(msg: msg, level: "w", tag: tag, filePath: filePath, function: function, line: line)
                if outputKind == .Udp{
                    sendMsg(msg: msgStr)
                }else{
                    saveMsg(msg: msgStr)
                }
            }
        }
    }
    
    //send log message of level e
    public static func e(_ msg:String,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        if outputKind == .None{
            return
        }else{
            dispatchQueue.async {
                let msgStr=proccessMsg(msg: msg, level: "e", tag: tag, filePath: filePath, function: function, line: line)
                if outputKind == .Udp{
                    sendMsg(msg: msgStr)
                }else{
                    saveMsg(msg: msgStr)
                }
            }
        }
    }
    
    public static func setOutputLevel(level:OutputLevel){
        outputLevel=level
    }
    
    public static func setSave2Local(appName name:String,saveInterval time:TimeInterval=0.5){
        outputKind = .Local
        LocalSaver.singleInstance.startSaving(appName: name, saveIterval: time)
    }
}
