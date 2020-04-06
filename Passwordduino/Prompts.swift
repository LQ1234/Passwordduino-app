//
//  Prompts.swift
//  Passwordduino
//
//  Created by larry qiu on 3/18/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import Foundation
import UIKit

func infoPrompt(title:String,message:String,controller:UIViewController,callback: @escaping (UIAlertAction)->Void){
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: callback))
    controller.present(alert, animated: true)
}

fileprivate class PasswordInputPrompt:NSObject,UITextFieldDelegate {
    private var textField:UITextField!;
    private var doneAction:UIAlertAction!;
    private let callback:(String?)->Void;
    let controller:UIViewController;
    let title:String;
    let message:String;
    @objc func passwordPromptFieldChanged(){
        if let txt=textField.text, !txt.isEmpty{
            doneAction.isEnabled=true;
            
        }else{
            doneAction.isEnabled=false;
        }
    }
    init(title:String, message:String,controller: UIViewController, callback:@escaping (String?)->Void) {
        self.callback=callback;
        self.title=title;
        self.message=message;
        self.controller=controller;
    }
    func run(){
        let alertController = UIAlertController(title:title,message:message,preferredStyle: .alert)
        alertController.addTextField { (tf) in
            self.textField = tf;
            self.textField.placeholder = "Password";
            self.textField.isSecureTextEntry=true;
        }
        textField.delegate=self;
        let cancelAction=UIAlertAction(title: "Cancel", style: .default, handler: { (_:UIAlertAction) in
            DispatchQueue.main.async {
                self.callback(nil);
            }
        });
        alertController.addAction(cancelAction);
        
        doneAction=UIAlertAction(title: "Done", style: .default, handler: { (_:UIAlertAction) in
            if let txt=self.textField.text{
                DispatchQueue.main.async {
                    self.callback(txt);
                }
            }else{
                DispatchQueue.main.async {
                    self.callback(nil);
                }
            }
        });
        print(self.controller)
        doneAction.isEnabled=false;
        alertController.addAction(doneAction);
        alertController.preferredAction=doneAction;
        textField.addTarget(self, action:  #selector(passwordPromptFieldChanged), for: .editingChanged);

        controller.present(alertController, animated: true)
    }
}


func promptPassword(title:String, message:String,controller: UIViewController,callback:@escaping (String?)->Void){
    PasswordInputPrompt(title: title, message: message, controller: controller, callback: callback).run();
}

fileprivate class HexInputPrompt:NSObject,UITextFieldDelegate {
    private var textField:UITextField!;
    private var doneAction:UIAlertAction!;
    private let callback:(Data??)->Void;
    private let requiredLength:Int;
    let controller:UIViewController;
    let title:String;
    let message:String;
    @objc func hexPromptFieldChanged(){
        if(textField.text?.count==0){
            doneAction.isEnabled=true;
        } else if let txt=textField.text,
            let dat=NSData.init(base64Encoded: txt.trimmingCharacters(in: CharacterSet.whitespaces), options: []),
            dat.count==requiredLength{
            doneAction.isEnabled=true;
        } else {
            doneAction.isEnabled=false;
        }
    }
    init(title:String, message:String,controller: UIViewController,requiredLength:Int, callback:@escaping (Data??)->Void) {
        self.callback=callback;
        self.title=title;
        self.message=message;
        self.controller=controller;
        self.requiredLength=requiredLength;
    }
    func run(){
        let alertController = UIAlertController(title:title,message:message,preferredStyle: .alert)
        alertController.addTextField { (tf) in
            self.textField = tf;
            self.textField.placeholder = "Base64";
        }
        textField.delegate=self;

        
        let cancelAction=UIAlertAction(title: "Cancel", style: .default, handler: { (_:UIAlertAction) in
            DispatchQueue.main.async {
                self.callback(nil);
            }
        });
        alertController.addAction(cancelAction);
        
        doneAction=UIAlertAction(title: "Done", style: .default, handler: { (_:UIAlertAction) in
            if let txt=self.textField.text{
                if let dat=NSData.init(base64Encoded: txt.trimmingCharacters(in: CharacterSet.whitespaces), options: []) as Data?,
                    dat.count==self.requiredLength{
                    DispatchQueue.main.async {
                       self.callback(dat);
                   }
                }else{
                    DispatchQueue.main.async {
                       self.callback(Optional(Optional(nil)));
                   }
                }
               
            }else{
                DispatchQueue.main.async {
                    self.callback(nil);
                }
            }
        });
        doneAction.isEnabled=true;
        alertController.addAction(doneAction);
        alertController.preferredAction=doneAction;
        textField.addTarget(self, action:  #selector(hexPromptFieldChanged), for: .editingChanged);

        controller.present(alertController, animated: true)
    }
}


func promptHex(title:String, message:String,controller: UIViewController,requiredLength:Int,callback:@escaping (Data??)->Void){
    HexInputPrompt(title: title, message: message, controller: controller,requiredLength:requiredLength, callback: callback).run();
}

