//
//  Bluetooth.swift
//  Passwordduino
//
//  Created by larry qiu on 3/25/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import Foundation

import CoreBluetooth
class PasswordduinoInfo: NSObject {
    public static let autoTypeServiceUUID       = CBUUID.init(string: "93752cf0-9ecc-44ae-a90f-1261766b8869")
    public static let encryptedDataUUID         = CBUUID.init(string: "93752cf1-9ecc-44ae-a90f-1261766b8869")
    public static let decryptedDataLengthUUID   = CBUUID.init(string: "93752cf2-9ecc-44ae-a90f-1261766b8869")
    public static let syncNumUUID               = CBUUID.init(string: "93752cf4-9ecc-44ae-a90f-1261766b8869")
}

class PasswordduinoPeripheralManager:NSObject,CBPeripheralDelegate{
    let peripheral:CBPeripheral;
    
    var encryptedDataChar:CBCharacteristic?=nil;
    var decryptedDataLengthChar:CBCharacteristic?=nil;
    var syncNumChar:CBCharacteristic?=nil;
    
    init(_ peri:CBPeripheral){
        peripheral=peri;
        super.init();
        peripheral.delegate=self;
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //print("DISCORERED SERV");
        if let services = peripheral.services,let autoTypeService=services.first{
            //print("FORUND SERV");

            peripheral.discoverCharacteristics([PasswordduinoInfo.encryptedDataUUID,PasswordduinoInfo.decryptedDataLengthUUID,PasswordduinoInfo.syncNumUUID], for: autoTypeService)
        }
    }

    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == PasswordduinoInfo.encryptedDataUUID {
                    //print("encryptedDataUUID found");
                    encryptedDataChar=characteristic;
                    //print(peripheral.maximumWriteValueLength(for: .withResponse));
                    //print(peripheral.maximumWriteValueLength(for: .withoutResponse));

                } else if characteristic.uuid == PasswordduinoInfo.decryptedDataLengthUUID {
                    //print("decryptedDataLengthUUID found");
                    decryptedDataLengthChar=characteristic;
                } else if characteristic.uuid == PasswordduinoInfo.syncNumUUID {
                    //print("syncNumUUID found");
                    syncNumChar=characteristic;
                }
            }
        }
    }
    private var writeCallbacks:[CBCharacteristic:[(Error?)->Void]]=[:];
    private var readCallbacks:[CBCharacteristic:[(Data?,Error?)->Void]]=[:];
    
    func write(_ data: Data,to characteristic:CBCharacteristic,callback:@escaping (Error?)->Void){
        if writeCallbacks[characteristic] == nil{
            writeCallbacks[characteristic]=[];
        }
        writeCallbacks[characteristic]!.append(callback);
        //print("sending somethinng");

        peripheral.writeValue(data, for: characteristic,type:.withResponse)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        //print("written somethinng");

        if let cbs=writeCallbacks[characteristic]{
            for cb in cbs{
                cb(error)
            }
            writeCallbacks.removeValue(forKey: characteristic)
        }
    }
    func read(from characteristic:CBCharacteristic,callback:@escaping (Data?,Error?)->Void){
        if readCallbacks[characteristic] == nil{
            readCallbacks[characteristic]=[];
        }
        readCallbacks[characteristic]!.append(callback);
        peripheral.readValue(for: characteristic)
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        //print("somethinng got updatedd");

        if let cbs=readCallbacks[characteristic]{
            for cb in cbs{
                cb(characteristic.value,error);
            }
            readCallbacks.removeValue(forKey: characteristic)
        }
    }
    func sendEncrypted(data:Data, callback:@escaping (String?)->Void){
        if let encrypted=encrypt(data){
            send(data:encrypted,callback: callback);
        }else{
            callback("Error encrypting message");
        }
    }
    func send(data:Data, callback:@escaping (String?)->Void){
        if let decryptedDataLengthChar = decryptedDataLengthChar{
            var count:Int32 = Int32(data.count).littleEndian;
            let countData = Data(bytes: &count, count: MemoryLayout.size(ofValue: count))
            write(countData,to: decryptedDataLengthChar){ (error) in
                if let error=error{
                    callback("Write error:\(error.localizedDescription)")
                }else{
                    self.send(data:data,index:0,callback:callback);
                }
            }

        }else{
            callback("Decrypted data length characteritic not found");
        }

    }
    private func send(data:Data,index:Int,callback:@escaping (String?)->Void){
        //print("SENDING");
        if let encryptedDataChar=encryptedDataChar,
            let syncNumChar=syncNumChar{
            //print("srying to dsesnd \(data.subdata(in: index..<min(index+200,data.count))) which is \([UInt8](data.subdata(in: index..<min(index+200,data.count))))")
            write(data.subdata(in: index..<min(index+200,data.count)),to:encryptedDataChar){ (error) in
                //print("encryptedDataChar WRITTEN");

                if let error=error{
                    callback("Write encryptedDataChar error: \(error.localizedDescription)")
                }else{
                    self.read(from:syncNumChar){(res,error) in
                        //print("syncNumChar READ");
                        if let error=error{
                            callback("Read syncNumChar error: \(error.localizedDescription)")
                        }else{
                            var currSyncNum:UInt8=([UInt8](res!))[0];
                            //print("current value:\(currSyncNum)");

                            currSyncNum&+=1;
                            self.write(Data([currSyncNum]),to:syncNumChar){(error) in
                                //print("syncNumChar WRITTEN");

                                if let error=error{
                                    callback("Write syncNumChar error: \(error.localizedDescription)")
                                }else{
                                    //print("index:\(index) data.count \(data.count)");

                                    if(index+200>=data.count){
                                        callback(nil);
                                    }else{
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            //print("RECURSIONM");
                                            self.send(data: data, index: index+200,callback: callback);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }else{
            callback("Encrypted data or Sync num characteritic not found");
        }
    }
    
    static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static var previouslyConnectedPeripheralArchiveURL = documentsDirectory.appendingPathComponent("previouslyConnectedPeripheral")
}
class AdvertisedPeripheralInfo{
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
class BluetoothWrapper:NSObject, CBCentralManagerDelegate{
    var foundPeripherals:[AdvertisedPeripheralInfo]=[];
    private var oldDeviceRemovalInterval: DispatchSourceTimer?=nil;
    private var centralManager: CBCentralManager?=nil;
    func startScan(){
        print("start");

        if centralManager == nil{
            centralManager = CBCentralManager(delegate: self, queue: nil)
            oldDeviceRemovalInterval = DispatchSource.makeTimerSource()
            oldDeviceRemovalInterval!.schedule(deadline: .now(), repeating: TimeInterval(5))
            oldDeviceRemovalInterval!.setEventHandler(handler: {[unowned self] in
                DispatchQueue.main.async {
                    var indxsToDelete:[Int]=[];
                    let now=DispatchTime.now();
                    for (indx,bdi) in self.foundPeripherals.enumerated(){
                        if((now.uptimeNanoseconds-bdi.lastRecievedAd.uptimeNanoseconds)>15000000000&&bdi.peripheral != self.selectedPasswordduino?.peripheral){
                            indxsToDelete.append(indx);
                        }
                    }
                    if(self.deletionCallback==nil){
                        for i in indxsToDelete.reversed(){
                            self.foundPeripherals.remove(at: i)
                        }
                    }else{
                        self.deletionCallback?(indxsToDelete){
                            for i in indxsToDelete.reversed(){
                                self.foundPeripherals.remove(at: i)
                            }
                        };
                    }
                    //print("OOOF");
                }
            });
            oldDeviceRemovalInterval!.resume();
        }
        if let select=selectCallback{
            if(selectedPasswordduino==nil){
                select(nil)
            }
        }
    }
    func stopScan(){
        print("stop");

        oldDeviceRemovalInterval?.cancel();
        centralManager?.stopScan();
        if let sp = selectedPasswordduino{
            centralManager?.cancelPeripheralConnection(sp.peripheral);
            
        }
        selectedPasswordduino=nil;
        oldDeviceRemovalInterval=nil;
        centralManager=nil;
        
    }
    private var insertionCallback: (([Int],()->Void) -> Void)?=nil;
    private var deletionCallback: (([Int],()->Void) -> Void)?=nil;
    private var changeCallback: ((Int) -> Void)?=nil;
    private var selectCallback: ((Int?) -> Void)?=nil;
    
    private var previouslyConnectedUUID:UUID?={
        if let archivedData = try? Data(contentsOf: PasswordduinoPeripheralManager.previouslyConnectedPeripheralArchiveURL)  {
            if let uuid = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedData) as? UUID {
                return(uuid);
            }
        }
        return nil;
    }();
    public private(set) var selectedPasswordduino:PasswordduinoPeripheralManager?=nil{
        didSet {
            if let uuid=selectedPasswordduino?.peripheral.identifier,
               let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: uuid, requiringSecureCoding: false){
                try? archivedData.write(to: PasswordduinoPeripheralManager.previouslyConnectedPeripheralArchiveURL);
            }
        }
    };
    
    func registerBluetoothPeripheralTableCallbacks(insertion:@escaping ([Int],()->Void)-> Void,deletion:@escaping ([Int],()->Void)-> Void,change:@escaping (Int)-> Void,select:@escaping (Int?)-> Void){
        print("register");

        insertionCallback=insertion;
        deletionCallback=deletion;
        changeCallback=change;
        selectCallback=select;
    
        
        if let selected=selectedPasswordduino,let indx=foundPeripherals.firstIndex(where:{$0.peripheral.identifier==selected.peripheral.identifier}){
            select(indx);
        }
    }
    func removeBluetoothPeripheralTableCallbacks(){
        print("remove");

        insertionCallback=nil;
        deletionCallback=nil;
        changeCallback=nil;
        selectCallback=nil;
    }
    
    func connect(index:Int){
        selectedPasswordduino=PasswordduinoPeripheralManager(foundPeripherals[index].peripheral);
        centralManager?.connect(foundPeripherals[index].peripheral)
        
        print("connecting ");

    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if(peripheral.identifier==selectedPasswordduino?.peripheral.identifier){
            peripheral.discoverServices(nil)
        }
    }
    internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral \(peripheral)");
        if(peripheral.identifier==selectedPasswordduino?.peripheral.identifier){
            selectedPasswordduino=nil;
            selectCallback?(nil);
        }
    }
    internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect \(peripheral)");

        if(peripheral.identifier==selectedPasswordduino?.peripheral.identifier){
           selectedPasswordduino=nil;
           selectCallback?(nil);
        }
    }
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            print("Central is not powered on");
        } else {
            central.scanForPeripherals(withServices: nil,options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber(1)])
        }
    }
    internal func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var isPasswordduino=false;

        if let arr=advertisementData[CBAdvertisementDataServiceUUIDsKey] as? NSArray,let uuid=arr[0] as? CBUUID{

            if(uuid==PasswordduinoInfo.autoTypeServiceUUID){
                isPasswordduino=true;
                //print("foundDuino \(selectedPasswordduino)");
                //print("this \(peripheral.identifier) last \(previouslyConnectedUUID)");
            }
        }
        if let foundIndex=foundPeripherals.firstIndex(where: {$0.peripheral.identifier==peripheral.identifier}){
            let found=foundPeripherals[foundIndex];
            found.lastRecievedAd=DispatchTime.now();
            found.rssi=found.rssi*0.3+RSSI.doubleValue*0.7;
            found.isPasswordduino=isPasswordduino;
            changeCallback?(foundIndex);
            if(peripheral.identifier==previouslyConnectedUUID&&selectedPasswordduino==nil){
                connect(index:foundIndex);
                selectCallback?(foundIndex);
                //print("RECONNECTIN");
            }
        }else{
            let bdi=AdvertisedPeripheralInfo(peripheral,rssi: RSSI.doubleValue);
            bdi.isPasswordduino=isPasswordduino;
            let newIndex=foundPeripherals.count;
            if(insertionCallback == nil){
                foundPeripherals.append(bdi);
            } else {
                insertionCallback?([newIndex]){
                    foundPeripherals.append(bdi);
                };
            }
            if(peripheral.identifier==previouslyConnectedUUID&&selectedPasswordduino==nil){
                connect(index:newIndex);
                selectCallback?(newIndex);
                //print("RECONNECTIN");
            }
        }

    }


}
var bluetoothWrapper=BluetoothWrapper();

