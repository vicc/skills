// Compare captured PNG channel values and place both images into a labeled canvas.
// Build: xcrun swiftc compare.swift -o compare
// Uses macOS system frameworks and zlib; no package dependencies.
import AppKit
import Foundation
import zlib

struct ComparisonError: Error, CustomStringConvertible {
    let description: String
    init(_ message: String) { description = message }
}

struct Pixels {
    let width: Int
    let height: Int
    var rgba: [UInt8]
}

// Reading/writing the PNG samples directly avoids hidden color conversion or
// premultiplication during comparison. RGB/RGBA, 8-bit, non-interlaced only.
func readPNG(_ url: URL) throws -> Pixels {
    let data = [UInt8](try Data(contentsOf: url))
    let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    guard data.starts(with: signature) else { throw ComparisonError("Not a PNG: \(url.path)") }
    func uint32(_ offset: Int) -> Int {
        (0..<4).reduce(0) { ($0 << 8) | Int(data[offset + $1]) }
    }
    var cursor = 8
    var width = 0, height = 0, channels = 0
    var compressed = [UInt8]()
    var sawHeader = false, sawEnd = false
    while cursor + 12 <= data.count {
        let count = uint32(cursor)
        guard count <= data.count - cursor - 12 else { throw ComparisonError("Truncated PNG chunk") }
        let tag = String(bytes: data[(cursor + 4)..<(cursor + 8)], encoding: .ascii) ?? ""
        let body = cursor + 8
        let expectedCRC = UInt32(uint32(body + count))
        let actualCRC = data.withUnsafeBufferPointer {
            crc32(0, $0.baseAddress!.advanced(by: cursor + 4), uInt(count + 4))
        }
        guard UInt32(actualCRC) == expectedCRC else { throw ComparisonError("PNG checksum failed: \(tag)") }
        switch tag {
        case "IHDR":
            guard !sawHeader, cursor == 8, count == 13 else { throw ComparisonError("Invalid PNG header") }
            width = uint32(body); height = uint32(body + 4)
            let depth = data[body + 8], type = data[body + 9]
            guard width > 0, height > 0, width <= 16384, height <= 16384,
                  width * height <= 64_000_000,
                  depth == 8, type == 2 || type == 6,
                  data[body + 10] == 0, data[body + 11] == 0, data[body + 12] == 0 else {
                throw ComparisonError("Expected a non-interlaced RGB/RGBA8 PNG, at most 64 million pixels")
            }
            channels = type == 6 ? 4 : 3
            sawHeader = true
        case "IDAT":
            guard sawHeader else { throw ComparisonError("PNG image data precedes header") }
            compressed.append(contentsOf: data[body..<(body + count)])
        case "IEND":
            sawEnd = true
        default:
            // Ancillary metadata, including color profiles, does not change raw
            // sample comparisons. Unsupported critical chunks are not ignored.
            guard data[cursor + 4] & 0x20 != 0 else {
                throw ComparisonError("Unsupported critical PNG chunk: \(tag)")
            }
        }
        cursor += count + 12
        if sawEnd { break }
    }
    guard sawHeader, sawEnd, !compressed.isEmpty else { throw ComparisonError("Incomplete PNG") }
    let stride = width * channels
    var filtered = [UInt8](repeating: 0, count: (stride + 1) * height)
    var decodedSize = uLongf(filtered.count)
    let status = filtered.withUnsafeMutableBufferPointer { output in
        compressed.withUnsafeBufferPointer { input in
            uncompress(output.baseAddress, &decodedSize, input.baseAddress, uLong(compressed.count))
        }
    }
    guard status == Z_OK, decodedSize == filtered.count else { throw ComparisonError("PNG decompression failed (\(status))") }
    var samples = [UInt8](repeating: 0, count: stride * height)
    func paeth(_ a: UInt8, _ b: UInt8, _ c: UInt8) -> UInt8 {
        let prediction = Int(a) + Int(b) - Int(c)
        let da = abs(prediction - Int(a)), db = abs(prediction - Int(b)), dc = abs(prediction - Int(c))
        return da <= db && da <= dc ? a : (db <= dc ? b : c)
    }
    for y in 0..<height {
        let filter = filtered[y * (stride + 1)]
        guard filter <= 4 else { throw ComparisonError("Unsupported PNG row filter") }
        for x in 0..<stride {
            let index = y * stride + x
            let left = x >= channels ? samples[index - channels] : 0
            let up = y > 0 ? samples[index - stride] : 0
            let upperLeft = y > 0 && x >= channels ? samples[index - stride - channels] : 0
            let predictor: UInt8
            switch filter {
            case 0: predictor = 0
            case 1: predictor = left
            case 2: predictor = up
            case 3: predictor = UInt8((Int(left) + Int(up)) / 2)
            default: predictor = paeth(left, up, upperLeft)
            }
            samples[index] = filtered[y * (stride + 1) + x + 1] &+ predictor
        }
    }
    var rgba = [UInt8](repeating: 255, count: width * height * 4)
    for pixel in 0..<(width * height) {
        for channel in 0..<channels { rgba[pixel * 4 + channel] = samples[pixel * channels + channel] }
    }
    return Pixels(width: width, height: height, rgba: rgba)
}

