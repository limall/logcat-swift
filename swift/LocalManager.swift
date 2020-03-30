//
//  LocalManager.swift
//  Logcat_iosProj
//
//  Created by 左启凡 on 2020/3/28.
//  Copyright © 2020 zqf. All rights reserved.
//

import Foundation

class LocalManager{
    internal static let singleInstance=LocalManager()
    private init(){}
    
    private let fileManager=FileManager.default
    private var logHomeDirectory=""
    private var logDirectory=""
    //存放缓存的日志
    private var logCache=[String]()
    private var saveTimer:Timer?=nil
    //上一次存储是否将文件存满了（超过1000字符）
    private var previousFileFull=true
    //上一次存储文件名所使用的id（id即为文件名）
    private var previousFileId = -1
    //是否正在存储日志到文件，用来避免多线程冲突
    private var isSaving=false

    

    private func createLogHomeDirectory(appName name:String){
        logHomeDirectory=NSHomeDirectory()+"/\(name)/logs"
        let exist=fileManager.fileExists(atPath: logHomeDirectory)
        if !exist {
            do{
                try fileManager.createDirectory(atPath: logHomeDirectory, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("logcat:Error occurs when creating log home directory,error:\(error)")
            }
        }
    }
    
    //每次运行的日志文件放到一个单独的文件夹中,第一次运行的文件夹名为0，第二次为1，依此类推
    private func createThisRunDirectory(){
        do{
            let directoryNames=try fileManager.contentsOfDirectory(atPath: logHomeDirectory)
            
            var ids=[Int]()
            for directoryName in directoryNames{
                if let id=Int(directoryName){
                    ids.append(id)
                }else{
                    print("logcat:Error:illegal name of a log directory:\(directoryName)")
                }
            }
            
            let directoryName:String
            if let max=ids.max(){
                directoryName=String(max+1)
            }else{
                directoryName="0"
            }
            
            logDirectory=logHomeDirectory+"/\(directoryName)"
            do{
                try fileManager.createDirectory(atPath: logDirectory, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("logcat:Error occurs when creating one log directory,url:\(logDirectory),error:\(error)")
            }
        }catch{
            print("logcat:Error occurs when try get contens of log home directory,error:\(error)")
        }
    }
    
    private func getAndClearSaveCache()->[String]{
        objc_sync_enter(logCache)
        let msgs=logCache
        logCache.removeAll()
        objc_sync_exit(logCache)
        return msgs
    }
    
    //单位：bytes
    private func getFileSize(path url:String)->UInt64?{
        var fileSize:UInt64?=nil
        do{
            let attr=try fileManager.attributesOfItem(atPath: url)
            fileSize=attr[FileAttributeKey.size] as? UInt64
        }catch{
            print("logcat:error occurs when getting file size,becuase of getting attribute of item from path:\(url) failure,error:\(error)")
        }
        return fileSize
    }
    
    private func processMsg(msgs:[String])->Data?{
        var str=""
        for msg in msgs{
            str += msg+","
        }
        let data=str.data(using: String.Encoding.utf8)
        return data
    }
    
    //获取cache应该存入的文件名，如果文件不存在，则创建
    private func getLogFilePath()->String{
        var path=logDirectory+"/\(previousFileId)"
        if previousFileFull{
            previousFileId += 1
            path=logDirectory+"/\(previousFileId)"
            fileManager.createFile(atPath: path, contents: nil, attributes: nil)
        }
        return path
    }
    
    private func writeCacheToFile(path:String,data:Data){
        if let fileHandle=FileHandle(forWritingAtPath: path){
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        }else{
            print("logcat:error occurs when write log cache to file,becuase of creating filehandle failure")
        }
    }
    
    //将缓存的日志存到文件里，并清空日志
    private func saveLogCache(){
        objc_sync_enter(isSaving)
        guard !isSaving else {
            objc_sync_exit(isSaving)
            return
        }
        isSaving=true
        objc_sync_exit(isSaving)
        
        let msgs=getAndClearSaveCache()
        guard !msgs.isEmpty else{
            isSaving=false
            return
        }
        
        if let data=processMsg(msgs: msgs){
            let path=getLogFilePath()
            if let originFileLength=getFileSize(path: path){
                writeCacheToFile(path: path, data: data)
                let nowFileLength=UInt64(data.count)+originFileLength
                if nowFileLength >= 100000{
                    previousFileFull=true
                }
            }else{
                print("logcat:error:can not get origin file length")
            }
        }else{
            print("logcat:error occurs when saving log cache becuase can not get string from log cache")
        }
        
        isSaving=false
    }
    
    internal func startSaving(appName name:String,saveIterval time:TimeInterval){
        createLogHomeDirectory(appName: name)
        createThisRunDirectory()
        DispatchQueue.global().async {
            self.saveTimer=Timer.scheduledTimer(withTimeInterval: time, repeats: true, block: {timer in
                self.saveLogCache()
            })
            RunLoop.current.run()
        }
    }
    
    internal func addSaveCache(msg:String){
        objc_sync_enter(logCache)
        logCache.append(msg)
        objc_sync_exit(logCache)
    }
}



