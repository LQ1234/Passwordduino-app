//
//  BluetoothDeviceListTableViewController.swift
//  Passwordduino
//
//  Created by larry qiu on 3/23/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth
class PasswordduinoInfo: NSObject {
    public static let autoTypeServiceUUID = CBUUID.init(string: "2d0ed66b-d9de-4dff-8e64-b8ded832079b")
    public static let encryptedDataUUID = CBUUID.init(string: "93752cf0-9ecc-44ae-a90f-1261766b8869")
    public static let decryptedDataLengthUUID = CBUUID.init(string: "93752cf1-9ecc-44ae-a90f-1261766b8869")
    public static let isPasswordUUID = CBUUID.init(string: "93752cf2-9ecc-44ae-a90f-1261766b8869")
    public static let syncNumUUID = CBUUID.init(string: "93752cfb-3ecc-44ae-a90f-1261766b8869")
}

class BluetoothDeviceListTableViewController: UITableViewController, CBPeripheralDelegate, CBCentralManagerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
