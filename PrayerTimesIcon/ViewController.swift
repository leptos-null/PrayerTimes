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
    // the background color for the whole image before the "face" is drawn
    var backgroundFillColor: UIColor? = .black
    var backgroundColor: UIColor = .white
    var foregroundColor: UIColor = .black
    
    // padding between the closest edge of the "background fill" and the "face"
    // a value of 0 means no padding
    // a value of 0.5 means half of the size is padding
    var insetScaleFactor: CGFloat = 1/8.0
    
    // the ratio of the "background fill" size to the requested size
    var backgroundFillScaleFactor: CGFloat = 1
    // the corner radius of the "background fill"
    // a value of 0 means no corner radius
    // a value of 0.5 means a near circle
    var backgroundFillRadiusFactor: CGFloat = 0
    
    private func fillSize(for size: CGSize) -> CGSize {
        CGSize(
            width: size.width * backgroundFillScaleFactor,
            height: size.height * backgroundFillScaleFactor
        )
    }
    
    private func dimension(for size: CGSize) -> CGFloat {
        min(size.width, size.height)
    }
    
    func drawBackground(size: CGSize) {
        let fillSize = fillSize(for: size)
        let fillDimension = dimension(for: fillSize)
        
        if let backgroundFillColor = backgroundFillColor {
            backgroundFillColor.setFill()
            
            let fillOrigin = CGPoint(
                x: (size.width - fillSize.width)/2,
                y: (size.height - fillSize.height)/2
            )
            UIBezierPath(
                roundedRect: CGRect(origin: fillOrigin, size: fillSize),
                cornerRadius: fillDimension * backgroundFillRadiusFactor
            ).fill()
        }
    }
    
    func drawFace(size: CGSize) {
        let fillSize = fillSize(for: size)
        let fillDimension = dimension(for: fillSize)
        let dimension = fillDimension * (1 - insetScaleFactor)
        
        backgroundColor.setFill()
        UIBezierPath(ovalIn: CGRect(
            x: (size.width - dimension)/2, y: (size.height - dimension)/2,
            width: dimension, height: dimension
        )).fill()
        
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let shadow = shadowPath(center: center, dimension: dimension)
        foregroundColor.setFill()
        shadow.fill()
    }
    
    func drawForeground(size: CGSize) {
        let fillSize = fillSize(for: size)
        let fillDimension = dimension(for: fillSize)
        let dimension = fillDimension * (1 - insetScaleFactor)
        
        foregroundColor.setStroke()
        
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
        
        let shadow = shadowPath(center: center, dimension: dimension)
        backgroundColor.setStroke()
        
        shadow.addClip()
        ticks.stroke()
        hand.stroke()
    }
    
    private func shadowPath(center: CGPoint, dimension: CGFloat) -> UIBezierPath {
        let shadow = UIBezierPath()
        shadow.addArc(withCenter: center,
                      radius: dimension * 0.47,
                      startAngle: (5 * .pi / 24.0), endAngle: (34 * .pi / 24.0), clockwise: false)
        shadow.addArc(withCenter: CGPoint(x: center.x + dimension * 0.151, y: center.y - dimension * 0.101),
                      radius: dimension * 0.45,
                      startAngle: (30 * .pi / 24.0), endAngle: (9 * .pi / 24.0), clockwise: false)
        return shadow
    }
    
    func draw(size: CGSize) {
        drawBackground(size: size)
        drawFace(size: size)
        drawForeground(size: size)
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
        let platform: String?
        let idiom: String?
        let role: String?
        let scale: String?
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

private struct SolidImageStackContents: Codable {
    struct Layer: Codable {
        var filename: String?
    }
    struct Info: Codable {
        var author: String
        var version: Int
    }
    var layers: [Layer]
    var info: Info
}

private struct ImageSetContents: Codable {
    struct Image: Codable {
        let platform: String?
        let idiom: String?
        let role: String?
        let scale: String?
        let size: String?
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
    
    private func writeIconAssets(for iconSet: URL, appIcon: AppIcon = AppIcon()) throws {
        let manifest = iconSet.appendingPathComponent("Contents.json")
        let parse = try Data(contentsOf: manifest)
        let jsonDecoder = JSONDecoder()
        var iconSetContents = try jsonDecoder.decode(AppIconSetContents.self, from: parse)
        
        iconSetContents.images = try iconSetContents.images.map { image in
            let scaleSuffix = image.scale ?? "1x"
            
            var imageScale = scaleSuffix
            guard imageScale.popLast() == Character("x") else { fatalError("scale must end with 'x' character") }
            guard let scale = Double(imageScale) else { fatalError("scale.dropLast() must be numeric") }
            
            let dimensions = image.size.split(separator: "x")
            guard dimensions.count == 2,
                  let width = Double(dimensions[0]),
                  let height = Double(dimensions[1]) else { fatalError("failed parsing dimensions") }
            let size = CGSize(width: width, height: height)
            
            let filenamePrefix: String
            if let platform = image.platform, let idiom = image.idiom {
                filenamePrefix = "\(platform)-\(idiom)"
            } else if let platform = image.platform {
                filenamePrefix = platform
            } else if let idiom = image.idiom {
                filenamePrefix = idiom
            } else {
                filenamePrefix = "icon"
            }
            
            let filename = "\(filenamePrefix)\(image.size)@\(scaleSuffix).png"
            
            let iconData: Data
            if image.idiom == "mac" {
                var macIcon = appIcon
                macIcon.insetScaleFactor = 0.136
                macIcon.backgroundFillScaleFactor = 0.806
                macIcon.backgroundFillRadiusFactor = 0.185
                
                iconData = macIcon.pngData(size: size, opaque: false, scale: scale)
            } else {
                iconData = appIcon.pngData(size: size, opaque: true, scale: scale)
            }
            
            try iconData.write(to: iconSet.appendingPathComponent(filename))
            
            var imgCopy = image
            imgCopy.filename = filename
            return imgCopy
        }
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [ .prettyPrinted, .sortedKeys ]
        let serialized = try jsonEncoder.encode(iconSetContents)
        try serialized.write(to: manifest)
    }
    
    private func writeImage(for imageSet: URL, drawBlock: (CGSize) -> Void) throws {
        let manifest = imageSet.appendingPathComponent("Contents.json")
        let parse = try Data(contentsOf: manifest)
        let jsonDecoder = JSONDecoder()
        var imageSetContents = try jsonDecoder.decode(ImageSetContents.self, from: parse)
        
        imageSetContents.images = try imageSetContents.images.map { image in
            let size: CGSize
            let scale: CGFloat
            let opaque: Bool
            
            guard image.idiom == "vision" else {
                fatalError("Currently this function only supports visionOS app icon image stacks")
            }
            // Xcode requests 512 @ 2x, but for some reason this breaks the ImageStack preview -
            // 1024 @ 1x seems to work fine though, so use this
            size = CGSize(width: 1024, height: 1024)
            scale = 1
            opaque = false
            
            let format = UIGraphicsImageRendererFormat()
            format.opaque = opaque
            format.scale = scale
            
            let iconData = UIGraphicsImageRenderer(size: size, format: format)
                .pngData { context in
                    drawBlock(size)
                }
            
            let filename = "icon.png"
            
            try iconData.write(to: imageSet.appendingPathComponent(filename))
            
            var imgCopy = image
            imgCopy.filename = filename
            return imgCopy
        }
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [ .prettyPrinted, .sortedKeys ]
        let serialized = try jsonEncoder.encode(imageSetContents)
        try serialized.write(to: manifest)
    }
    
    private func writeSolidImageStack(for imageStack: URL, appIcon: AppIcon = AppIcon()) throws {
        let manifest = imageStack.appendingPathComponent("Contents.json")
        let parse = try Data(contentsOf: manifest)
        let jsonDecoder = JSONDecoder()
        let imageStackContents = try jsonDecoder.decode(SolidImageStackContents.self, from: parse)
        
        let layerImageSets = imageStackContents.layers.map { layer in
            guard let filename = layer.filename else {
                fatalError("Layer must have a filename")
            }
            return imageStack
                .appendingPathComponent(filename)
                .appendingPathComponent("Content.imageset")
        }
        
        switch layerImageSets.count {
        case 1:
            try writeImage(for: layerImageSets[0]) { size in
                appIcon.draw(size: size)
            }
        case 2:
            try writeImage(for: layerImageSets[1]) { size in
                appIcon.drawBackground(size: size)
                appIcon.drawFace(size: size)
            }
            try writeImage(for: layerImageSets[0]) { size in
                appIcon.drawForeground(size: size)
            }
        case 3:
            try writeImage(for: layerImageSets[2]) { size in
                appIcon.drawBackground(size: size)
            }
            try writeImage(for: layerImageSets[1]) { size in
                appIcon.drawFace(size: size)
            }
            try writeImage(for: layerImageSets[0]) { size in
                appIcon.drawForeground(size: size)
            }
        default:
            fatalError("Image stack currently only supports 1, 2, or 3 layers")
        }
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
        
        let mobileIconSet = URL(fileURLWithPath: "PrayerTimes/Assets.xcassets/AppIcon.appiconset", isDirectory: true, relativeTo: project)
        try! writeIconAssets(for: mobileIconSet)
        
        let nanoIconSet = URL(fileURLWithPath: "PrayerTimesWatch/Assets.xcassets/AppIcon.appiconset", isDirectory: true, relativeTo: project)
        try! writeIconAssets(for: nanoIconSet, appIcon: AppIcon(insetScaleFactor: 0))
        
        let visionImageStack = URL(fileURLWithPath: "PrayerTimes/Assets.xcassets/AppIcon.solidimagestack", relativeTo: project)
        try! writeSolidImageStack(for: visionImageStack, appIcon: AppIcon(insetScaleFactor: 1/5.0))
        
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
