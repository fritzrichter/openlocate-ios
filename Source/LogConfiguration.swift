//
//  LogConfiguration.swift
//  OpenLocate
//
//  Created by Виктор Заикин on 29.09.2017.
//  Copyright © 2017 OpenLocate. All rights reserved.
//

public struct LogConfiguration {
    public let isNetworkInfoLogging: Bool
    public let isDeviceCourseLogging: Bool

    public static let `default` = LogConfiguration(isNetworkInfoLogging: true, isDeviceCourseLogging: true)
}
