//
//  Person.swift
//  People
//
//  Created by Huy Bui on 2022-07-15.
//

import Foundation

//class Person: NSObject {
//class Person: NSObject, NSCoding { // Modified class definition to use with NSKeyedArchiver
class Person: NSObject, Codable {
    // NSCoding-required functions
//    required init?(coder: NSCoder) {
//        name = coder.decodeObject(forKey: "name") as? String ?? ""
//        image = coder.decodeObject(forKey: "image") as? String ?? ""
//    }
//
//    func encode(with coder: NSCoder) {
//        coder.encode(name, forKey: "name")
//        coder.encode(image, forKey: "image")
//    }
    
    var name: String,
        image: String?
    
    init(name: String, image: String?) {
        self.name = name
        self.image = image
    }
    
    init(name: String) {
        self.name = name
        self.image = nil
    }

}
