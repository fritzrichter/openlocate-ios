//
//  OpenLocateError.swift
//
//  Copyright (c) 2017 OpenLocate
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public enum OpenLocateError: Error {
    case invalidConfiguration(message: String)
    case locationMissingAuthorizationKeys(message: String)
    case locationFailure(message: String)

    struct ErrorMessage {
        static let invalidConfigurationMessage = "Invalid Configuration. Please provide a correct url"
        static let missingAuthorizationKeysMessage = "Authorization keys are missing. Please add in plist file."
        static let noCurrentLocationExists = "There is currently no location"
    }
}

public enum PlaceError: Error {
    case invalidLocationJson(message: String)

    struct ErrorMessage {
        static let invalidLocationJsonMessage = "Invalid location. Please try again"
    }
}

enum OpenLocateLocationError: Error {
    case unarchivingCannotBeDone
}
