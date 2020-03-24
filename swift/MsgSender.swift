//
//  MsgSender.swift
//  Logcat_iosProj
//
//  Created by 左启凡 on 2020/3/24.
//  Copyright © 2020 zqf. All rights reserved.
//

import Foundation
import Network

public class UdpLog{
    private enum Masthead:Int {
        case headOfLog=0
        case bodyOfLog=1
        case resetLogId=2
    }
    
    private static let BLOCK_LEN=128
    private static var toHost:NWEndpoint.Host="127.0.0.1"
    private static var toPort:NWEndpoint.Port=20131
    //identify a device which sends log message
    public static var logId:UInt32=0
    //identify one log message
    private static var _id:UInt32=0
    private static var connection:NWConnection?
    
    //create a global single id for one message
    private static func getSingleId()->UInt32{
        var toReturn:UInt32=0
        objc_sync_enter(toReturn)
        toReturn=_id
        _id += 1
        objc_sync_exit(toReturn)
        return toReturn
    }
    
    //init NWConnect to prepare for sending message
    private static func initConnection(){
        connection=NWConnection(host: toHost, port: toPort, using: .udp)
        if let _connection=connection{
            _connection.stateUpdateHandler = { (newState) in
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
            _connection.start(queue: .global())
        }
    }
    
    //set where message will be sent and init NWConnection
    private static func setDst(toIp ip:String,toPort port:UInt16,logId:UInt32){
        let _host=NWEndpoint.Host(ip)
        let _port=NWEndpoint.Port(rawValue: port)
        if let aPort=_port{
            UdpLog.toPort=aPort
        }else{
            print("logcat:set toPort failure")
            return
        }
        toHost=_host
        UdpLog.logId=logId
        
        initConnection()
    }
    
    //send a block of one log message
    private static func sendBlock(block:Data,isBegin:Bool,id:UInt32,totoalLength:UInt16,order:UInt8){
        //add head description
        var buffer=Data(count: 12)
        buffer[0] = isBegin ? 0 : 1
        let mask:UInt32=0xff
        var i=0;
        while i<4 {
            buffer[i+1]=UInt8(UInt32(logId>>(8*(4-i-1)))&mask)
            i+=1
        }
        i=0
        while i<4 {
            buffer[i+5]=UInt8(UInt32(id>>(8*(4-i-1)))&mask)
            i+=1
        }
        buffer[9]=UInt8(totoalLength>>8)
        buffer[10]=UInt8(UInt32(totoalLength)&mask)
        buffer[11]=order
        
        buffer.append(block)
        
        if let _connection=connection{
            _connection.send(content: buffer, completion: NWConnection.SendCompletion.contentProcessed({(NWError)in
                if NWError != nil{
                    print("logcat:error:send block failure,id:\(id),order:\(order)")
                }
            }))
        }else{
            print("logcat:error:send block when connection is nil")
        }
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
    
    //encapsulation log message into a Json string
    private static func makeJsonStr(msg:String,tag:String,level:String,time:UInt)->String{
        let     str="{\"msg\":\"\(msg)\",\"tag\":\"\(tag)\",\"level\":\"\(level)\",\"time\":\(time)}"
        return str
    }
    
    //set where device send log to and init connection or reset connection
    public static func resetDst(toIp ip:String,toPort port:UInt16,logId:UInt32){
        setDst(toIp: ip, toPort: port, logId: logId)
        
        var buf=Data(count: 5)
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
    
    //send log message of level i
    public static func i(_ msg:String,tag:String=String(logId)){
        let level="i"
        let t=time(nil)
        let msg=makeJsonStr(msg: msg, tag: tag, level: level, time: UInt(t))
        sendMsg(msg: msg)
    }
    
    //send log message of level d
    public static func d(_ msg:String,tag:String=String(logId)){
        let level="d"
        let t=time(nil)
        let msg=makeJsonStr(msg: msg, tag: tag, level: level, time: UInt(t))
        sendMsg(msg: msg)
    }
    
    //send log message of level w
    public static func w(_ msg:String,tag:String=String(logId)){
        let level="w"
        let t=time(nil)
        let msg=makeJsonStr(msg: msg, tag: tag, level: level, time: UInt(t))
        sendMsg(msg: msg)
    }
    
    //send log message of level e
    public static func e(_ msg:String,tag:String=String(logId)){
        let level="e"
        let t=time(nil)
        let msg=makeJsonStr(msg: msg, tag: tag, level: level, time: UInt(t))
        sendMsg(msg: msg)
    }
}
