//
//  StringExtension.swift
//  RecordGram
//
//  Created by Mauro Taroco on 11/22/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation

extension String {
    
    func isValidMediaName() -> Bool {
        let stricterFilterString = "[A-Z0-9a-z ]*"
        let stringTest = NSPredicate(format: "SELF MATCHES %@", stricterFilterString)
        let isValid: Bool = stringTest.evaluate(with: self)
        return isValid
    }

    var decodeEmoji: String {
        guard let data = self.data(using: String.Encoding.utf8) else {
            return self
        }
        guard let str = NSString(data: data, encoding: String.Encoding.nonLossyASCII.rawValue) as String? else {
            return self
        }

        return str
    }
}
