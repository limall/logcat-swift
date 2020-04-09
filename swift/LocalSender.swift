//
//  LocalSender.swift
//  Logcat_iosProj
//
//  Created by 左启凡 on 2020/3/31.
//  Copyright © 2020 zqf. All rights reserved.

//每次发送的数据包前四byte为握手口令，接着三个byte为文件夹名（数字），接着四byte为文件名（数字），接着一byte为数据长度，最后128byte为数据
//每个实例只能同时执行一个发送任务
//该实例会发生内存泄露，但泄露的量理论上和实际测试都很小，可以忽略不计。为了代码整洁这里就不处理了
//经过测试，闭包发生泄露时，它的调用栈内存并不会泄露。我也不太清楚是否是这样，还请路过的大神赐教。

import Foundation
import Network

public class LocalSender{
    private struct FileId{
        let folderId:Int
        let fileId:Int
    }
    
    //发送数据块的最大容量
    private let BLOCK_MAX_LEN=128
    private var localHomeDirectory:String=""
    private var fileSentCallback:(()->Void)
    private var connection:NWConnection
    //connectKey为与服务器连接的口令，预防简单的ddos攻击
    private var connectKey:Int
    //缓存要发送的数据
    private var sendCache=[Data]()
    private var sendingFileHolderId=0
    private var sendingFileId=0
    private var isSendingSingleFile=true
    
    init(toIP:NWEndpoint.Host,toPort:NWEndpoint.Port=11230,connectKey:Int=396792774,appName:String) {
        connection=NWConnection(host: toIP, port: toPort, using: .tcp)
        self.connectKey=connectKey
        fileSentCallback={
            debugPrint("logcat:local sender:file sent")
        }
        initConnection()
        getLocalHomeDirectory(appName: appName)
    }
    
    private func getLocalHomeDirectory(appName:String){
        let paths=NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        localHomeDirectory=paths[0]+"/logs"
    }
    
    public func initConnection(){
        connection.stateUpdateHandler = { (newState) in
            switch (newState) {
                case .ready:
                    debugPrint("logcat:local sender:NWConnection ready")
                case .setup:
                    debugPrint("logcat:local sender:NWConnection setup")
                case .cancelled:
                    debugPrint("logcat:local sender:NWConnection cancelled")
                case .preparing:
                    debugPrint("logcat:local sender:NWConnection preparing")
                default:
                    print("logcat:local sender:ERROR! State not defined!\n")
            }
        }
        connection.start(queue: .global())
    }
    
    //发送文件数据块
    private func sendBlock(block:Data){
        var data=Data(count: 12)
        let mask=0xff
        for i in 0..<4{
            data[i]=UInt8((connectKey>>(8*(4-i-1)))&mask)
        }
        for i in 0..<3{
            data[i+4]=UInt8((sendingFileHolderId>>(8*(3-i-1)))&mask)
        }
        for i in 0..<4{
            data[i+7]=UInt8((sendingFileId>>(8*(4-i-1)))&mask)
        }
        data[11]=UInt8(block.count)
        
        data.append(block)
        
        if data.count<BLOCK_MAX_LEN+12{
            let zeroData=Data(count: BLOCK_MAX_LEN+12-data.count)
            data.append(zeroData)
        }
        
        sendCache.append(data)
    }
    
    //将缓存的block一个接一个发送
    private func send(){
        if sendCache.count>0{
            var index=0
            var callback:((NWError?)->Void)?=nil
            callback={(nwerror:NWError?) in
                if let error=nwerror{
                    print("logcat:local send:error occurs when sending block of:\(self.sendingFileHolderId)/\(self.sendingFileId),error:\(error)")
                    self.sendCache.removeAll()
                }else{
                    index += 1
                    if index<self.sendCache.count{
                        self.connection.send(content: self.sendCache[index], completion: NWConnection.SendCompletion.contentProcessed(callback!))
                    }else{
                        debugPrint("file:\(self.sendingFileHolderId)/\(self.sendingFileId):has been sent")
                        self.sendCache.removeAll()
                        if self.isSendingSingleFile{
                            self.connection.cancel()
                        }
                        self.fileSentCallback()
                    }
                }
            }
            connection.send(content: sendCache[index], completion: NWConnection.SendCompletion.contentProcessed(callback!))
        }
    }
    
