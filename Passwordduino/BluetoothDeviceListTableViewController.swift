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

class BluetoothDeviceListTableViewController: UITableViewController {
    
    private var entryTableViewController:EntryTableViewController!;
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool){
        bluetoothWrapper.registerBluetoothPeripheralTableCallbacks(insertion: { [unowned self] (indexes,doChanges) in
                self.tableView.beginUpdates()
                doChanges();
                self.tableView.insertRows(at: indexes.map{IndexPath(row:$0,section: 0)}, with: .automatic)
                self.tableView.endUpdates()
            }, deletion: {[unowned self] (indexes,doChanges) in
                self.tableView.beginUpdates()
                doChanges();
                self.tableView.deleteRows(at: indexes.map{IndexPath(row:$0,section: 0)}, with: .automatic)
                self.tableView.endUpdates()
            }, change: { [unowned self] (index) in
                self.tableView.reloadRows(at: [IndexPath(row:index,section: 0)], with: .none)
            }, select: { [unowned self] (index) in
                if let index=index{
                    self.tableView.selectRow(at:IndexPath(row:index,section: 0), animated: false, scrollPosition:.none);
                }else{
                    if let index = self.tableView.indexPathForSelectedRow{
                        self.tableView.deselectRow(at: index, animated: false)
                    }
                }
            }
        );
        print("viewDidAppear");

    }
    
    override func viewWillDisappear(_ animated: Bool){
        bluetoothWrapper.removeBluetoothPeripheralTableCallbacks();
        print("viewWillDisappear");
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return bluetoothWrapper.foundPeripherals.count;
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)  as? BluetoothDeviceListTableViewCell else{
            fatalError("The dequeued cell is of wrong type.")
        }
        let dinfo=bluetoothWrapper.foundPeripherals[indexPath.row];
        cell.label.text = dinfo.peripheral.name ?? "Unknown name";
        cell.deviceStrength.text="\(dinfo.rssi)";
        if(dinfo.isPasswordduino){
            cell.isUserInteractionEnabled=true;
            cell.label.isEnabled=true;
            cell.deviceStrength.isEnabled=true;
        }else{
            cell.isUserInteractionEnabled=false;
            cell.label.isEnabled=false;
            cell.deviceStrength.isEnabled=false;
        }
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bluetoothWrapper.connect(index: indexPath.row)
    }
    
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
