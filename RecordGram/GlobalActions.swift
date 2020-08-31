//
//  GlobalActions.swift
//  RecordGram
//
//  Created by Roman Salazar Lopez on 9/13/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import Foundation
import UIKit
import DeviceKit


func deviceName() -> String {
    let device = Device()
    print(device)
    return device.description
}