func writePNG(_ pixels: Pixels, to url: URL) throws {
    func bigEndian(_ value: Int) -> [UInt8] {
        [UInt8((value >> 24) & 255), UInt8((value >> 16) & 255), UInt8((value >> 8) & 255), UInt8(value & 255)]
    }
    var png = Data([137, 80, 78, 71, 13, 10, 26, 10])
    func appendChunk(_ name: String, _ content: [UInt8]) {
        let payload = Array(name.utf8) + content
        let checksum = payload.withUnsafeBufferPointer { crc32(0, $0.baseAddress, uInt(payload.count)) }
        png.append(contentsOf: bigEndian(content.count))
        png.append(contentsOf: payload)
        png.append(contentsOf: bigEndian(Int(checksum)))
    }
    appendChunk("IHDR", bigEndian(pixels.width) + bigEndian(pixels.height) + [8, 6, 0, 0, 0])
    var raw = [UInt8]()
    raw.reserveCapacity(pixels.rgba.count + pixels.height)
    let stride = pixels.width * 4
    for y in 0..<pixels.height {
        raw.append(0)
        raw.append(contentsOf: pixels.rgba[(y * stride)..<((y + 1) * stride)])
    }
    var size = compressBound(uLong(raw.count))
    var compressed = [UInt8](repeating: 0, count: Int(size))
    let status = compressed.withUnsafeMutableBufferPointer { output in
        raw.withUnsafeBufferPointer { input in
            compress2(output.baseAddress, &size, input.baseAddress, uLong(raw.count), Z_BEST_COMPRESSION)
        }
    }
    guard status == Z_OK else { throw ComparisonError("PNG compression failed (\(status))") }
    appendChunk("IDAT", Array(compressed.prefix(Int(size))))
    appendChunk("IEND", [])
    try png.write(to: url, options: .atomic)
}

struct Metrics: Codable {
    let width: Int
    let height: Int
    let channelRange: String
    let comparisonSpace: String
    let differingPixelDefinition: String
    let meanAbsoluteRGBError: Double
    let rootMeanSquareRGBError: Double
    let maxRGBError: Int
    let differingRGBPixelsPercentage: Double
    let meanAbsoluteAlphaError: Double
    let maxAlphaError: Int
    let differingAlphaPixelsPercentage: Double
    let differingPixelsPercentage: Double
}

func measure(_ lhs: Pixels, _ rhs: Pixels) throws -> Metrics {
    guard lhs.width == rhs.width, lhs.height == rhs.height else { throw ComparisonError("Capture dimensions must match") }
    var rgbTotal = 0.0, rgbSquared = 0.0, alphaTotal = 0.0
    var rgbMax = 0, alphaMax = 0, rgbPixels = 0, alphaPixels = 0, anyPixels = 0
    let count = lhs.width * lhs.height
    for pixel in 0..<count {
        var rgbChanged = false
        for channel in 0..<3 {
            let delta = abs(Int(lhs.rgba[pixel * 4 + channel]) - Int(rhs.rgba[pixel * 4 + channel]))
            rgbTotal += Double(delta); rgbSquared += Double(delta * delta)
            rgbMax = max(rgbMax, delta); rgbChanged = rgbChanged || delta != 0
        }
        let alpha = abs(Int(lhs.rgba[pixel * 4 + 3]) - Int(rhs.rgba[pixel * 4 + 3]))
        alphaTotal += Double(alpha); alphaMax = max(alphaMax, alpha)
        if rgbChanged { rgbPixels += 1 }
        if alpha != 0 { alphaPixels += 1 }
        if rgbChanged || alpha != 0 { anyPixels += 1 }
    }
    func percent(_ changed: Int) -> Double { Double(changed) * 100 / Double(count) }
    return Metrics(
        width: lhs.width, height: lhs.height, channelRange: "0...255",
        comparisonSpace: "Raw encoded RGB/RGBA8 PNG samples; no color-profile conversion",
        differingPixelDefinition: "At least one RGBA channel differs by one or more integer levels",
        meanAbsoluteRGBError: rgbTotal / Double(count * 3),
        rootMeanSquareRGBError: sqrt(rgbSquared / Double(count * 3)),
        maxRGBError: rgbMax, differingRGBPixelsPercentage: percent(rgbPixels),
        meanAbsoluteAlphaError: alphaTotal / Double(count), maxAlphaError: alphaMax,
        differingAlphaPixelsPercentage: percent(alphaPixels), differingPixelsPercentage: percent(anyPixels))
}

