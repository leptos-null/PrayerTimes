//
//  LineUpCompass.swift
//  PrayerTimesUI
//
//  Created by Leptos on 2/15/22.
//

import SwiftUI

public struct LineUpCompass: View {
    public let facing: Angle
    public let strokeWidth: Double
    
    public init(facing: Angle, strokeWidth: Double = 2) {
        self.facing = facing
        self.strokeWidth = strokeWidth
    }
    
    public var body: some View {
        Canvas { graphicsContext, size in
            let needleRatio = 0.15
            
            let rect = CGRect(origin: .zero, size: size)
                .insetBy(dx: strokeWidth/2, dy: strokeWidth/2)
            
            let radius: CGFloat = min(
                rect.width/(1 + 2 * needleRatio),
                rect.height/2
            )/2
            
            let middleX = rect.midX
            let leftSide = middleX - needleRatio * radius
            let rightSide = middleX + needleRatio * radius
            
            let compassY = rect.midY - radius
            
            var compass = Path()
            compass.move   (to: CGPoint(x: middleX,   y: compassY + (2 + needleRatio) * radius))
            compass.addLine(to: CGPoint(x: leftSide,  y: compassY + (2 + (2 * needleRatio)) * radius))
            compass.addLine(to: CGPoint(x: leftSide,  y: compassY - needleRatio * radius))
            compass.addLine(to: CGPoint(x: middleX,   y: compassY + (-2 * needleRatio) * radius))
            compass.addLine(to: CGPoint(x: rightSide, y: compassY - needleRatio * radius))
            compass.addLine(to: CGPoint(x: rightSide, y: compassY + (2 + (2 * needleRatio)) * radius))
            compass.closeSubpath()
            
            let angle = acos(needleRatio)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            compass.appendArc(center: center, radius: radius, startAngle: angle, endAngle: (.pi * 2 - angle), clockwise: true)
            compass.appendArc(center: center, radius: radius, startAngle: (.pi + angle), endAngle: (.pi - angle), clockwise: true)
            
            let lineUpHeight = radius * 2.5
            let lineUpY = rect.height/2
            
            var lineUp = Path()
            lineUp.move   (to: CGPoint(x: rightSide, y: lineUpY + (1 + 2 * needleRatio) * radius))
            lineUp.addLine(to: CGPoint(x: rightSide, y: lineUpY + lineUpHeight/4 * 3))
            lineUp.addLine(to: CGPoint(x: middleX,   y: lineUpY + lineUpHeight/4 * 3 - needleRatio * radius))
            lineUp.addLine(to: CGPoint(x: leftSide,  y: lineUpY + lineUpHeight/4 * 3))
            lineUp.addLine(to: CGPoint(x: leftSide,  y: lineUpY + (1 + 2 * needleRatio) * radius))
            
            lineUp.move   (to: CGPoint(x: leftSide,  y: lineUpY - (1 + needleRatio) * radius))
            lineUp.addLine(to: CGPoint(x: leftSide,  y: lineUpY - lineUpHeight/3 * 2))
            lineUp.addLine(to: CGPoint(x: middleX,   y: lineUpY - lineUpHeight/3 * 2 - needleRatio * radius))
            lineUp.addLine(to: CGPoint(x: rightSide, y: lineUpY - lineUpHeight/3 * 2))
            lineUp.addLine(to: CGPoint(x: rightSide, y: lineUpY - (1 + needleRatio) * radius))
            
            let rotation: CGAffineTransform = .identity
                .translatedBy(x: center.x, y: center.y)
                .rotated(by: facing.radians)
                .translatedBy(x: -center.x, y: -center.y)
            
            graphicsContext.stroke(lineUp, with: .foreground, lineWidth: strokeWidth)
            graphicsContext.stroke(compass.applying(rotation), with: .foreground, lineWidth: strokeWidth)
        }
    }
}

private extension Path {
    mutating func appendArc(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        move(to: CGPoint(
            x: center.x + radius * cos(startAngle),
            y: center.y + radius * sin(startAngle))
        )
        addArc(center: center, radius: radius, startAngle: Angle(radians: startAngle), endAngle: Angle(radians: endAngle), clockwise: true)
    }
}

struct LineUpCompass_Previews: PreviewProvider {
    static var previews: some View {
        LineUpCompass(facing: Angle(degrees: 15))
    }
}
