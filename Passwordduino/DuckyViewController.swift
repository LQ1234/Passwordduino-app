//
//  DuckyViewController.swift
//  Passwordduino
//
//  Created by larry qiu on 3/16/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import UIKit

class DuckyViewController: UIViewController,UITextFieldDelegate{

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    var entry: Entry?;

    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self;
        contentsTextView.layer.borderWidth = 0.5
        contentsTextView.layer.borderColor = UIColor.gray.cgColor
        contentsTextView.layer.cornerRadius = 5.0

        if let entry=entry{
            nameTextField.text = entry.name;
            navigationItem.title = entry.name;
            contentsTextView.text = entry.contents;
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
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
        entry = Entry(entryType:.ducky, name:nameTextField.text ?? "", contents:contentsTextView.text ?? "")
    }
    
    private func updateSaveButtonState() {
        let nameText = nameTextField.text ?? "";
        saveButton.isEnabled = !nameText.isEmpty;
    }

}
