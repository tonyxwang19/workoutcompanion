//
//  LocationTracker.swift
//  runningdemo
//
//  Created by 王希宁的Macbook on 8/8/25.
//

import CoreLocation
import SwiftUI
import Combine
import MapKit

class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var locations: [CLLocation] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationAvailable = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
    #if targetEnvironment(simulator)
        manager.allowsBackgroundLocationUpdates = false
    #else
        manager.allowsBackgroundLocationUpdates = true
    #endif
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startTracking(activityType: CLActivityType = .fitness) {
        print("开始定位")
        locations.removeAll()
        manager.activityType = activityType
        manager.startUpdatingLocation()
    }
    
    func stopTracking() {
        print("停止定位")
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations newLocations: [CLLocation]) {
        for loc in newLocations {
            guard loc.horizontalAccuracy <= 15 else { continue } // 精度控制
            locations.append(loc)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isLocationAvailable = true
        default:
            isLocationAvailable = false
        }
    }
}

func wgs84ToGcj02(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    // 中国境外不做偏移
    if outOfChina(lat: coordinate.latitude, lon: coordinate.longitude) {
        return coordinate
    }
    
    let pi = 3.14159265358979324
    let a = 6378245.0
    let ee = 0.00669342162296594323
    
    func transformLat(x: Double, y: Double) -> Double {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y
        ret += 0.1 * x * y + 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0
        return ret
    }
    
    func transformLon(x: Double, y: Double) -> Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x
        ret += 0.1 * x * y + 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0
        return ret
    }
    
    let lat = coordinate.latitude
    let lon = coordinate.longitude
    var dLat = transformLat(x: lon - 105.0, y: lat - 35.0)
    var dLon = transformLon(x: lon - 105.0, y: lat - 35.0)
    let radLat = lat / 180.0 * pi
    var magic = sin(radLat)
    magic = 1 - ee * magic * magic
    let sqrtMagic = sqrt(magic)
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi)
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi)
    return CLLocationCoordinate2D(latitude: lat + dLat, longitude: lon + dLon)
}

func outOfChina(lat: Double, lon: Double) -> Bool {
    if lon < 72.004 || lon > 137.8347 { return true }
    if lat < 0.8293 || lat > 55.8271 { return true }
    return false
}

func totalDistance(from locations: [CLLocation], minDistance: Double = 1.0) -> Double {
    guard locations.count > 1 else { return 0 }
    var total: Double = 0
    for i in 1..<locations.count {
        let d = locations[i].distance(from: locations[i - 1])
        if d >= minDistance {
            total += d
        }
    }
    return total
}

//func pace(from distance: Double, duration: TimeInterval) -> String {
//    guard distance >= 10, duration >= 5 else { return "--'--''" }
//    let paceValue = (duration / 60) / (distance / 1000) // min/km
//    let minutes = Int(paceValue)
//    let seconds = Int((paceValue - Double(minutes)) * 60)
//    return String(format: "%d'%02d''", minutes, seconds)
//}
