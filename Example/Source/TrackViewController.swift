//
//  TrackViewController.swift
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

import UIKit
import OpenLocate
import CoreLocation

class TrackViewController: UIViewController, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.titleView = UIImageView(image: UIImage(named: "tab_logo"))

        if OpenLocate.shared.isTrackingEnabled {
            onStartTracking()
        }

        locationManager.delegate = self
    }

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var appSettingsButton: UIButton!

    @IBAction func startTracking(_ sender: Any) {
        OpenLocate.shared.startTracking()
        onStartTracking()
    }

    @IBAction func stopTracking(_ sender: Any) {
        OpenLocate.shared.stopTracking()
        onStopTracking()
    }

    private func onStartTracking() {
        startButton.isHidden = true
        stopButton.isHidden = false
    }

    private func onStopTracking() {
        startButton.isHidden = false
        stopButton.isHidden = true
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        errorLabel.isHidden = false
        appSettingsButton.isHidden = false

        switch status {
        case .denied:
            errorLabel.text = "Location Permission Denied"
        case .authorizedWhenInUse:
            errorLabel.text = "Location Permission is only When In Use"
        case .restricted:
            errorLabel.text = "Location Services is Restricted"
        default:
            errorLabel.isHidden = true
            appSettingsButton.isHidden = true
        }
    }

    @IBAction func didTapAppSettingsButton() {
        if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(appSettings)
            }
        }
    }
}
