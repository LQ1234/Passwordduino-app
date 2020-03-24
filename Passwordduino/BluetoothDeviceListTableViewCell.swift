//
//  BluetoothDeviceListTableViewCell.swift
//  Passwordduino
//
//  Created by Larry Qiu on 3/23/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import UIKit

class BluetoothDeviceListTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var deviceStrength: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {

        super.setSelected(selected, animated: animated)
        

        // Configure the view for the selected state
    }

}
