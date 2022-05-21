//
//  RealTimeRateLimit.swift
//  PrayerTimesKit
//
//  Created by Leptos on 5/16/22.
//

import Foundation

public class RealTimeRateLimit {
    private var latestTime = DispatchTime(uptimeNanoseconds: 1) // 0 nanoseconds calls `now()`, use 1 to get the earliest time
    public let minimumTimeInterval: DispatchTimeInterval
    
    public init(interval: DispatchTimeInterval) {
        minimumTimeInterval = interval
    }
    
    public func permitted() -> Bool {
        let nowTime: DispatchTime = .now()
        let minTime = latestTime.advanced(by: minimumTimeInterval)
        
        if nowTime > minTime {
            latestTime = nowTime
            return true
        }
        return false
    }
}
