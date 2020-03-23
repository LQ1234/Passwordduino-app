//
//  PasswordOrDuckyViewController.swift
//  Passwordduino
//
//  Created by larry qiu on 3/16/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import UIKit

class PasswordOrDuckyViewController: UIViewController {
    weak var rootView:EntryTableViewController?;

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func choiceMadePassword(_ sender: Any) {
        exitToAddNewEntry(entryType:.password);

    }
    @IBAction func choiceMadeDucky(_ sender: Any) {
        exitToAddNewEntry(entryType:.ducky);
    }
    
    private func exitToAddNewEntry(entryType:EntryType){
        if let parent = rootView {
            dismiss(animated: true, completion: {
                parent.editAndAddNewEntry(entryType: entryType);
            });
        }
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

