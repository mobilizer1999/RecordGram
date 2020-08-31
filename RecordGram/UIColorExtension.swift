//
//  UIColorExtension.swift
//  RecordGram
//
//  Created by Hugo Prione on 6/24/16.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit

extension UIColor {
    static var primary: UIColor {
        return UIColor(red:1.00, green:0.91, blue:0.93, alpha:1.00)
    }

    static var secondary: UIColor {
        return UIColor(red:1.00, green:0.85, blue:0.90, alpha:1.00)
    }

    static var navBar: UIColor {
        return UIColor(red:0.82, green:0.40, blue:0.55, alpha:1.00)
    }

    static var navBarBackground: UIColor {
        return UIColor(red:0.96, green:0.78, blue:0.83, alpha:1.00)
    }

    static var calendar: UIColor {
        return UIColor(red:0.94, green:0.69, blue:0.76, alpha:1.00)
    }

    static var calendarToday: UIColor {
        return UIColor(red:0.88, green:0.60, blue:0.67, alpha:1.00)
    }

    static var calendarSelection: UIColor {
        return UIColor(red:0.99, green:0.46, blue:0.59, alpha:1.00)
    }

    static var status: UIColor {
        return UIColor(red:0.93, green:0.15, blue:0.30, alpha:1.00)
    }
    
    static var themeColor: UIColor {
        return UIColor(red:0.71, green:0.11, blue:0.35, alpha:1.00)
    }
    
    static var unreadColor: UIColor {
        return UIColor.rgb(red: 229, green: 229, blue: 229, alpha: 1.0)
    }
    
    static var grayTextColor: UIColor {
        return UIColor.init(hex: "7F7F7F")
    }
    
    static var themeBlueColor: UIColor {
        return UIColor.init(hex: "2DACEE")
    }
    
    
}
