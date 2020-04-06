//
//  Authentication.swift
//  Passwordduino
//
//  Created by larry qiu on 3/17/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import Foundation
import LocalAuthentication
import UIKit



func authenticateWithDevicePassword(controller:UIViewController, callback:@escaping (Bool)->Void){
    let context = LAContext()
    var error: NSError?
    
    if(context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)) {
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authenticate to access settings" ) { success, error in
            if success {
                DispatchQueue.main.async {
                     callback(true);
                }
            } else {
                DispatchQueue.main.async {
                    callback(false);
                }
            }
        }
    } else {
        infoPrompt(title:"Unable to authenticate",message: error.debugDescription,controller:controller,callback: {(_:UIAlertAction)->Void in
            DispatchQueue.main.async {
                callback(false);
            }
        });
    }
}

func authenticateWithBiometrics(controller:UIViewController, callback:@escaping (Bool)->Void){
    if(passwordduinoPasswordExists()){
        func fallBackToPasswordEntry(){
            promptPassword(title: "Enter password", message: "Enter password:", controller: controller) { (result) in
                if let entered=result{
                    if(entered==getPasswordduinoPassword()){
                        DispatchQueue.main.async {
                            callback(true);
                        }
                    }else {
                        infoPrompt(title:"Incorrect Password",message:"Incorrect Password",controller:controller){ (_) in
                            DispatchQueue.main.async {
                                callback(false);
                            }
                        }
                    }
                }else{
                    DispatchQueue.main.async {
                        callback(false);
                    }
                }
            }
        }
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to access settings" ) { success, error in
                if success {
                    DispatchQueue.main.async {
                         callback(true);
                    }
                } else {
                    DispatchQueue.main.async {
                        fallBackToPasswordEntry();
                    }
                }
            }
        }else{
            fallBackToPasswordEntry();
        }
    }else{
        authenticateWithDevicePassword(controller:controller,callback: callback);
    }
}

//MARK: Device PSK

func setDevicePSK(pskAsData: Data){

    if(devicePSKExists()){
        let findQuery: [String: Any] = [kSecClass as String: kSecClassKey,
                                        kSecAttrLabel as String: "devicePSK"];
        let setAttrs: [String: Any] = [kSecValueData as String: pskAsData];
        let status = SecItemUpdate(findQuery as CFDictionary, setAttrs as CFDictionary)
        precondition(status != errSecItemNotFound, "Trying to update existing item but it doesn't exist anymore: \(status)");
        precondition(status==errSecSuccess, "Error Storing item in keychain: \(status)");
    }else{
        let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrLabel as String: "devicePSK",
                                    kSecValueData as String: pskAsData];
        
        let status = SecItemAdd(query as CFDictionary, nil);
        precondition(status==errSecSuccess, "Error Storing item in keychain: \(status)");
    }
}
func devicePSKExists()->Bool{
    let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                kSecAttrLabel as String: "devicePSK",
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: false,
                                kSecReturnData as String: false];
    var item: CFTypeRef?;
    let status = SecItemCopyMatching(query as CFDictionary, &item);
    return(status != errSecItemNotFound);
}
func getDevicePSK()->Data?{
    let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                kSecAttrLabel as String: "devicePSK",
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true];
    
    var item: CFTypeRef?;
    let status = SecItemCopyMatching(query as CFDictionary, &item);
    guard status != errSecItemNotFound else {
        return nil;
    }
    guard status == errSecSuccess else {
        fatalError("Unsuccessful keychain get error: \(status)")
    }
    guard let existingItem = item as? [String : Any],
        let pskData = existingItem[kSecValueData as String] as? Data
    else {
       fatalError("Unexpected password data in Keychain get request")
    }
    
    return(pskData);
}
func deleteDevicePSK(){
    let findQuery: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrLabel as String: "devicePSK"];
    let status = SecItemDelete(findQuery as CFDictionary)
    precondition(status == errSecSuccess || status == errSecItemNotFound , "Unsuccessful keychain delete error: \(status)")
}

//MARK: Passwordduino Password

