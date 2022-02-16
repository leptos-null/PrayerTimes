//
//  SimpleCompass.swift
//  PrayerTimesUI
//
//  Created by Leptos on 2/16/22.
//

import SwiftUI

public struct SimpleCompass: Shape {
    public static var role: ShapeRole { .stroke }
    
    public let triangleScale: Double
    public let strokeWidth: Double
    
    public init(triangleScale: Double = 0.2, strokeWidth: Double = 2) {
        self.triangleScale = triangleScale
        self.strokeWidth = strokeWidth
    }
    
    public func path(in rect: CGRect) -> Path {
        let halfStrokeWidth = strokeWidth/2
        let drawRect = rect.insetBy(dx: halfStrokeWidth, dy: halfStrokeWidth)
        
        var path = Path(ellipseIn: drawRect)
        
        let rectMidX = drawRect.midX
        let triangleSideLength = drawRect.height * triangleScale
        let triangleOffset: CGFloat = triangleSideLength/3 + halfStrokeWidth
        let triangleHeight: CGFloat = triangleSideLength * sin(.pi/3)
        let halfTriangleSideLength = triangleSideLength/2
        
        path.move(to: CGPoint(x: rectMidX, y: triangleOffset))
        path.addLine(to: CGPoint(x: rectMidX + halfTriangleSideLength, y: triangleHeight + triangleOffset))
        path.addLine(to: CGPoint(x: rectMidX - halfTriangleSideLength, y: triangleHeight + triangleOffset))
        path.closeSubpath()
        
        let strokeStyle = StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
        return path.strokedPath(strokeStyle)
    }
}

struct SimpleCompass_Previews: PreviewProvider {
    static var previews: some View {
        SimpleCompass()
            .aspectRatio(1, contentMode: .fit)
            .rotationEffect(Angle(degrees: 15))
    }
}
