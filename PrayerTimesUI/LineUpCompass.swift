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
        ZStack {
            LineUp(strokeWidth: strokeWidth)
            Compass(strokeWidth: strokeWidth)
                .rotation(facing)
        }
    }
}

private struct DrawingDimensions {
    let needleRatio: Double = 0.15
    let strokeWidth: Double
    
    let drawRect: CGRect
    let radius: CGFloat
    let midX: CGFloat
    let leftSide: CGFloat
    let rightSide: CGFloat
    
    init(strokeWidth: Double, rect: CGRect) {
        self.strokeWidth = strokeWidth
        
        self.drawRect = rect.insetBy(dx: strokeWidth/2, dy: strokeWidth/2)
        
        self.radius = min(
            drawRect.width/(1 + 2 * needleRatio),
            rect.height/2
        )/2
        
        self.midX = drawRect.midX
        self.leftSide = midX - needleRatio * radius
        self.rightSide = midX + needleRatio * radius
    }
}

private struct LineUp: Shape {
    let strokeWidth: Double
    
    func path(in rect: CGRect) -> Path {
        let dimensions = DrawingDimensions(strokeWidth: strokeWidth, rect: rect)
        let needleRatio = dimensions.needleRatio
        
        let drawRect = dimensions.drawRect
        
        let radius: CGFloat = dimensions.radius
        
        let middleX = dimensions.midX
        let leftSide = dimensions.leftSide
        let rightSide = dimensions.rightSide
        
        let lineUpHeight = radius * 2.5
        let lineUpY = drawRect.height/2
        
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
        
        let strokeStyle = StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
        return lineUp.strokedPath(strokeStyle)
    }
}

private struct Compass: Shape {
    let strokeWidth: Double
    
    func path(in rect: CGRect) -> Path {
        let dimensions = DrawingDimensions(strokeWidth: strokeWidth, rect: rect)
        let needleRatio = dimensions.needleRatio
        
        let drawRect = dimensions.drawRect
        
        let radius: CGFloat = dimensions.radius
        
        let middleX = dimensions.midX
        let leftSide = dimensions.leftSide
        let rightSide = dimensions.rightSide
        
        let compassY = drawRect.midY - radius
        
        var compass = Path()
        compass.move   (to: CGPoint(x: middleX,   y: compassY + (2 + needleRatio) * radius))
        compass.addLine(to: CGPoint(x: leftSide,  y: compassY + (2 + (2 * needleRatio)) * radius))
        compass.addLine(to: CGPoint(x: leftSide,  y: compassY - needleRatio * radius))
        compass.addLine(to: CGPoint(x: middleX,   y: compassY + (-2 * needleRatio) * radius))
        compass.addLine(to: CGPoint(x: rightSide, y: compassY - needleRatio * radius))
        compass.addLine(to: CGPoint(x: rightSide, y: compassY + (2 + (2 * needleRatio)) * radius))
        compass.closeSubpath()
        
        let angle = acos(needleRatio)
        let center = CGPoint(x: drawRect.midX, y: drawRect.midY)
        compass.appendArc(center: center, radius: radius, startAngle: angle, endAngle: (.pi * 2 - angle), clockwise: true)
        compass.appendArc(center: center, radius: radius, startAngle: (.pi + angle), endAngle: (.pi - angle), clockwise: true)
        
        let strokeStyle = StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
        return compass.strokedPath(strokeStyle)
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
