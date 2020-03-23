//
//  PasswordEntryPopup.swift
//  Passwordduino
//
//  Created by larry qiu on 3/18/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import Foundation
import UIKit
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
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return !((textField.text ?? "").isEmpty)
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
