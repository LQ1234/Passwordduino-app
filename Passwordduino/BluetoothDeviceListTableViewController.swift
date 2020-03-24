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

class BluetoothDeviceInfo{
    var lastRecievedAd:DispatchTime;
    let peripheral:CBPeripheral;
    var rssi:Double;
    var isPasswordduino:Bool=false;
    func peripheral(_ peripheral: CBPeripheral,
        didReadRSSI RSSI: NSNumber,
        error: Error?){
        rssi=RSSI.doubleValue;
    }
    
    init(_ peri:CBPeripheral, rssi:Double){
        peripheral=peri;
        self.rssi=rssi;
        lastRecievedAd=DispatchTime.now();
    }
    
    
}
class BluetoothDeviceListTableViewController: UITableViewController, CBCentralManagerDelegate {
    var foundPeripherals:[BluetoothDeviceInfo]=[];
    var bluetoothUpdateInterval: DispatchSourceTimer?=nil;
    
    private var centralManager: CBCentralManager!
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update");
        if central.state != .poweredOn {
            print("Central is not powered on");
        } else {
            print("Central scanning");
            centralManager.scanForPeripherals(withServices: nil,options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber(1)])
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var isPasswordduino=false;
        if let arr=advertisementData[CBAdvertisementDataServiceUUIDsKey] as? NSArray,let uuid=arr[0] as? CBUUID{
            if(uuid==PasswordduinoInfo.autoTypeServiceUUID){
                isPasswordduino=true;
            }
        }
        if let found=foundPeripherals.first(where: {$0.peripheral==peripheral}){
            found.lastRecievedAd=DispatchTime.now();
            found.rssi=RSSI.doubleValue;
            found.isPasswordduino=isPasswordduino;
        }else{
            tableView.beginUpdates()
            let bdi=BluetoothDeviceInfo(peripheral,rssi: RSSI.doubleValue);
            bdi.isPasswordduino=isPasswordduino;
            foundPeripherals.append(bdi);
            tableView.insertRows(at: [IndexPath(row: foundPeripherals.count-1, section: 0)], with: .automatic)
            tableView.endUpdates()
        }

    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return foundPeripherals.count;
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)  as? BluetoothDeviceListTableViewCell else{
            fatalError("The dequeued cell is of wrong type.")
        }
        let dinfo=foundPeripherals[indexPath.row];
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

    override func viewDidAppear(_ animated: Bool){
        bluetoothUpdateInterval = DispatchSource.makeTimerSource()
        bluetoothUpdateInterval!.schedule(deadline: .now(), repeating: TimeInterval(0.1))
        bluetoothUpdateInterval!.setEventHandler(handler: {[weak self] in
            DispatchQueue.main.async {
                var indxsToDelete:[Int]=[];
                let now=DispatchTime.now();
                for (indx,bdi) in self!.foundPeripherals.enumerated(){
                    let cell=self?.tableView.cellForRow(at: IndexPath(row:indx,section: 0)) as? BluetoothDeviceListTableViewCell;
                    if((now.uptimeNanoseconds-bdi.lastRecievedAd.uptimeNanoseconds)>1000000000){
                        indxsToDelete.append(indx);
                    }
                    cell?.deviceStrength?.text="\(bdi.rssi)";
                }
                self?.tableView.beginUpdates()
                for i in indxsToDelete.reversed(){
                    self?.foundPeripherals.remove(at: i)
                }
                self?.tableView.deleteRows(at:indxsToDelete.map{(i) in IndexPath(row:i,section: 0)},with:.automatic);
                self?.tableView.endUpdates()
            }
        });
        bluetoothUpdateInterval?.resume();
    }
    override func viewWillDisappear(_ animated: Bool){
        bluetoothUpdateInterval?.cancel();

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
