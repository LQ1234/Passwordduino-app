//
//  SettingsTableViewController.swift
//  Passwordduino
//
//  Created by larry qiu on 3/18/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    var isUnlocked=false;
    var lockedLock:UIImage!;
    var unlockedLock:UIImage!;

    @IBOutlet weak var usePasswordSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        lockedLock=UIImage(systemName: "lock")
        unlockedLock=UIImage(systemName: "lock.open")
        updatePasswordSwitch();
        isUnlocked=false;
        setUnlockState(false, [1,2])
    }

    @IBAction func unlockButtonClicked(_ sender: UIBarButtonItem) {
        if(isUnlocked){
            isUnlocked=false;
            setUnlockState(false, [1,2])
            sender.image=self.lockedLock;

        }else{
            authenticateWithDevicePassword(controller:self){ (successful) in
                if(successful){
                    self.isUnlocked=true
                    self.setUnlockState(true, [1,2])
                    sender.image=self.unlockedLock;
                }
            }
        }
    }
    
    
    private func setUnlockState(_ isUnlocked:Bool,_ sections:[Int]){
        for section in sections{
            for row in 0..<tableView.numberOfRows(inSection: section){
                if let cell = tableView.cellForRow(at: IndexPath(row: row, section: section)) {
                    cell.textLabel!.isEnabled = isUnlocked;
                    cell.isUserInteractionEnabled = isUnlocked;
                    
                    setStateRecursively(cell,isUnlocked);
                    
                }
            }
        }
    }
    
    private func setStateRecursively(_ view:UIView,_ enabled:Bool){
        view.isUserInteractionEnabled=enabled;
        if let item = view as? UISwitch {
            item.isEnabled=enabled;
        }
        if let item = view as? UILabel {
            item.isEnabled=enabled;
        }
        if let item = view as? UIButton {
            item.isEnabled=enabled;
        }
        for subview in view.subviews {
            setStateRecursively(subview,enabled);
        }
    }
    
    @IBAction func passwordSwitchPressed(_ sender: UISwitch) {
        if(sender.isOn){
            askPasswordduinoPassword();
        }else{
            deletePasswordduinoPassword();
        }
    }
    
    private func askPasswordduinoPassword(){
        promptPassword(title: "Enter password", message: "This password will be used to authenticate you if biometrics are unavailable", controller: self) { (pass) in
            if let password = pass{
                self.usePasswordSwitch.setOn(true, animated: true)
                setPasswordduinoPassword(password: password)
            }else{
                self.usePasswordSwitch.setOn(false, animated: true)
                deletePasswordduinoPassword();
            }
        }
        self.usePasswordSwitch.setOn(false, animated: true)
        deletePasswordduinoPassword();
    }
    private func updatePasswordSwitch(){
        usePasswordSwitch.setOn(passwordduinoPasswordExists(), animated: false);
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
