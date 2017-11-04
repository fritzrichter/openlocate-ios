
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

### Using user's location to query 3rd party Places APIs

To use user's current location, obtain the location by calling `fetchCurrentLocation` method on OpenLocate. Get the instance by calling `shared`. Use the fields collected by SDK to send to 3rd party APIs.

#### For example, to obtain user location:

```swift
try OpenLocate.shared.fetchCurrentLocation { location, error in
  if let location = location {
    fetchNearbyPlaces(location: location)
  } else {
    debugPrint(error.localizedDescription)
  }
}
```

#### For example, to query Google Places API using location:

Google Places API: https://developers.google.com/places/web-service/search

```swift

func fetchNearbyPlaces(location: OpenLocateLocation, completion: @escaping GooglePlacesCompletionHandler) {
        guard let coordinates = location.locationFields.coordinates else {
            completion(nil, GooglePlacesError.locationNotFound)
            return
        }

        let queryParams = [
            "location": "\(coordinates.latitude),\(coordinates.longitude)",
            "radius": "500",
            "type": "restaurant",
            "keyword": "south",
            "key": "<YOUR GOOGLE PLACES API KEY>"
            ] as [String : Any]

        Alamofire.request(
            "https://maps.googleapis.com/maps/api/place/nearbysearch/json",
            parameters: queryParams
        )
            .responseJSON { response in
                debugPrint(response)
                guard let json = response.result.value as? [String: Any],
                    let placesJson = json["places"] as? [Any], !placesJson.isEmpty else {
                    completion(nil, GooglePlacesError.placesNotFound)
                    return
                }

                var places = [GooglePlace]()
                for placeJson in placesJson {
                    let place = (placeJson as? [String: Any])!
                    places.append(GooglePlace(json: place))
                }

                completion(places, nil)
        }
    }

```

#### For example, to query Safegraph Places API using location:

SafeGraph Places API: https://developers.safegraph.com/docs/places.html

```swift

func fetchNearbyPlaces(location: OpenLocateLocation, completion: @escaping SafePlacesCompletionHandler) {
        guard let coordinates = location.locationFields.coordinates else {
            completion(nil, SafeGraphError.locationNotFound)
            return
        }

        let queryParams = [
            "advertising_id": location.advertisingInfo.advertisingId,
            "advertising_id_type": "aaid",
            "latitude": coordinates.latitude,
            "longitude": coordinates.longitude,
            "horizontal_accuracy": location.locationFields.horizontalAccuracy
            ] as [String : Any]

        Alamofire.request(
            "https://api.safegraph.com/places/v1/nearby",
            parameters: queryParams,
            headers: ["Authorization": "Bearer <YOUR_TOKEN>"]
        )
            .responseJSON { response in
                debugPrint(response)
                guard let json = response.result.value as? [String: Any],
                    let placesJson = json["places"] as? [Any], !placesJson.isEmpty else {
                    completion(nil, SafeGraphError.placesNotFound)
                    return
                }

                var places = [SafeGraphPlace]()
                for placeJson in placesJson {
                    let place = (placeJson as? [String: Any])!
                    places.append(SafeGraphPlace(json: place))
                }

                completion(places, nil)
        }
    }

```

Similarly, OpenLocate SDK can be used to query additional APIs such as Facebook Places Graph or any other 3rd party places API.

- Facebook Places API - https://developers.facebook.com/docs/places/

## Fields collected for request

