//
//  Person.swift
//  People
//
//  Created by Huy Bui on 2022-07-15.
//

import UIKit

class Person: NSObject {
    
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
