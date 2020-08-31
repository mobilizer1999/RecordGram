//
//  UIImageExtension.swift
//  RecordGram
//
//  Created by Mauro Taroco on 20/1/18.
//  Copyright © 2018 Meridian Inc. All rights reserved.
//

import UIKit

extension UIImage {
    class func templateImage(name: String) -> UIImage? {
        return UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
    }
}