func setPasswordduinoPassword(password: String){
    let passwordAsData = password.data(using: String.Encoding.utf8)!

    if(passwordduinoPasswordExists()){
        let findQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                        kSecAttrService as String: "passwordduino",
                                        kSecAttrAccount as String: "passwordduino"];
        let setAttrs: [String: Any] = [kSecValueData as String: passwordAsData];
        let status = SecItemUpdate(findQuery as CFDictionary, setAttrs as CFDictionary)
        precondition(status != errSecItemNotFound, "Trying to update existing item but it doesn't exist anymore: \(status)");
        precondition(status==errSecSuccess, "Error Storing item in keychain: \(status)");
    }else{
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "passwordduino",
                                    kSecAttrAccount as String: "passwordduino",
                                    kSecValueData as String: passwordAsData];
        
        let status = SecItemAdd(query as CFDictionary, nil);
        precondition(status==errSecSuccess, "Error Storing item in keychain: \(status)");
    }
}
func passwordduinoPasswordExists()->Bool{
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: "passwordduino",
                                kSecAttrAccount as String: "passwordduino",
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: false,
                                kSecReturnData as String: false];
    var item: CFTypeRef?;
    let status = SecItemCopyMatching(query as CFDictionary, &item);
    return(status != errSecItemNotFound);
}
func getPasswordduinoPassword()->String?{
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: "passwordduino",
                                kSecAttrAccount as String: "passwordduino",
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true];
    
    var item: CFTypeRef?;
    let status = SecItemCopyMatching(query as CFDictionary, &item);
    guard status != errSecItemNotFound else {
        return nil;
    }
    guard status == errSecSuccess else {
        fatalError("Unsuccessful keychain get error: \(status)")
    }
    guard let existingItem = item as? [String : Any],
        let passwordData = existingItem[kSecValueData as String] as? Data,
        let password = String(data: passwordData, encoding: String.Encoding.utf8)
    else {
       fatalError("Unexpected password data in Keychain get request")
    }
    
    return(password);
}
func deletePasswordduinoPassword(){
    let findQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "passwordduino",
                                    kSecAttrAccount as String: "passwordduino"];
    let status = SecItemDelete(findQuery as CFDictionary)
    precondition(status == errSecSuccess || status == errSecItemNotFound , "Unsuccessful keychain delete error: \(status)")
}
//MARK: User Passwords

func setUserPassword(name:String, password: String){
    let passwordAsData = password.data(using: String.Encoding.utf8)!

    if(userPasswordExists(name: name)){
        let findQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                        kSecAttrService as String: "user",
                                        kSecAttrAccount as String: name];
        let setAttrs: [String: Any] = [kSecValueData as String: passwordAsData];
        let status = SecItemUpdate(findQuery as CFDictionary, setAttrs as CFDictionary)
        precondition(status != errSecItemNotFound, "Trying to update existing item but it doesn't exist anymore: \(status)");
        precondition(status==errSecSuccess, "Error Storing item in keychain: \(status)");

    }else{
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "user",
                                    kSecAttrAccount as String: name,
                                    kSecValueData as String: passwordAsData];
        
        let status = SecItemAdd(query as CFDictionary, nil);
        precondition(status==errSecSuccess, "Error Storing item in keychain: \(status)");
    }
}
func userPasswordExists(name:String)->Bool{
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: "user",
                                kSecAttrAccount as String: name,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: false,
                                kSecReturnData as String: false];
    var item: CFTypeRef?;
    let status = SecItemCopyMatching(query as CFDictionary, &item);
    return(status != errSecItemNotFound);
}
func getUserPassword(name:String)->String?{
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: "user",
                                kSecAttrAccount as String: name,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecReturnData as String: true];
    
    var item: CFTypeRef?;
    let status = SecItemCopyMatching(query as CFDictionary, &item);
    guard status != errSecItemNotFound else {
        return nil;
    }
    guard status == errSecSuccess else {
        fatalError("Unsuccessful keychain get error: \(status)")
    }
    guard let existingItem = item as? [String : Any],
        let passwordData = existingItem[kSecValueData as String] as? Data,
        let password = String(data: passwordData, encoding: String.Encoding.utf8)
    else {
       fatalError("Unexpected password data in Keychain get request")
    }
    
    return(password);
}
func deleteUserPassword(name:String){
    let findQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "user",
                                    kSecAttrAccount as String: name];
    let status = SecItemDelete(findQuery as CFDictionary)
    precondition(status == errSecSuccess || status == errSecItemNotFound , "Unsuccessful keychain delete error: \(status)")
}

