//
//  QiblaCalculator.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation

struct QiblaCalculator {
    private static let KAABA_LAT = 21.4225
    private static let KAABA_LNG = 39.8262

    /// Bearing from user location to Kaaba in degrees (0–360, clockwise from north).
    static func bearingToKaaba(latitude: Double, longitude: Double) -> Double {
        let lat1 = latitude * .pi / 180.0
        let lat2 = KAABA_LAT * .pi / 180.0
        let deltaLng = (KAABA_LNG - longitude) * .pi / 180.0

        let y = sin(deltaLng) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLng)
        let bearing = atan2(y, x) * 180.0 / .pi
        return (bearing + 360.0).truncatingRemainder(dividingBy: 360.0)
    }

    /// Distance from user location to Kaaba in kilometers.
    static func distanceToKaabaKm(latitude: Double, longitude: Double) -> Double {
        let earthRadius = 6371.0
        let dLat = (KAABA_LAT - latitude) * .pi / 180.0
        let dLng = (KAABA_LNG - longitude) * .pi / 180.0
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(latitude * .pi / 180.0) * cos(KAABA_LAT * .pi / 180.0) *
                sin(dLng / 2) * sin(dLng / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
}
