//
//  ViewController.swift
//  PrayerTimesIcon
//
//  Created by Leptos on 1/29/22.
//

import UIKit

// mostly from https://github.com/leptos-null/Symptoms/blob/main/SymptomsIcon/ViewController.swift

extension CGPoint {
    init(center: CGPoint, radius: CGFloat, angle: Double) {
        self.init(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }
}

struct AppIcon {
    let backgroundFillColor: UIColor?
    let backgroundColor: UIColor
    let foregroundColor: UIColor
    
    let insetScaleFactor: CGFloat
    
    init(backgroundFillColor: UIColor? = .black,
         backgroundColor: UIColor = .white, foregroundColor: UIColor = .black,
         insetScaleFactor: CGFloat = 1/8.0) {
        self.backgroundFillColor = backgroundFillColor
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.insetScaleFactor = insetScaleFactor
    }
    
    func draw(size: CGSize) {
        let fullDimension = min(size.width, size.height)
        let dimension = fullDimension * (1 - insetScaleFactor)
        
        if let backgroundFillColor = backgroundFillColor {
            backgroundFillColor.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
        }
        
        backgroundColor.setFill()
        foregroundColor.setStroke()
        
        UIBezierPath(ovalIn: CGRect(
            x: (size.width - dimension)/2, y: (size.height - dimension)/2,
            width: dimension, height: dimension
        )).fill()
        
        let ticks = UIBezierPath()
        ticks.lineWidth = dimension/58
        ticks.lineCapStyle = .round
        
        let center = CGPoint(x: size.width/2, y: size.height/2)
        
        let midTickRadius = dimension * 0.4
        let tickHeightDiff = dimension/28
        let innerTickRadius = midTickRadius - tickHeightDiff
        let outerTickRadius = midTickRadius + tickHeightDiff
        
        let circleRadians: Double = 2 * .pi
        for position in stride(from: 0, to: circleRadians, by: circleRadians/12) {
            ticks.move(to: CGPoint(center: center, radius: innerTickRadius, angle: position))
            ticks.addLine(to: CGPoint(center: center, radius: outerTickRadius, angle: position))
        }
        ticks.stroke()
        
        let hourAngle: Double = 7 * .pi / 6.0
        let minuteAngle: Double = 171 * .pi / 96.0
        
        let hand = UIBezierPath()
        hand.lineWidth = dimension/32
        hand.lineCapStyle = .round
        
        hand.move(to: center)
        hand.addLine(to: CGPoint(center: center, radius: dimension * 0.26, angle: hourAngle))
        hand.move(to: center)
        hand.addLine(to: CGPoint(center: center, radius: dimension * 0.36, angle: minuteAngle))
        
        hand.stroke()
        
        let shadow = UIBezierPath()
        shadow.addArc(withCenter: center,
                      radius: dimension * 0.47,
                      startAngle: (5 * .pi / 24.0), endAngle: (34 * .pi / 24.0), clockwise: false)
        shadow.addArc(withCenter: CGPoint(x: center.x + dimension * 0.151, y: center.y - dimension * 0.101),
                      radius: dimension * 0.45,
                      startAngle: (30 * .pi / 24.0), endAngle: (9 * .pi / 24.0), clockwise: false)
        
        foregroundColor.setFill()
        backgroundColor.setStroke()
        
        shadow.fill()
        
        shadow.addClip()
        ticks.stroke()
        hand.stroke()
    }
    
    func image(size: CGSize, opaque: Bool = false, scale: CGFloat? = nil) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = opaque
        if let scale = scale {
            format.scale = scale
        }
        return UIGraphicsImageRenderer(size: size, format: format)
            .image { context in
                draw(size: size)
            }
    }
    
    func pngData(size: CGSize, opaque: Bool = false, scale: CGFloat? = nil) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = opaque
        if let scale = scale {
            format.scale = scale
        }
        return UIGraphicsImageRenderer(size: size, format: format)
            .pngData { context in
                draw(size: size)
            }
    }
    
    func pdfData(size: CGSize) -> Data {
        UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size))
            .pdfData { context in
                context.beginPage()
                draw(size: size)
            }
    }
    
}

private struct AppIconSetContents: Codable {
    struct Image: Codable {
        let idiom: String?
        let role: String?
        let scale: String
        let size: String
        let subtype: String?
        var filename: String?
    }
    struct Info: Codable {
        var author: String
        var version: Int
    }
    var images: [Image]
    var info: Info
}

class ViewController: UIViewController {
    
    @IBOutlet private var imageView: UIImageView!
    
    private func writeIconAssets(for iconSet: URL) throws {
        let manifest = iconSet.appendingPathComponent("Contents.json")
        let parse = try Data(contentsOf: manifest)
        let jsonDecoder = JSONDecoder()
        var iconSetContents = try jsonDecoder.decode(AppIconSetContents.self, from: parse)
        
        let appIcon = AppIcon()
        
        iconSetContents.images = try iconSetContents.images.map { image in
            guard image.scale.last == Character("x") else { fatalError("scale must be '{NUMERIC}x'") }
            guard let scale = Double(image.scale.dropLast()) else { fatalError("scale.dropLast() must be numeric") }
            
            let dimensions = image.size.split(separator: "x")
            guard dimensions.count == 2,
                  let width = Double(dimensions[0]),
                  let height = Double(dimensions[1]) else { fatalError("failed parsing dimensions") }
            let size = CGSize(width: width, height: height)
            
            let filename = "AppIcon\(image.size)@\(image.scale).png"
            try appIcon
                .pngData(size: size, opaque: true, scale: scale)
                .write(to: iconSet.appendingPathComponent(filename))
            
            var imgCopy = image
            imgCopy.filename = filename
            return imgCopy
        }
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [ .prettyPrinted, .sortedKeys ]
        let serialized = try jsonEncoder.encode(iconSetContents)
        try serialized.write(to: manifest)
    }
    
    private func writeGitHubPreview(to url: URL, scale: CGFloat) throws {
        let size = CGSize(width: 1280/scale, height: 640/scale)
        try AppIcon()
            .pngData(size: size, opaque: true, scale: scale)
            .write(to: url)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let file = URL(fileURLWithPath: #file)
        let project = URL(fileURLWithPath: "..", isDirectory: true, relativeTo: file)
        
        let iconSet = URL(fileURLWithPath: "PrayerTimes/Assets.xcassets/AppIcon.appiconset", isDirectory: true, relativeTo: project)
        try! writeIconAssets(for: iconSet)
        
        let banner = URL(fileURLWithPath: "docs/banner.png", isDirectory: true, relativeTo: project)
        try! writeGitHubPreview(to: banner, scale: 1)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let imageView = self.imageView else { return }
        let size = imageView.frame.size
        let appIcon = AppIcon(backgroundFillColor: nil)
        
        imageView.image = appIcon.image(size: size)
    }
    
}