    //单位：bytes
    private func getFileSize(path url:String)->UInt64?{
        var fileSize:UInt64?=nil
        do{
            let attr=try FileManager.default.attributesOfItem(atPath: url)
            fileSize=attr[FileAttributeKey.size] as? UInt64
        }catch{
            print("logcat:error occurs when getting file size,becuase of getting attribute of item from path:\(url) failure,error:\(error)")
        }
        return fileSize
    }
    
    private func getFiles2Send()->[FileId]{
        var fileIds=[FileId]()
        do{
            let folderNames=try FileManager.default.contentsOfDirectory(atPath: localHomeDirectory)
            for folderName in folderNames{
                let folderPath="\(localHomeDirectory)/\(folderName)"
                let fileNames=try FileManager.default.contentsOfDirectory(atPath: folderPath)
                for fileName in fileNames{
                    let filePath="\(localHomeDirectory)/\(folderName)/\(fileName)"
                    if let fileSize=getFileSize(path: filePath){
                        if fileSize>0{
                            let folderId=Int(folderName)
                            let fileId=Int(fileName)
                            debugPrint("logcat:local send:find log file:\(folderId!)/\(fileId!)")
                            fileIds.append(FileId(folderId: folderId!, fileId: fileId!))
                        }
                    }else{
                        print("logcat:local send:can not get file size of \(folderName)/\(fileName)")
                    }
                }
            }
        }catch{
            print("logcat:local send:Error occurs when try get path of files to send,error:\(error)")
        }
        return fileIds
    }
    
    //开始发送指定的日志文件（发送时将文件分拆后存入发送队列）
    private func sendFile(holderId:Int,fileId:Int,completeCallback:@escaping()->Void){
        sendingFileHolderId=holderId
        sendingFileId=fileId
        let path="\(localHomeDirectory)/\(holderId)/\(fileId)"
        fileSentCallback=completeCallback
        if let data=FileManager.default.contents(atPath: path){
            let totalLength=data.count
            var start=0
            while start<totalLength {
                var thisLength=totalLength-start
                if thisLength>BLOCK_MAX_LEN{
                    thisLength=BLOCK_MAX_LEN
                }
                
                var block=Data(count: thisLength)
                for i in 0..<thisLength{
                    block[i]=data[i+start]
                }
                
                sendBlock(block: block)
                
                start += thisLength
            }
            send()
        }else{
            print("logcat:local sender:can not read file from:\(path)")
        }
    }
    
    public func sendSingleFile(holderId:Int,fileId:Int,completeCallback:@escaping()->Void){
        isSendingSingleFile=true
        sendFile(holderId: holderId, fileId: fileId, completeCallback: completeCallback)
    }
    
    public func sendAllFiles(completeCallback:@escaping()->Void){
        isSendingSingleFile=false
        let files2Send=getFiles2Send()
        guard files2Send.count>0 else{
            return
        }
        
        var index=0
        var oneFileSentCallback:(()->Void)?=nil
        oneFileSentCallback={
            debugPrint("logcat:local send:file:\(files2Send[index].folderId)/\(files2Send[index].fileId) has been sent")
            
            index += 1
            if index<files2Send.count{
                self.sendFile(holderId: files2Send[index].folderId, fileId: files2Send[index].fileId, completeCallback: oneFileSentCallback!)
            }else{
                debugPrint("logcat:local send:all file sent")
                self.connection.cancel()
                completeCallback()
            }
        }
        sendFile(holderId: files2Send[index].folderId, fileId: files2Send[index].fileId, completeCallback: oneFileSentCallback!)
    }
}
