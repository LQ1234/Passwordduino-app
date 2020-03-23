//
//  Entry.swift
//  Passwordduino
//
//  Created by larry qiu on 3/16/20.
//  Copyright © 2020 Larry's Tech. All rights reserved.
//

import Foundation;
enum EntryType:Int{
    case ducky;
    case password;
}
struct PropertyKey {
    static let entryType = "entryType"
    static let name = "name"
    static let contents = "contents"
}
class Entry: NSObject, NSCoding {
    let entryType:EntryType;
    var name:String;
    var contents:String;
    init( entryType:EntryType, name:String, contents:String){
        self.entryType=entryType;
        self.name=name;
        self.contents=contents;
    }
    func encode(with encoder: NSCoder) {
        encoder.encode(entryType.rawValue, forKey: PropertyKey.entryType)
        encoder.encode(name, forKey: PropertyKey.name)
        encoder.encode(contents, forKey: PropertyKey.contents)
    }
    required convenience init?(coder decoder: NSCoder) {
        
        guard let entryType = EntryType(rawValue: decoder.decodeInteger(forKey: PropertyKey.entryType)) else {
            return nil
        }
        guard let name = decoder.decodeObject(forKey: PropertyKey.name) as? String else {
            return nil
        }
        guard let contents = decoder.decodeObject(forKey: PropertyKey.contents) as? String else {
            return nil
        }
        self.init(entryType:entryType, name:name, contents:contents)

    }
    static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveURL = documentsDirectory.appendingPathComponent("entries")
}
