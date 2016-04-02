//
//  LocationManager.swift
//  cryptochat
//
//  Created by David Zorychta on 2016-04-02.
//  Copyright © 2016 David Zorychta. All rights reserved.
//

import Foundation
import CoreLocation
import PromiseKit
import UIKit

class LocationManager : NSObject {

    // locationManager is how we access the device GPS api
    let locationManager = CLLocationManager()

    // state variable keeping track of if we've found the user location yet
    var foundLocation = false

    var imagePromise : Promise<UIImage>?
    var imagePromiseFufilled : ((UIImage) -> Void)?
    var imagePromiseRejected : ((ErrorType) -> Void)?


    override init() {
        super.init()
        imagePromise = Promise { fulfill, reject in
            self.imagePromiseFufilled = fulfill
            self.imagePromiseRejected = reject
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }

}

extension LocationManager : CLLocationManagerDelegate {

    // when user approves GPS, start asking for location updates
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != .Denied {
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
        } else {
            imagePromiseRejected?(NSError(domain: "no permission", code: 1, userInfo: nil))
        }
    }

    // handle GPS errors by going back to the province selecting page
    func locationManager(manager: CLLocationManager, didFailWithError errorMsg: NSError) {
        imagePromiseRejected?(errorMsg)
    }

    // when the GPS tells us where we are, start trying to find out our province and city
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // lock to make sure this runs once (dont trust GPS not to trigger this block twice even though we stop listening below)
        locationManager.stopUpdatingLocation()
        if foundLocation {
            return
        }
        foundLocation = true
        if let location = locations.first {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                let url = String(format: "https://maps.google.com/maps/api/staticmap?center=%f,%f&zoom=14&size=256x256&maptype=roadmap&sensor=false", location.coordinate.latitude, location.coordinate.longitude)
                var image : UIImage?
                if let url = NSURL(string: url) {
                    let data = NSData(contentsOfURL: url)
                    image = UIImage(data: data!)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    if let image = image {
                        self.imagePromiseFufilled?(image)
                    } else {
                        self.imagePromiseRejected?(NSError(domain: "invalid image", code: 1, userInfo: nil))
                    }
                }
            }
        } else {
            imagePromiseRejected?(NSError(domain: "no location found", code: 1, userInfo: nil))
        }
    }

}