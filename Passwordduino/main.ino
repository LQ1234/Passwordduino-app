//https://github.com/arduino/ArduinoCore-nRF528x-mbedos/tree/master/libraries/USBHID
#include "USBKeyboard.h"

USBKeyboard keyboard(true, 0x046d, 0xc31c, 64); //sorry logitech

void type(const char* string) {
  keyboard.printf(string);
}

#include <ArduinoBLE.h>

struct PasswordduinoBLECtx {
  BLEService autoTypeService;
  BLECharacteristic encryptedData;
  BLEUnsignedIntCharacteristic decryptedDataLength;
  BLEUnsignedCharCharacteristic syncNum;
  BLEDevice connectedTo;
  unsigned char* recievedEncrypted = NULL;  //  0ED66BD9-DEFC-0DFF-8E64-B8DED832079B
  unsigned int recievedEncryptedLength = 0;
  unsigned char* recievedDecrypted = NULL;
  unsigned int recievedDecryptedLength = 0;

  PasswordduinoBLECtx(): autoTypeService("93752cf0-9ecc-44ae-a90f-1261766b8869"),
    encryptedData("93752cf1-9ecc-44ae-a90f-1261766b8869", BLEWrite | BLERead, 200, false),
    decryptedDataLength("93752cf2-9ecc-44ae-a90f-1261766b8869", BLEWrite | BLERead),
    syncNum("93752cf4-9ecc-44ae-a90f-1261766b8869", BLEWrite | BLERead | BLENotify) {
    autoTypeService.addCharacteristic(encryptedData);
    autoTypeService.addCharacteristic(decryptedDataLength);
    autoTypeService.addCharacteristic(syncNum);
  }
};
PasswordduinoBLECtx* bleCtx;
void initBLE() {
  if (!BLE.begin()) {
    //Serial.println("starting BLE failed!");

    while (1);
  }
  bleCtx = new PasswordduinoBLECtx();

  BLE.setLocalName("Passwordduino");
  BLE.setDeviceName("Passwordduino");

  BLE.setAppearance(961);
  BLE.addService(bleCtx->autoTypeService);
  BLE.setAdvertisedService(bleCtx->autoTypeService);

  BLE.advertise();
}



bool waitUntilSyncChange() {
  unsigned char initial;
  //Serial.println("Waiting for sync change");

  bleCtx->syncNum.readValue(initial);

  unsigned char current = initial;

  while (current == initial) {
    BLE.poll(100);
    if (!bleCtx->connectedTo.connected()) {
      return (false);
    }
    BLE.poll(100);
    //if (bleCtx->syncNum.valueUpdated()) {
    bleCtx->syncNum.readValue(current);
    //}
    //Serial.println("Waiting for sync change, initial: "+String(initial)+" current: "+String(current));

  }
  //Serial.println("Sync changed");
  return (true);
}
//-------- BLE helper --------

bool recieve() {
  if (bleCtx->recievedEncrypted != NULL) {
    delete[] bleCtx->recievedEncrypted;
    bleCtx->recievedDecrypted = NULL;
  }
  uint32_t toRecieve;
  BLE.poll(100);
  bleCtx->decryptedDataLength.readValue(toRecieve);
  //Serial.println("toRecieve " + String(toRecieve));

  if (toRecieve == 0) {
    return (false);
  }

  bleCtx->recievedEncrypted = new uint8_t[toRecieve]; //max characteristic size
  bleCtx->recievedEncryptedLength = toRecieve;
  unsigned int totalRecieved = 0;

  while (totalRecieved < toRecieve) {
    if (!waitUntilSyncChange()) {
      return (false);
    }
    int packetLength = bleCtx->encryptedData.valueSize();
    //Serial.println("recieved "+String(packetLength));

    BLE.poll(100);
    bleCtx->encryptedData.readValue(bleCtx->recievedEncrypted + totalRecieved, packetLength);

    totalRecieved += packetLength;


  }
  for (int i = 0; i < toRecieve; i++) {
    //Serial.print((char)bleCtx->recievedEncrypted[i]);
  }
  //Serial.println();
  bleCtx->encryptedData.setValue("");
  bleCtx->decryptedDataLength.setValue(0);
  bleCtx->syncNum.setValue(0);
  return (true);
}
#include "src/Crypto/Crypto.h"
#include "src/Crypto/ChaChaPoly.h"
ChaChaPoly chaChaPoly;

