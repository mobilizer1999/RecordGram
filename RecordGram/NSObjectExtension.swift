//
//  NSObjectExtension.swift
//  RecordGram
//
//  Created by Mauro Taroco on 12/29/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation

extension NSObject {
    var className: String {
        return String(describing: type(of: self))
    }
    
    class var className: String {
        return String(describing: self)
    }
}
