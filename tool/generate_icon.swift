import AppKit
import Foundation

// Draw the ShopSphere mark at each platform's required pixel size.
// The vector geometry keeps small Android and iOS icons crisp.
func renderIcon(size: Int, output: String) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "ShopSphereIcon", code: 1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    let scale = NSAffineTransform()
    scale.scale(by: CGFloat(size) / 1024)
    scale.concat()

    NSColor(calibratedRed: 23 / 255, green: 107 / 255, blue: 91 / 255, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()

    NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.09).setFill()
    NSBezierPath(ovalIn: NSRect(x: 660, y: 650, width: 510, height: 510)).fill()
    NSBezierPath(ovalIn: NSRect(x: -180, y: -190, width: 470, height: 470)).fill()

    let handle = NSBezierPath()
    handle.lineWidth = 54
    handle.lineCapStyle = .round
    handle.move(to: NSPoint(x: 364, y: 664))
    handle.curve(
        to: NSPoint(x: 660, y: 664),
        controlPoint1: NSPoint(x: 364, y: 906),
        controlPoint2: NSPoint(x: 660, y: 906)
    )
    NSColor(calibratedRed: 1, green: 0.98, blue: 0.94, alpha: 1).setStroke()
    handle.stroke()

    NSColor(calibratedRed: 1, green: 0.98, blue: 0.94, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: 226, y: 226, width: 572, height: 456),
                 xRadius: 88, yRadius: 88).fill()

    NSColor(calibratedRed: 1, green: 117 / 255, blue: 78 / 255, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 559, y: 304, width: 154, height: 154)).fill()

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ShopSphereIcon", code: 2)
    }
    try data.write(to: URL(fileURLWithPath: output))
}

let android = ["mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192]
for (density, size) in android {
    try renderIcon(size: size, output: "android/app/src/main/res/mipmap-\(density)/ic_launcher.png")
}

let ios = [
    "Icon-App-20x20@1x.png": 20, "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60, "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58, "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40, "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120, "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180, "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152, "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
]
for (name, size) in ios {
    try renderIcon(size: size, output: "ios/Runner/Assets.xcassets/AppIcon.appiconset/\(name)")
}
