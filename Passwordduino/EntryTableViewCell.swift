//
//  EntryTableViewCell.swift
//  Passwordduino
//
//  Created by larry qiu on 3/16/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import UIKit

class EntryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var entryTypeImage: UIImageView!
    @IBOutlet weak var entryLabel: UILabel!
    weak var viewController: EntryTableViewController!
    weak var entry:Entry!;
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        
    }
    @IBAction func editButtonClicked(_ sender: Any) {
        viewController.currentlyEditing=self
        
        switch(entry.entryType){
            case .password:viewController.performSegue(withIdentifier: "editPasswordSegue", sender: viewController);
            case .ducky:viewController.performSegue(withIdentifier: "editDuckySegue", sender: viewController);
        }
    }
    
}
