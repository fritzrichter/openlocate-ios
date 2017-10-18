
![OpenLocate](http://imageshack.com/a/img922/4800/Pihgqn.png)

We’re building an open SDK to collect location data (like GPS) from phones, for apps like yours

## Purpose

### Why is this project useful?

OpenLocate is supported by developers, non-profits, trade groups, and industry for the following reasons:

* Collecting location data in a battery efficient manner that does not adversely affect mobile application performance is non-trivial. OpenLocate enables everyone in the community to benefit from shared knowledge around how to do this well.
* Creates standards and best practices for location collection.
* Developers have full transparency on how OpenLocate location collection works.
* Location data collected via OpenLocate is solely controlled by the developer.

### What can I do with location data?

Mobile application developers can use location data collected via OpenLocate to:

* Enhance their mobile application using context about the user’s location.
* Receive data about the Points of Interest a device has visited by enabling integrations with 3rd party APIs such as Google Places or Foursquare Venues
* Send location data to partners of OpenLocate via integrations listed here.

### Who is supporting OpenLocate?

OpenLocate is supported by mobile app developers, non-profit trade groups, academia, and leading companies across GIS, logistics, marketing, and more.

## Requirements
- iOS 10 onwards

## Installation

Cocoapods

If you use cocoapods, add the following line in your podfile and run `pod install`

```ruby
pod 'OpenLocate'
```

## Usage

### Initialize tracking

1. Add permission keys for location tracking in the `Info.plist` of your application

For **Xcode 9:**
```xml
<key>NSLocationAlwaysUsageDescription</key>
<string>OpenLocate would like to access location.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>OpenLocate would like to access location.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>OpenLocate would like to access location.</string>
```

If you are using **Xcode 8** you need one of these keys:
```xml
<key>NSLocationAlwaysUsageDescription</key>
<string>OpenLocate would like to access location.</string>
```
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>OpenLocate would like to access location.</string>
```

2. Configure where the SDK should send data to by building the configuration with appropriate URL and headers. Supply the configuration to the `initialize` method. Ensure that the initialize method is invoked in the `application:didFinishLaunchingWithOptions:` method in your `UIApplicationDelegate`

#### For example, to send data to SafeGraph:

Assuming you have a UUID and token from SafeGraph:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? ) -> Bool {

    let uuid = UUID(uuidString: "<YOUR_UUID>")!
    let token = "YOUR_TOKEN"
    
    let url = URL(string: "https://api.safegraph.com/v1/provider/\(uuid)/devicelocation")!
    let headers = ["Authorization": "Bearer \(token)"]
    
    let configuration = Configuration(url: url, headers: headers)
    
    do {
        try OpenLocate.shared.initialize(with: configuration)
    } catch {
        print(error)
    }
}
```


### Start tracking of location

To start the tracking location, call the `startTracking` method on the `OpenLocate`. Get the instance by calling `shared`.

```swift
OpenLocate.shared.startTracking()
```


### Stop tracking of location

To stop the tracking call `stopTracking` method on the `OpenLocate`. Get the instance by calling `shared`.

```swift
OpenLocate.shared.stopTracking()
```

### Check the current state of location tracking

Call `isTrackingEnabled` method on the `OpenLocate`. Get the instance by calling `shared`.

```swift
OpenLocate.shared.isTrackingEnabled()
```


### Fields collected by the SDK

The following fields are collected by the SDK to be sent to a private or public API:

1. `latitude` - Latitude of the device
2. `longitude` - Longitude of the device
3. `utc_timestamp` - Timestamp of the recorded location in epoch
4. `horizontal_accuracy` - The accuracy of the location being recorded
5. `id_type` - 'idfa' for identifying Apple device advertising type
6. `ad_id` - Advertising identifier
7. `ad_opt_out` - Limited ad tracking enabled flag
8. `course` - The direction in which the device is traveling
9. `speed` - The instantaneous speed of the device, measured in meters per second
10. `is_charging` - Indicates if device is charging
11. `device_model` - Model of the user's device
12. `os_version` - Version of the using OS on the device

By default all these fields are collected. Naturally, you can choose what fields you'd like to collect. You just need to set configuration in such way.
For example, you want to send all information except device course. Than you should do so:

```swift
    let fieldsConfiguration = CollectingFieldsConfiguration.Builder()
                               .set(shouldLogDeviceCourse: false)
                               .build()
    let configuration = Configuration(url: url, headers: headers, collectingFieldsConfiguration: fieldsConfiguration)
```

## Communication

- If you **need help**, post a question to the [discussion forum](https://groups.google.com/a/openlocate.org/d/forum/openlocate), or tag a question with 'OpenLocate' on [Stack Overflow](https://stackoverflow.com).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.
