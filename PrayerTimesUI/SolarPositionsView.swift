//
//  SolarPositionsView.swift
//  PrayerTimesUI
//
//  Created by Leptos on 2/16/22.
//

import SwiftUI
import CoreLocation
import PrayerTimesKit

public struct SolarPositionsView: View {
    let currentTime: Date?
    let dailyPrayers: DailyPrayers
    
    let solarRadius: CGFloat = 9
    
    let cosineStrokeWidth: CGFloat = 1
    let horizonStrokeWidth: CGFloat = 1
    let solarStrokeWidth: CGFloat = 1
    
    public init(currentTime: Date? = .now, dailyPrayers: DailyPrayers) {
        self.currentTime = currentTime
        self.dailyPrayers = dailyPrayers
    }
    
    private func percentIntoDay(_ time: Date) -> Double {
        let timeInDay: TimeInterval = 24 * 60 * 60
        let solarNoon = dailyPrayers.dhuhr.start
        let solarMidnight = solarNoon.addingTimeInterval(-timeInDay/2)
        let timeSinceMidnight = time.timeIntervalSince(solarMidnight)
        return timeSinceMidnight / timeInDay
    }
    
    private func pointOnCosinePath(percent: Double, size: CGSize) -> CGPoint {
        let offset = solarRadius + solarStrokeWidth/2
        let verticalShift = size.height/2
        let amplitude = verticalShift - offset
        return CGPoint(
            x: size.width * percent,
            y: verticalShift + amplitude * cos(percent * 2 * .pi)
        )
    }
    
    public var body: some View {
        Canvas { graphicsContext, size in
            let width = size.width
            
            var cosinePath = Path()
            if width > 0 {
                let pointPercent: CGFloat = 1/width
                cosinePath.move(to: pointOnCosinePath(percent: 0, size: size))
                stride(from: pointPercent, through: 1, by: pointPercent).forEach { percent in
                    cosinePath.addLine(to: pointOnCosinePath(percent: percent, size: size))
                }
            }
            
            let sunrisePoint = pointOnCosinePath(percent: percentIntoDay(dailyPrayers.sunrise.start), size: size)
            
            var horizonPath = Path()
            horizonPath.move(to: CGPoint(x: 0, y: sunrisePoint.y))
            horizonPath.addLine(to: CGPoint(x: width, y: sunrisePoint.y))
            
            var currentSunPath = Path()
            if let currentTime = currentTime {
                currentSunPath.addCircle(
                    center: pointOnCosinePath(percent: percentIntoDay(currentTime), size: size),
                    radius: solarRadius
                )
            }
            
            var solarPath = Path()
            dailyPrayers.ordered.forEach { prayer in
                solarPath.addCircle(
                    center: pointOnCosinePath(percent: percentIntoDay(prayer.start), size: size),
                    radius: solarRadius
                )
            }
            
            graphicsContext.stroke(cosinePath, with: .color(.primary.opacity(0.8)), lineWidth: cosineStrokeWidth)
            graphicsContext.stroke(horizonPath, with: .color(.primary.opacity(0.5)), lineWidth: horizonStrokeWidth)
            graphicsContext.stroke(solarPath, with: .color(.primary.opacity(0.8)), lineWidth: solarStrokeWidth)
            graphicsContext.fill(currentSunPath, with: .color(.primary))
        }
    }
}

private extension Path {
    mutating func addCircle(center: CGPoint, radius: CGFloat) {
        move(to: CGPoint(x: center.x + radius, y: center.y))
        addRelativeArc(center: center, radius: radius, startAngle: Angle(degrees: 0), delta: Angle(degrees: 360))
    }
}

struct SolarPositionsView_Previews: PreviewProvider {
    static var previews: some View {
        SolarPositionsView(currentTime: Date(timeIntervalSinceReferenceDate: 664610000), dailyPrayers: DailyPrayers(
            day: Date(timeIntervalSinceReferenceDate: 664581600),
            calculationParameters: CalculationParameters(
                timeZone: TimeZone(identifier: "Africa/Johannesburg")!,
                location: CLLocation(latitude: -29.856687, longitude: 31.017086),
                configuration: CalculationParameters.Configuration(asrFactor: 1, fajrAngle: 18, ishaAngle: 17)
            )
        ))
            .aspectRatio(2, contentMode: .fit)
    }
}