uint8_t presharedKey[32] = {0x99, 0x5f, 0xb8, 0x9d, 0x83, 0xab, 0xee, 0x46, 0xa3, 0xbf, 0x55, 0x6e, 0x43, 0xeb, 0xac, 0x58, 0x9e, 0xf9, 0xf3, 0xfe, 0x07, 0xd0, 0xb6, 0x22, 0x6f, 0xc5, 0x1c, 0xbe, 0xd6, 0xfc, 0x3b, 0xf5};

bool recieveAndDecrypt() {
  if (!recieve())return (false);
  if (!chaChaPoly.setKey(presharedKey, 32)) {
    //Serial.println("Key unsupported");
    return (false);
  }
  if (!chaChaPoly.setIV(bleCtx->recievedEncrypted, 12)) {
    //Serial.println("IV unsupported");
    return (false);
  }
  if (bleCtx->recievedDecrypted != NULL) {
    delete[] bleCtx->recievedDecrypted;
    bleCtx->recievedDecrypted = NULL;
  }

  if (bleCtx->recievedEncryptedLength < 12) {
    //Serial.println("Recieved length too small");
    return (false);
  }
  bleCtx->recievedDecrypted = new uint8_t[bleCtx->recievedEncryptedLength - 12]; //max characteristic size
  bleCtx->recievedDecryptedLength = bleCtx->recievedEncryptedLength - 12;
  //Serial.println("Decrypting...");
  chaChaPoly.decrypt(bleCtx->recievedDecrypted, bleCtx->recievedEncrypted + 12, bleCtx->recievedDecryptedLength);
  //Serial.println("Decrypted:");


  for (int i = 0; i < bleCtx->recievedDecryptedLength; i++) {
    //Serial.print((char) bleCtx->recievedDecrypted[i]);
  }
  //Serial.println();
  return (true);
}
/*
  enum ByteCodeType:UInt8{
    case rawHID=0
    case text
    case delay
  }
*/
void runBytecode(unsigned char* inp, unsigned int len) {
  int indx = 0;
  while (indx < len) {
    switch (inp[indx++]) {
      case 0:
        //Serial.println("HID");
        HID_REPORT report;
        report.length=9;
        memcpy(report.data, inp + indx, 9);
        if (!keyboard.send(&report)) {
            //error
            while(true){
            }
        }
        indx += 9;
        break;
      case 1:
        {
          uint32_t len;

          //Serial.println("Text: ");
          memcpy(&len, inp + indx, 4);
          indx += 4;
          for (int i = 0; i < len; i++) {
            Serial.print((char)inp[indx]);
            keyboard._putc(inp[indx]);
            indx++;
          }
          //Serial.println();
        }
        break;
      case 2:
        {
          uint32_t len;

          memcpy(&len, inp + indx, 4);
          indx += 4;
          delay(len);
          //Serial.println("Sleep: "+String(len));

        }
        break;
      default:
        break;
        //Serial.println("Unknown command");

    }

  }
}
int main() {


  initBLE();

  while (1) {

    BLE.poll(100);

    bleCtx->connectedTo = BLE.central();

    if (bleCtx->connectedTo)
    {
      //Serial.println("Connected");

      while (true) {
        delay(100);
        BLE.poll(100);
        if (!bleCtx->connectedTo.connected()) {
          break;
          //Serial.println("Disconnected");

        }
        if (recieveAndDecrypt()) {
          //Serial.println("Recieve success");
          runBytecode(bleCtx->recievedDecrypted, bleCtx->recievedDecryptedLength);
        }

      }
    }
    delay(200);
    //Serial.println("Loop");
  }
}
