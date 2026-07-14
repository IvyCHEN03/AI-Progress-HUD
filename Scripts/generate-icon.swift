import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("BundleResources", isDirectory: true)
let iconset = resources.appendingPathComponent("AIProgressHUD.iconset", isDirectory: true)
let output = resources.appendingPathComponent("AIProgressHUD.icns")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func render(size: Int) -> Data {
    let canvas = NSImage(size: NSSize(width: size, height: size))
    canvas.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else { fatalError("Missing graphics context") }
    context.setShouldAntialias(true)

    let scale = CGFloat(size) / 1024
    let iconRect = CGRect(x: 92 * scale, y: 92 * scale, width: 840 * scale, height: 840 * scale)
    let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: 218 * scale, yRadius: 218 * scale)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.04, green: 0.10, blue: 0.16, alpha: 1),
        NSColor(calibratedRed: 0.05, green: 0.19, blue: 0.25, alpha: 1)
    ])!
    gradient.draw(in: iconPath, angle: -45)

    NSColor(calibratedRed: 0.12, green: 0.86, blue: 0.93, alpha: 0.16).setFill()
    NSBezierPath(ovalIn: CGRect(x: 184 * scale, y: 184 * scale, width: 656 * scale, height: 656 * scale)).fill()

    let pulse = NSBezierPath()
    pulse.lineWidth = 54 * scale
    pulse.lineCapStyle = .round
    pulse.lineJoinStyle = .round
    pulse.move(to: CGPoint(x: 220 * scale, y: 500 * scale))
    pulse.line(to: CGPoint(x: 354 * scale, y: 500 * scale))
    pulse.line(to: CGPoint(x: 420 * scale, y: 660 * scale))
    pulse.line(to: CGPoint(x: 500 * scale, y: 350 * scale))
    pulse.line(to: CGPoint(x: 574 * scale, y: 560 * scale))
    pulse.line(to: CGPoint(x: 642 * scale, y: 500 * scale))
    pulse.line(to: CGPoint(x: 804 * scale, y: 500 * scale))
    NSColor(calibratedRed: 0.17, green: 0.91, blue: 0.98, alpha: 1).setStroke()
    pulse.stroke()

    context.setShadow(offset: .zero, blur: 28 * scale, color: NSColor.cyan.withAlphaComponent(0.55).cgColor)
    pulse.stroke()
    context.setShadow(offset: .zero, blur: 0)

    canvas.unlockFocus()
    guard let tiff = canvas.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Failed to render icon")
    }
    return png
}

let variants: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]
for (name, size) in variants {
    try render(size: size).write(to: iconset.appendingPathComponent(name), options: .atomic)
}

func bigEndian(_ value: UInt32) -> Data {
    var encoded = value.bigEndian
    return Data(bytes: &encoded, count: MemoryLayout<UInt32>.size)
}

let chunks: [(String, String)] = [
    ("icp4", "icon_16x16.png"),
    ("icp5", "icon_32x32.png"),
    ("icp6", "icon_32x32@2x.png"),
    ("ic07", "icon_128x128.png"),
    ("ic08", "icon_128x128@2x.png"),
    ("ic09", "icon_256x256@2x.png"),
    ("ic10", "icon_512x512@2x.png")
]
var body = Data()
for (type, file) in chunks {
    let png = try Data(contentsOf: iconset.appendingPathComponent(file))
    body.append(Data(type.utf8))
    body.append(bigEndian(UInt32(png.count + 8)))
    body.append(png)
}
var icns = Data("icns".utf8)
icns.append(bigEndian(UInt32(body.count + 8)))
icns.append(body)
try icns.write(to: output, options: .atomic)
print("Generated \(output.path)")
