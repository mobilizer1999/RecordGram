//
//  DoubleExtension.swift
//  RecordGram
//
//  Created by Hugo Prione on 13/11/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation

extension Double {
    func durationString() -> String {
        guard !self.isNaN else {
            return ""
        }
        let value = Int(self)
        let seconds = value % 60
        let minutes = (value / 60) % 60
        
        if value <= 3600 {
            return String(format: "%0.2d:%0.2d", minutes, seconds)
        }
        
        let hours = (value / 3600)
        
        return String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }
}
