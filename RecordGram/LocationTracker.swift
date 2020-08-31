//
//  LocationTracker.swift
//  RecordGram
//
//  Created by Mauro Taroco on 9/12/17.
//  Copyright © 2017 Meridian Inc. All rights reserved.
//

import UIKit
import CoreLocation

class LocationTracker: NSObject {
    static let shared = LocationTracker()

    var latitude: String = ""
    var longitude: String = ""

    let locationManager = CLLocationManager()

    var completion: ((CLLocation?) -> Void)?

    func existCoordenates() -> Bool {
        return !latitude.elementsEqual("0") || !longitude.elementsEqual("0") || longitude.isEmpty || latitude.isEmpty
    }

    func getCurrentLocation(completionHandler: ((CLLocation?) -> (Void))?) {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
//            locationManager.requestWhenInUseAuthorization()
        } else {
            completionHandler?(nil)
            return
        }

        locationManager.startUpdatingLocation()

        completion = completionHandler

        if let location = locationManager.location {
            sendCallBackAfterCheckingSignificantChangeFor(location)
        }
    }

    func sendCallBackAfterCheckingSignificantChangeFor(_ location: CLLocation) {
        latitude = String(location.coordinate.latitude)
        longitude = String(location.coordinate.longitude)
        updateCoordinateInServer()
        if let completion = completion {
            completion(location)
        }
    }

    func updateCoordinateInServer() {
        if existCoordenates() {
            UserClient.shared.update(latitude: latitude, longitude: longitude, success: { (response) in
                if let status = response.bool, status == true {
                    if let data = response[kData].dictionary {
                        guard let latitude = data[kLatitude]?.string,
                              let longitude = data[kLongitude]?.string else {
                            return
                        }
                        UserDefaults.setCoordinate(latitude: latitude, longitude: longitude)
                    }
                }
            }, failure: { error in
                //Nothing to do...
            })
        }
    }
}

extension LocationTracker: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()

        if let coordinate = locations.first {
            sendCallBackAfterCheckingSignificantChangeFor(coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(nil)
    }
}
