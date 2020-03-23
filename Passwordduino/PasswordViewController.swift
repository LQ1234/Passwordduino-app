//
//  PasswordViewController.swift
//  Passwordduino
//
//  Created by larry qiu on 3/16/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import UIKit


class PasswordViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var openEye:UIImage!;
    var closedEye:UIImage!;
    var entry: Entry?;
    private var viewingPassword=false;
    var seeButton:UIButton!;
    override func viewDidLoad() {
        super.viewDidLoad();
        nameTextField.delegate = self;
        passwordTextField.delegate = self;
        if let entry=entry{
            authenticateWithBiometrics(controller: self) { (successful) in
                if(successful){
                    let possiblePassword = getUserPassword(name:entry.name);//Password not actully stored in entry
                    self.nameTextField.text = entry.name;
                    self.navigationItem.title = entry.name;
                    if let password=possiblePassword{
                        self.passwordTextField.text=password;
                    }
                    self.updateSaveButtonState();

                }else{
                    if let navController = self.navigationController{
                        if(navController.viewControllers.count>1){
                            if let viewController = navController.viewControllers[navController.viewControllers.count - 2] as? EntryTableViewController{
                                viewController.currentlyEditing=nil;
                            }
                            
                        }
                        navController.popViewController(animated: true)
                    }
                }
            }
            nameTextField.text = ""
            navigationItem.title = "Authenticating...";
        }
        updateSaveButtonState();
        
        //configure password
        openEye=UIImage(systemName: "eye")
        closedEye=UIImage(systemName: "eye.slash")
        
        let w=openEye.size.width;
        let h=openEye.size.height;
        seeButton = UIButton(type:UIButton.ButtonType.custom);
        seeButton.setImage(openEye, for: .normal)
        seeButton.frame = CGRect(x: w/2, y: h/2, width: w, height: h)
        passwordTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: w*2, height: h*2))
        passwordTextField.rightView?.addSubview(seeButton)
        passwordTextField.rightViewMode = .always
        seeButton.addTarget(self, action: #selector(seeButtonTapped), for: .touchUpInside)
    }
    
    @objc func seeButtonTapped(){
        viewingPassword = !viewingPassword;
        seeButton.setImage(viewingPassword ? closedEye : openEye, for: .normal)
        passwordTextField.isSecureTextEntry = !viewingPassword;
        
    }

    @IBAction func copyButtonPressed(_ sender: Any) {
        let pasteboard = UIPasteboard.general
        if(passwordTextField.text != nil){
            pasteboard.string = passwordTextField.text;
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        let isAddingEntry = presentingViewController is UINavigationController
        if isAddingEntry{
            dismiss(animated: true, completion: nil);
        }else if let navController = navigationController{
            if(navController.viewControllers.count>1){
                if let viewController = navController.viewControllers[navController.viewControllers.count - 2] as? EntryTableViewController{
                    viewController.currentlyEditing=nil;
                }
                
            }
            navController.popViewController(animated: true)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        saveButton.isEnabled = false;
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();

        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState();
        if(textField===nameTextField){
            navigationItem.title = textField.text;
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            return;
        }
        let name=nameTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        if let entry=entry{//if updating entry, delete old one
            deleteUserPassword(name: entry.name)
        }
        setUserPassword(name: name, password: password)
        entry = Entry(entryType:.password, name:name, contents:"")
    }
    
    private func updateSaveButtonState() {
        let nameText = nameTextField.text ?? "";
        let passwordText = passwordTextField.text ?? "";
        saveButton.isEnabled = !nameText.isEmpty && (!passwordText.isEmpty);
    }
}
