import AppKit
import CoreGraphics
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fputs("uso: mask-icon entrada.png salida.png\n", stderr)
    exit(1)
}

let input = arguments[1]
let output = arguments[2]
guard let image = NSImage(contentsOfFile: input) else {
    fputs("no pude leer \(input)\n", stderr)
    exit(1)
}
var proposed = NSRect(origin: .zero, size: image.size)
guard let cgImage = image.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
    fputs("no pude leer \(input)\n", stderr)
    exit(1)
}

let pixels = max(cgImage.width, cgImage.height)
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: pixels,
    height: pixels,
    bitsPerComponent: 8,
    bytesPerRow: pixels * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("no pude crear el lienzo\n", stderr)
    exit(1)
}

let bounds = CGRect(x: 0, y: 0, width: pixels, height: pixels)
let inset = max(2, CGFloat(pixels) * 0.03)
let shape = bounds.insetBy(dx: inset, dy: inset)
context.clear(bounds)
context.addPath(squircle(in: shape))
context.clip()
context.interpolationQuality = CGInterpolationQuality.high
context.draw(cgImage, in: bounds)
context.resetClip()
context.addPath(squircle(in: shape))
context.setStrokeColor(CGColor(gray: 0, alpha: 0.55))
context.setLineWidth(max(1, CGFloat(pixels) * 0.035))
context.strokePath()

guard let rendered = context.makeImage() else {
    fputs("no pude componer el icono\n", stderr)
    exit(1)
}

guard let data = context.data else {
    fputs("no pude leer los pixeles\n", stderr)
    exit(1)
}
let bytes = data.bindMemory(to: UInt8.self, capacity: pixels * pixels * 4)
let center = (pixels / 2) * pixels + (pixels / 2)
let centerAlpha = bytes[center * 4 + 3]
let cornerAlpha = bytes[3]
if centerAlpha < 200 || cornerAlpha > 16 {
    fputs("el icono salió mal: centro \(centerAlpha), esquina \(cornerAlpha)\n", stderr)
    exit(1)
}

let rep = NSBitmapImageRep(cgImage: rendered)
guard let png = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
    fputs("no pude escribir el icono\n", stderr)
    exit(1)
}

do {
    try png.write(to: URL(fileURLWithPath: output))
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}

func squircle(in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    let exponent: CGFloat = 5
    let steps = 180
    let radiusX = rect.width / 2
    let radiusY = rect.height / 2
    let centerX = rect.midX
    let centerY = rect.midY
    for index in 0...steps {
        let angle = CGFloat(index) / CGFloat(steps) * 2 * .pi
        let cosine = cos(angle)
        let sine = sin(angle)
        let point = CGPoint(
            x: centerX + pow(abs(cosine), 2 / exponent) * radiusX * (cosine < 0 ? -1 : 1),
            y: centerY + pow(abs(sine), 2 / exponent) * radiusY * (sine < 0 ? -1 : 1)
        )
        if index == 0 {
            path.move(to: point)
        } else {
            path.addLine(to: point)
        }
    }
    path.closeSubpath()
    return path
}
