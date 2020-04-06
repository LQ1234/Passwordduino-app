//
//  BytecodeAndCrypto.swift
//  Passwordduino
//
//  Created by larry qiu on 3/27/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import Foundation
import UIKit

enum ByteCodeType:UInt8{
    case rawHID=0
    case text
    case delay
}
class Bytecode{
    static private func uint32ToData(_ inp:UInt32)->Data{
        var inpvar=inp;
        return(Data(bytes: &inpvar, count: MemoryLayout.size(ofValue: inp)))
    }
    static func from(ducky duckyScript:String,passwordInfo:(entries:[Entry],controller:UIViewController?),callback:@escaping (_ bytecode:Data?,_ error:String)->Void){
        var bytecode=Data();
        var scanner=Scanner(string:duckyScript);
        var needsAuthentication=false
        func nextString()->String{
            return(scanner.scanUpToCharacters(from: CharacterSet.whitespacesAndNewlines) ?? "");
        }
        func nextUInt32()->UInt32?{
            if let v=scanner.scanInt(){
                return(UInt32(v));
            }
            return(nil);
        }
        func nextLine()->String{
            let prev=scanner.charactersToBeSkipped;
            scanner.charactersToBeSkipped=CharacterSet.whitespaces;
            let res=scanner.scanUpToCharacters(from: CharacterSet.newlines) ?? "";
            scanner.charactersToBeSkipped=prev;
            return(res);
        }
        func nextLineSplit()->[String]{
            return(nextLine().split(separator: " ").map {String($0)})
        }
        func alnumCode(_ name:String)->UInt8?{
            if(name.count==1){
                if let ascii=name.lowercased().first!.asciiValue{
                    switch(ascii){
                        case 0x61...0x7A:
                            return(UInt8(ascii-0x61+0x04));
                        case 0x31...0x39:
                            return(UInt8(ascii-0x31+0x1e));
                        case 0x30:
                            return(UInt8(ascii-0x30+0x27));
                        default:
                            return(nil);
                    }
                }
            }
            return(nil);
        }
        func modCode(_ name:String)->UInt8?{
            switch (name.lowercased()){
                case "ctrl","control":
                    return(0b00000001);
                case "shift":
                    return(0b00000010);
                case "alt","option":
                    return(0b00000100);
                case "gui","windows","logo","command":
                    return(0b00001000);
                default:
                    return(nil);
            }
        }
        func keyCode(_ name:String)->UInt8?{
            switch (name.lowercased()){
                case "enter":
                    return(0x28);
                case "capslock","caps":
                    return(0x39);
                case "del","delete":
                    return(0x4c);
                case "backspace":
                    return(0x2a);
                case "esc","escape":
                    return(0x29);
                case "home":
                    return(0x4a);
                case "insert":
                    return(0x49);
                case "numlock":
                    return(0x53);
                case "pageup":
                    return(0x4b);
                case "pagedown":
                    return(0x4e);
                case "printscreen":
                    return(0x46);
                case "scrolllock":
                    return(0x47);
                case "space":
                    return(0x2c);
                case "tab":
                    return(0x2b);
                case "left","leftarrow":
                    return(0x50);
                case "right","rightarrow":
                    return(0x4f);
                case "up","uparrow":
                    return(0x52);
                case "down","downarrow":
                    return(0x51);
                case "f1":
                    return(0x3a);
                case "f2":
                    return(0x3b);
                case "f3":
                    return(0x3c);
                case "f4":
                    return(0x3d);
                case "f5":
                    return(0x3e);
                case "f6":
                    return(0x3f);
                case "f7":
                    return(0x40);
                case "f8":
                    return(0x41);
                case "f9":
                    return(0x42);
                case "f10":
                    return(0x43);
                case "f11":
                    return(0x44);
                case "f12":
                    return(0x45);
                default:
                    return(nil);
            }
        }
        //thanks to https://files.microscan.com/helpfiles/ms4_help_file/ms-4_help-02-46.html

        func typeKeySequence(_ names:[String],to:inout Data) -> String?{
            var report=[UInt8](repeating: 0, count: 9);
            report[0]=0x01;
            let reset=report;
            var keyIndx=3;
            for name in names{
                if let modifier=modCode(name){
                    report[1]|=modifier;
                }else if let key=keyCode(name){
                    if(keyIndx>=9){
                        return("Too many keys")
                    }
                    report[keyIndx]=key;
                    keyIndx+=1;
                }else if let alnum=alnumCode(name){
                    if(keyIndx>=9){
                        return("Too many keys")
                    }
                    report[keyIndx]=alnum;
                    keyIndx+=1;
                }else{
                    return("Unknown key \(name)");
                }
                to.append(contentsOf: [ByteCodeType.rawHID.rawValue]);
                to.append(contentsOf:report);
                delay(50,to:&to);
            }
            to.append(contentsOf: [ByteCodeType.rawHID.rawValue]);
            to.append(contentsOf:reset);
            delay(50,to:&to);
            return(nil);
        }
        
        var defaultdelay:UInt32=0;
        func delay(_ len:UInt32,to:inout Data){
            to.append(contentsOf: [ByteCodeType.delay.rawValue]);
            to.append(uint32ToData(len));
        }
        func delayDefaultDelay(to:inout Data){
            delay(defaultdelay,to:&to);
        }
        var lastBytecode=Data();
        while(!scanner.isAtEnd){
            let startingIndex=scanner.currentIndex;
            let wholeLine=nextLine();
            scanner.currentIndex=startingIndex;
            
            let command=nextString().lowercased();
            
            switch command {
            case "rem":
                _ = nextLine();
            case "default_delay","defaultdelay":
                if let dd=nextUInt32(){
                    defaultdelay=dd;
                }else{
                    callback(nil,"Invalid integer at \(wholeLine)")
                    return;
                }
                _ = nextLine();
            case "delay":
                lastBytecode=Data();
                if let dd=nextUInt32(){
                    delay(dd,to:&lastBytecode);
                }else{
                    callback(nil,"Invalid integer at \(wholeLine)")
                    return;
                }
                delayDefaultDelay(to:&lastBytecode);
                bytecode.append(lastBytecode);
            case "string", "print":
                lastBytecode=Data();
                let str=nextLine();
                lastBytecode.append(contentsOf: [ByteCodeType.text.rawValue]);
                lastBytecode.append(uint32ToData(UInt32(str.count)));
                lastBytecode.append(str.data(using: String.Encoding.utf8,allowLossyConversion: true)!);
                delayDefaultDelay(to:&lastBytecode);
                bytecode.append(lastBytecode);
            case "repeat":
                if let dd=nextUInt32(){
                    for _ in 0..<dd{
                        bytecode.append(lastBytecode);
                    }
                }else{
                    callback(nil,"Invalid integer at \(wholeLine)")
                    return;
                }
            case "password":
                let lookForName=nextLine().trimmingCharacters(in: .whitespaces);
                if let entry=passwordInfo.entries.first(where: { $0.name.trimmingCharacters(in: .whitespaces)==lookForName}){
                    if passwordInfo.controller != nil{
                        needsAuthentication=true;
                        lastBytecode=Data();
                        if let password=getUserPassword(name: entry.name){
                            lastBytecode.append(contentsOf: [ByteCodeType.text.rawValue]);
                            lastBytecode.append(uint32ToData(UInt32(password.count)));
                            lastBytecode.append(password.data(using: String.Encoding.utf8,allowLossyConversion: true)!);
                        }else{
                            callback(nil,"Error accessing password \(entry.name)")
                            return;
                        }
                        delayDefaultDelay(to:&lastBytecode);
                        bytecode.append(lastBytecode);
                    }
                } else{
                    callback(nil,"Password \(lookForName) not found at \(wholeLine)")
                    return;
                }
            default:
                if(keyCode(command) != nil||modCode(command) != nil){
                    lastBytecode=Data();
                    if let error=typeKeySequence([command]+nextLineSplit(),to:&lastBytecode){
                        callback(nil,"\(error) at \(wholeLine)")
                        return;
                    }
                    delayDefaultDelay(to:&lastBytecode);
                    bytecode.append(lastBytecode);
                }else if(command.first=="#"||command.starts(with: "//")){
                    _ = nextLine();
                }else{
                    callback(nil,"Unknown command \(command) at \(wholeLine)")
                    return;
                }
            }
        }
        if(needsAuthentication){
            authenticateWithBiometrics(controller: passwordInfo.controller!) { (successful) in
                if(successful){
                    callback(bytecode,"")
                    return;
                }else{
                    callback(nil,"Failed to authenticate")
                    return;
                }
            };
            return;
        }else{
            callback(bytecode,"")
            return;
        }
    }
    static func from(name:String,passwordInfo:(entries:[Entry],controller:UIViewController),callback:@escaping (_ bytecode:Data?,_ error:String)->Void){
        if let entry=passwordInfo.entries.first(where: { $0.name==name}){
            var bytecode=Data();
            if let password=getUserPassword(name: entry.name){
                bytecode.append(contentsOf: [ByteCodeType.text.rawValue]);
                bytecode.append(uint32ToData(UInt32(password.count)));
                bytecode.append(password.data(using: String.Encoding.utf8,allowLossyConversion: true)!);
                authenticateWithBiometrics(controller: passwordInfo.controller) { (successful) in
                    if(successful){
                        callback(bytecode,"")
                        return;
                    }else{
                        callback(nil,"Failed to authenticate")
                        return;
                    }
                };
                return;
            }else{
                callback(nil,"Error accessing password \(entry.name)")
                return;
            }
            
        } else{
            callback(nil,"Password \(name) not found")
            return;
        }
    }
}
import CryptoKit

func encrypt(_ data:Data)->Data?{
    guard let psk=getDevicePSK() else {
        return(nil);
    }
    guard let sealedBox = try? ChaChaPoly.seal(data, using: SymmetricKey(data:psk)) else {
        return(nil);
    }
    //     12 bytes        same as input
    return(sealedBox.nonce+sealedBox.ciphertext);
}
