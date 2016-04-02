//
//  MapViewController.swift
//  cryptochat
//
//  Created by Yuanjiang Lin on 16/4/2.
//  Copyright © 2016年 David Zorychta. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    
    
    var locationManager = CLLocationManager()
    var x = 0.0
    var y = 0.0
    var x2 = 1.1
    var y2 = 1.1
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // Dispose of any resources that can be recreated.
        let camera = GMSCameraPosition.cameraWithLatitude(x, longitude: y, zoom: 6)
        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView.myLocationEnabled = true
        print(mapView.myLocation)
        
        self.view = mapView
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(x, y)
        marker.title = "user"
        marker.snippet = "somewhere"
        marker.map = mapView
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        x2 = (manager.location?.coordinate.latitude)!
        y2 = (manager.location?.coordinate.longitude)!
        print(x2, y2)
        if(x2 != x) || (y2 != y) {
            x = x2
            y = y2
            viewDidLoad()
        }
    }
    
}
