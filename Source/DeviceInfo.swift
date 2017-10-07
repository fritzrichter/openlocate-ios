//
//  DeviceInfo.swift
//  OpenLocate
//
//  Created by Виктор Заикин on 30.09.2017.
//  Copyright © 2017 OpenLocate. All rights reserved.
//

import Foundation
import UIKit.UIDevice

extension UIDevice {
    var isCharging: Bool {
        return batteryState == .charging
    }
}

struct DeviceInfo {
    let isCharging: Bool?

    static func currentDeviceInfo(configuration: CollectingFieldsConfiguration) -> DeviceInfo {
        let currentDevice = UIDevice.current
        let isCharging = configuration.shouldLogDeviceCharging ? currentDevice.isCharging : nil

        return DeviceInfo(isCharging: isCharging)
    }
}
