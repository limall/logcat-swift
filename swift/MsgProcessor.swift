//
//  MsgProcessor.swift
//  Logcat_iosProj
//
//  Created by 左启凡 on 2020/3/24.
//  Copyright © 2020 zqf. All rights reserved.
//

import Foundation

extension Logcat{
    public static func i(_ msg:Int,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.i(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func d(_ msg:Int,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.d(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func w(_ msg:Int,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.w(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func e(_ msg:Int,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.e(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func i(_ msg:Float,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.i(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func d(_ msg:Float,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.d(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func w(_ msg:Float,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.w(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func e(_ msg:Float,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.e(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func i(_ msg:Double,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.i(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func d(_ msg:Double,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.d(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func w(_ msg:Double,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.w(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func e(_ msg:Double,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.e(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func i(_ msg:Character,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.i(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func d(_ msg:Character,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.d(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func w(_ msg:Character,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.w(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func e(_ msg:Character,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.e(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func i(_ msg:Bool,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.i(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func d(_ msg:Bool,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.d(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func w(_ msg:Bool,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.w(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func e(_ msg:Bool,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        Logcat.e(String(msg),tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func iHex(_ msg:Int,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=String(format: "%02x", msg)
        Logcat.i(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func dHex(_ msg:Int,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=String(format: "%02x", msg)
        Logcat.d(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func wHex(_ msg:Int,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=String(format: "%02x", msg)
        Logcat.w(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func eHex(_ msg:Int,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=String(format: "%02x", msg)
        Logcat.e(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func iHex(_ msg:UInt8,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=String(format: "%02x", msg)
        Logcat.i(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func dHex(_ msg:UInt8,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=String(format: "%02x", msg)
        Logcat.d(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func wHex(_ msg:UInt8,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=String(format: "%02x", msg)
        Logcat.w(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func eHex(_ msg:UInt8,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=String(format: "%02x", msg)
        Logcat.e(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    private static func processStr(_ msg:[Int])->String{
        var result=""
        
        for i in 0..<msg.count{
            result += "\(msg[i])"
            
            if i<msg.count-1{
                result += ","
            }
        }
        
        result += "\n\n"
        
        var line=0
        for i in 0..<msg.count{
            result += "\(i):\(msg[i])"
            line += 1
            
            if line==6{
                result += "\n"
                line=0
            }else if i<msg.count-1{
                result += ","
            }
        }
        
        return result
    }
    
    public static func i(_ msg:[Int],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.i(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func d(_ msg:[Int],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.d(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func w(_ msg:[Int],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.w(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func e(_ msg:[Int],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.e(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    private static func processStr(_ msg:[UInt8])->String{
        var result=""
        
        for i in 0..<msg.count{
            result += "\(msg[i])"
            
            if i<msg.count-1{
                result += ","
            }
        }
        
        result += "\n\n"
        
        var line=0
        for i in 0..<msg.count{
            result += "\(i):\(msg[i])"
            line += 1
            
            if line==6{
                result += "\n"
                line=0
            }else if i<msg.count-1{
                result += ","
            }
        }
        
        return result
    }
    
    public static func i(_ msg:[UInt8],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.i(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func d(_ msg:[UInt8],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.d(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func w(_ msg:[UInt8],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.w(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func e(_ msg:[UInt8],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.e(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    private static func processHexStr(_ msg:[Int])->String{
        var result=""
        
        for i in 0..<msg.count{
            let hexStr=String(format: "%02x", msg[i])
            result += "\(hexStr)"
            
            if i<msg.count-1{
                result += ","
            }
        }
        
        result += "\n\n"
        
        var line=0
        for i in 0..<msg.count{
            let hexStr=String(format: "%02x", msg[i])
            result += "\(i):\(hexStr)"
            line += 1
            
            if line==6{
                result += "\n"
                line=0
            }else if i<msg.count-1{
                result += ","
            }
        }
        
        return result
    }
    
    public static func iHex(_ msg:[Int],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.i(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func dHex(_ msg:[Int],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.d(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func wHex(_ msg:[Int],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.w(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func eHex(_ msg:[Int],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.e(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    private static func processHexStr(_ msg:[UInt8])->String{
        var result=""
        
        for i in 0..<msg.count{
            let hexStr=String(format: "%02x", msg[i])
            result += "\(hexStr)"
            
            if i<msg.count-1{
                result += ","
            }
        }
        
        result += "\n\n"
        
        var line=0
        for i in 0..<msg.count{
            let hexStr=String(format: "%02x", msg[i])
            result += "\(i):\(hexStr)"
            line += 1
            
            if line==6{
                result += "\n"
                line=0
            }else if i<msg.count-1{
                result += ","
            }
        }
        
        return result
    }
    
    public static func iHex(_ msg:[UInt8],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.i(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func dHex(_ msg:[UInt8],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.d(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func wHex(_ msg:[UInt8],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.w(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func eHex(_ msg:[UInt8],tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.e(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    private static func processStr(_ msg:Data)->String{
        var result=""
        
        for i in 0..<msg.count{
            result += "\(msg[i])"
            
            if i<msg.count-1{
                result += ","
            }
        }
        
        result += "\n\n"
        
        var line=0
        for i in 0..<msg.count{
            result += "\(i):\(msg[i])"
            line += 1
            
            if line==6{
                result += "\n"
                line=0
            }else if i<msg.count-1{
                result += ","
            }
        }
        
        return result
    }
    
    public static func i(_ msg:Data,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.i(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func d(_ msg:Data,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.d(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func w(_ msg:Data,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.w(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func e(_ msg:Data,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processStr(msg)
        Logcat.e(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    private static func processHexStr(_ msg:Data)->String{
        var result=""
        
        for i in 0..<msg.count{
            let hexStr=String(format: "%02x", msg[i])
            result += "\(hexStr)"
            
            if i<msg.count-1{
                result += ","
            }
        }
        
        result += "\n\n"
        
        var line=0
        for i in 0..<msg.count{
            let hexStr=String(format: "%02x", msg[i])
            result += "\(i):\(hexStr)"
            line += 1
            
            if line==6{
                result += "\n"
                line=0
            }else if i<msg.count-1{
                result += ","
            }
        }
        
        return result
    }
    
    public static func iHex(_ msg:Data,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.i(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func dHex(_ msg:Data,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.d(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func wHex(_ msg:Data,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.w(str,tag: tag,filePath: filePath,function: function,line: line)
    }
    
    public static func eHex(_ msg:Data,tag:String=String(logId),filePath:String=#file,function:String=#function,line:Int=#line){
        let str=processHexStr(msg)
        Logcat.e(str,tag: tag,filePath: filePath,function: function,line: line)
    }
/*
    public static func iIntArray(_ array:[Int],tag:String=String(logId)){
        
    }
    
    public static func iDoubleArray(_ array:[Double],tag:String=String(logId)){
        
    }
    
    public static func iBoolArray(_ array:[Bool],tag:String=String(logId)){
        
    }
    
    public static func iStringArray(_ array:[String],tag:String=String(logId)){
        
    }
    
    public static func iCharArray(_ array:[Character],tag:String=String(logId)){
        
    }
*/
}