| Fields | Type | Description | Flag to enable |
| ------ | ---- | ----------- | -------------- |
|ad_id|String|An alphanumeric string unique to each device, used only for serving advertisements. More [here](https://developer.apple.com/documentation/adsupport/asidentifiermanager).|CollectingFieldsConfiguration.shouldLogAdId|
|ad_opt_out|Boolean|A Boolean value that indicates whether the user has limited ad tracking. More [here](https://developer.apple.com/documentation/adsupport/asidentifiermanager).|CollectingFieldsConfiguration.shouldLogAdId|
|id_type|String|A string value that indicates which operating systen advertising info belongs to. 'idfa' for iOS devices|CollectingFieldsConfiguration.shouldLogAdId|
|latitude|Decimal|The latitude in degrees.|CollectingFieldsConfiguration.shouldLogLocation|
|longitude|Decimal|The longitude in degrees.|CollectingFieldsConfiguration.shouldLogLocation|
|utc_timestamp|Long|The time at which this location was determined.|CollectingFieldsConfiguration.shouldLogTimestamp|
|horizontal_accuracy|Float|The radius of uncertainty for the location, measured in meters.|CollectingFieldsConfiguration.shouldLogHorizontalAccuracy|
|veritcal_accuracy|Float|The accuracy of the altitude value, measured in meters.|CollectingFieldsConfiguration.shouldLogHorizontalAccuracy|
|altitude|Float|The altitude, measured in meters.|CollectingFieldsConfiguration.shouldLogAltitude|
|wifi_bssid|String|A string value representing the bssid of the wifi to which the device is connected to|CollectingFieldsConfiguration.shouldLogNetworkInfo|
|wifi_ssid|String|A string value representing the ssis of the wifi to which the device is connected to|CollectingFieldsConfiguration.shouldLogNetworkInfo|
|location_context|String|A string value representing the state of the location when it was collected. Possible value - `unknown`, `passive`, `regular`, `visit_entry`, `visit_exit`|CollectingFieldsConfiguration.shouldLogLocation|
|course|Float|The direction in which the device is traveling.|CollectingFieldsConfiguration.shouldLogDeviceCourse|
|speed|Float|The instantaneous speed of the device, measured in meters per second.|CollectingFieldsConfiguration.shouldLogDeviceSpeed|
|is_charging|Boolean|A boolean value to determine if the phone was charging when the location was determined|CollectingFieldsConfiguration.shouldLogDeviceCharging|
|device_model|String|A string value representing the model of the device|CollectingFieldsConfiguration.shouldLogDeviceModel|
|os_version|String|A String value representing the version of the operating system|CollectingFieldsConfiguration.shouldLogDeviceOsVersion|

### Sample Request Body

This is a sample request body sent by the SDK. 
```json
[
  {
    "ad_id": "12a451dd-3539-4092-b134-8cb0ef62ab8a",
    "ad_opt_out": true,
    "id_type": "idfa",
    "latitude": "37.773972",
    "longitude": "-122.431297",
    "utc_timestamp": "1508356559",
    "horizontal_accuracy": 12.323,
    "vertical_accuracy": 5.3,
    "altitude": 0.456,
    "wifi_ssid": "OpenLocate_Guest",
    "wifi_bssid": "OpenLocate_Guest",
    "location_context": "regular",
    "course": 175.0,
    "speed": 11.032,
    "is_charging": true,
    "device_model": "iPhone 7",
    "os_version": "iOS 11.0.3"
  },
  {
    "ad_id": "12a451dd-3539-4092-b134-8cb0ef62ab8a",
    "ad_opt_out": true,
    "id_type": "idfa",
    "latitude": "37.773972",
    "longitude": "-122.431297",
    "utc_timestamp": "1508356559",
    "horizontal_accuracy": 12.323,
    "vertical_accuracy": 5.3,
    "altitude": 0.456,
    "wifi_ssid": "OpenLocate_Guest",
    "wifi_bssid": "OpenLocate_Guest",
    "location_context": "regular",
    "course": 175.0,
    "speed": 11.032,
    "is_charging": true,
    "device_model": "iPhone 7",
    "os_version": "iOS 11.0.3"
  }
]
```

If you want to have the SDK send data to your own AWS s3 environment for example, look into setting up an [Kinesis firehose](https://aws.amazon.com/kinesis/firehose/) according to the SDK request above.

## Communication

- If you **need help**, post a question to the [discussion forum](https://groups.google.com/a/openlocate.org/d/forum/openlocate), or tag a question with 'OpenLocate' on [Stack Overflow](https://stackoverflow.com).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.
