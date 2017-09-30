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

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        return identifier
    }
}

struct DeviceInfo {
    let isCharging: Bool?
    let deviceModel: String?

    static func currentDeviceInfo(withLogConfiguration configuration: LogConfiguration) -> DeviceInfo {
        let currentDevice = UIDevice.current

        let isCharging = configuration.shouldLogDeviceCharging ? currentDevice.isCharging : nil
        let deviceModel = configuration.shouldLogDeviceModel ? currentDevice.modelName : nil

        return DeviceInfo(isCharging: isCharging, deviceModel: deviceModel)
    }
}
