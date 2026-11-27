import CoreImage.CIFilterBuiltins
import Foundation
import ImageIO
import UniformTypeIdentifiers

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("qr.swift: \(message)\n".utf8))
    exit(1)
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fail("usage: swift qr.swift <preview-url> <destination.png>")
}

guard let components = URLComponents(string: arguments[1]),
      let scheme = components.scheme?.lowercased(),
      ["http", "https"].contains(scheme),
      let host = components.host, !host.isEmpty,
      let url = components.url?.absoluteString else {
    fail("the preview URL must be an absolute HTTP or HTTPS URL")
}

let filter = CIFilter.qrCodeGenerator()
filter.message = Data(url.utf8)
filter.correctionLevel = "M"

guard let code = filter.outputImage else {
    fail("could not encode the preview URL")
}
let renderer = CIContext(options: [.useSoftwareRenderer: true])
guard let modules = renderer.createCGImage(code, from: code.extent) else {
    fail("Core Image could not render the QR code")
}

// Use whole pixels per module and a four-module quiet zone on each side.
let pixelsPerModule = 10
let margin = 4 * pixelsPerModule
let width = modules.width * pixelsPerModule + 2 * margin
let height = modules.height * pixelsPerModule + 2 * margin
guard let canvas = CGContext(data: nil, width: width, height: height,
                             bitsPerComponent: 8, bytesPerRow: 0,
                             space: CGColorSpaceCreateDeviceGray(),
                             bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
    fail("could not allocate the QR image")
}

canvas.setFillColor(gray: 1, alpha: 1)
canvas.fill(CGRect(x: 0, y: 0, width: width, height: height))
canvas.interpolationQuality = .none
canvas.draw(modules, in: CGRect(x: margin, y: margin,
                               width: width - 2 * margin, height: height - 2 * margin))

guard let image = canvas.makeImage() else {
    fail("could not render the QR image")
}

let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: renderer,
                          options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
let decoded = detector?.features(in: CIImage(cgImage: image)).first as? CIQRCodeFeature
guard decoded?.messageString == url else {
    fail("the rendered QR image did not decode to the preview URL")
}

let png = NSMutableData()
guard let writer = CGImageDestinationCreateWithData(png, UTType.png.identifier as CFString, 1, nil) else {
    fail("could not create a PNG encoder")
}
CGImageDestinationAddImage(writer, image, nil)
guard CGImageDestinationFinalize(writer) else {
    fail("could not encode the QR image as PNG")
}

do {
    let destination = URL(fileURLWithPath: arguments[2])
    try (png as Data).write(to: destination, options: .atomic)
} catch {
    fail("could not write the PNG: \(error.localizedDescription)")
}