func compose(_ left: Pixels, _ right: Pixels, title: String, leftLabel: String,
             rightLabel: String, metrics: Metrics) throws -> Pixels {
    let margin = 24, gap = 16, imageTop = 120
    let width = margin * 2 + left.width * 2 + gap
    let height = imageTop + left.height + 84
    guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                  bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue),
          let buffer = context.data else { throw ComparisonError("Could not allocate comparison canvas") }
    context.setFillColor(red: 15 / 255, green: 18 / 255, blue: 25 / 255, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    func label(_ text: String, x: Int, top: Int, size: CGFloat, weight: NSFont.Weight, color: NSColor, maxWidth: Int) {
        let boxHeight = Int(ceil(size * 1.5))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color
        ]
        (text as NSString).draw(in: NSRect(x: x, y: height - top - boxHeight, width: maxWidth, height: boxHeight), withAttributes: attributes)
    }
    let white = NSColor(srgbRed: 0.94, green: 0.96, blue: 1, alpha: 1)
    let muted = NSColor(srgbRed: 0.58, green: 0.64, blue: 0.74, alpha: 1)
    let available = width - margin * 2
    label(title, x: margin, top: 19, size: 26, weight: .semibold, color: white, maxWidth: available)
    label("Matched captures · \(left.width) × \(left.height) pixels each · no rescaling", x: margin, top: 58, size: 13, weight: .regular, color: muted, maxWidth: available)
    label(leftLabel, x: margin, top: 88, size: 16, weight: .medium, color: white, maxWidth: left.width)
    label(rightLabel, x: margin + left.width + gap, top: 88, size: 16, weight: .medium, color: white, maxWidth: left.width)
    let summary = String(format: "RGB mean error: %.4f / 255    ·    Maximum: %d / 255    ·    Pixels differing: %.4f%%", metrics.meanAbsoluteRGBError, metrics.maxRGBError, metrics.differingPixelsPercentage)
    label(summary, x: margin, top: imageTop + left.height + 17, size: 13, weight: .medium, color: white, maxWidth: available)
    let alpha = String(format: "Alpha mean error: %.4f / 255 · max %d / 255. Any nonzero RGBA difference counts; no tolerance is hidden.", metrics.meanAbsoluteAlphaError, metrics.maxAlphaError)
    label(alpha, x: margin, top: imageTop + left.height + 43, size: 12, weight: .regular, color: muted, maxWidth: available)
    NSGraphicsContext.restoreGraphicsState()
    var canvas = Pixels(width: width, height: height, rgba: Array(UnsafeBufferPointer(start: buffer.assumingMemoryBound(to: UInt8.self), count: width * height * 4)))
    // These copies preserve every image byte, including alpha. No CGContext image
    // drawing, interpolation, color management, or compositing touches captures.
    for (source, x) in [(left, margin), (right, margin + left.width + gap)] {
        for y in 0..<source.height {
            let start = ((imageTop + y) * width + x) * 4
            let sourceStart = y * source.width * 4
            canvas.rgba.replaceSubrange(start..<(start + source.width * 4), with: source.rgba[sourceStart..<(sourceStart + source.width * 4)])
        }
    }
    return canvas
}

do {
    let args = Array(CommandLine.arguments.dropFirst())
    guard args.count >= 6, args.count % 2 == 0 else {
        throw ComparisonError("Usage: compare <left.png> <right.png> <comparison.png> <metrics.json> --title NAME [--left-label TEXT --right-label TEXT]")
    }
    var options: [String: String] = [:]
    for index in stride(from: 4, to: args.count, by: 2) {
        let key = args[index]
        guard ["--title", "--left-label", "--right-label"].contains(key), options[key] == nil else {
            throw ComparisonError("Unknown or duplicate option: \(key)")
        }
        options[key] = args[index + 1]
    }
    guard let title = options["--title"] else { throw ComparisonError("--title is required") }
    let left = try readPNG(URL(fileURLWithPath: args[0]))
    let right = try readPNG(URL(fileURLWithPath: args[1]))
    let metrics = try measure(left, right)
    let composite = try compose(left, right, title: title,
                                leftLabel: options["--left-label"] ?? "GLSL · OpenGL",
                                rightLabel: options["--right-label"] ?? "Metal · offscreen",
                                metrics: metrics)
    try writePNG(composite, to: URL(fileURLWithPath: args[2]))
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    var json = try encoder.encode(metrics)
    json.append(0x0A)
    try json.write(to: URL(fileURLWithPath: args[3]), options: .atomic)
    print(String(format: "RGB MAE %.6f/255, max %d/255; differing pixels %.6f%%; alpha MAE %.6f/255", metrics.meanAbsoluteRGBError, metrics.maxRGBError, metrics.differingPixelsPercentage, metrics.meanAbsoluteAlphaError))
} catch {
    FileHandle.standardError.write(Data("compare: \(error)\n".utf8))
    exit(1)
}
