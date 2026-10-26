// Render a compiled example on the actual Metal GPU and save its raw RGBA8 output.
// Build: xcrun swiftc render-metal.swift -o render-metal
// Run:   render-metal --library effect.metallib --output metal.png \
//          --width 640 --height 400 --time 1.25 [--texture0 input.png]
//
// This is an offscreen render-pipeline capture, not a SwiftUI window screenshot.
// Input fixtures are opaque PNGs. Texture v=0 addresses their top row, matching
// render-glsl. Output is tagged sRGB without converting the numeric channels.
import Foundation
import Metal
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

struct CaptureError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

struct Options {
    let library: URL
    let output: URL
    let width: Int
    let height: Int
    let time: Float
    let displayScale: Float
    let textures: [Int: URL]

    init(arguments: [String]) throws {
        var values: [String: String] = [:]
        let accepted: Set<String> = [
            "--library", "--output", "--width", "--height", "--time",
            "--texture0", "--texture1"
        ]
        var index = 0
        while index < arguments.count {
            let key = arguments[index]
            guard accepted.contains(key), index + 1 < arguments.count else {
                throw CaptureError("Expected --library FILE --output PNG [--width N --height N --time SECONDS --texture0 PNG --texture1 PNG]; invalid or incomplete argument: \(key)")
            }
            guard values[key] == nil else { throw CaptureError("Duplicate argument: \(key)") }
            values[key] = arguments[index + 1]
            index += 2
        }
        guard let libraryPath = values["--library"], let outputPath = values["--output"] else {
            throw CaptureError("Both --library and --output are required.")
        }
        guard let width = Int(values["--width"] ?? "640"),
              let height = Int(values["--height"] ?? "400"),
              (1...8192).contains(width), (1...8192).contains(height) else {
            throw CaptureError("Width and height must be integers from 1 through 8192.")
        }
        guard let time = Float(values["--time"] ?? "1.25"), time.isFinite else {
            throw CaptureError("Time must be finite.")
        }
        self.library = URL(fileURLWithPath: libraryPath)
        self.output = URL(fileURLWithPath: outputPath)
        self.width = width
        self.height = height
        self.time = time
        self.displayScale = 1 // Captures use one user-space unit per pixel.
        var textures: [Int: URL] = [:]
        for slot in 0...1 {
            if let path = values["--texture\(slot)"] {
                textures[slot] = URL(fileURLWithPath: path)
            }
        }
        self.textures = textures
    }
}

// Do not add fields without updating the Metal header and its layout assertion.
struct ComparisonUniforms {
    var resolution: SIMD2<Float>
    var time: Float
    var displayScale: Float
}

func loadTexture(_ url: URL, device: MTLDevice) throws -> MTLTexture {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw CaptureError("Cannot decode texture: \(url.path)")
    }
    guard image.width > 0, image.height > 0,
          image.width <= 8192, image.height <= 8192 else {
        throw CaptureError("Texture dimensions must be between 1 and 8192 pixels.")
    }
    // Matching the source color space avoids an explicit color-space conversion.
    // With the opaque sRGB fixtures, premultiplication leaves channels unchanged.
    let sourceSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
    guard sourceSpace.model == .rgb else {
        throw CaptureError("Texture fixtures must be RGB PNGs: \(url.lastPathComponent)")
    }
    let bytesPerRow = image.width * 4
    var bytes = [UInt8](repeating: 0, count: bytesPerRow * image.height)
    try bytes.withUnsafeMutableBytes { storage in
        guard let context = CGContext(
            data: storage.baseAddress, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: sourceSpace,
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue |
                CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { throw CaptureError("Cannot create texture decode context.") }
        context.setBlendMode(.copy)
        context.interpolationQuality = .none
        // No transform: first memory row is the source PNG's top row.
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    }
    // The examples use opaque source fixtures, keeping PNG and GPU alpha
    // conventions identical. Fail loudly rather than silently premultiplying.
    guard stride(from: 3, to: bytes.count, by: 4).allSatisfy({ bytes[$0] == 255 }) else {
        throw CaptureError("Texture fixtures must be opaque: \(url.lastPathComponent)")
    }
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm, width: image.width, height: image.height, mipmapped: false
    )
    descriptor.storageMode = .shared
    descriptor.usage = .shaderRead
    guard let texture = device.makeTexture(descriptor: descriptor) else {
        throw CaptureError("Cannot allocate texture: \(url.lastPathComponent)")
    }
    bytes.withUnsafeBytes { storage in
        texture.replace(
            region: MTLRegionMake2D(0, 0, image.width, image.height), mipmapLevel: 0,
            withBytes: storage.baseAddress!, bytesPerRow: bytesPerRow
        )
    }
    return texture
}

func writePNG(_ bytes: Data, width: Int, height: Int, to url: URL) throws {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let provider = CGDataProvider(data: bytes as CFData),
          let image = CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: width * 4, space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue |
                CGImageAlphaInfo.last.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
          ) else { throw CaptureError("Cannot construct output image.") }
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw CaptureError("Cannot create output PNG: \(url.path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw CaptureError("Cannot finish output PNG: \(url.path)")
    }
}

func capture(_ options: Options) throws {
    guard MemoryLayout<ComparisonUniforms>.stride == 16 else {
        throw CaptureError("Unexpected Swift/Metal uniform layout.")
    }
    guard let device = MTLCreateSystemDefaultDevice(),
          let queue = device.makeCommandQueue() else {
        throw CaptureError("No Metal device or command queue is available.")
    }
    let library = try device.makeLibrary(URL: options.library)
    guard let vertex = library.makeFunction(name: "comparisonVertex"),
          let fragment = library.makeFunction(name: "comparisonFragment") else {
        throw CaptureError("The library must export comparisonVertex and comparisonFragment.")
    }
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertex
    pipelineDescriptor.fragmentFunction = fragment
    // Stitchable functions are visible functions. Explicitly link them so the
    // capture fragment can call the same entry points SwiftUI uses.
    let linked = MTLLinkedFunctions()
    linked.privateFunctions = library.functionNames.compactMap { library.makeFunction(name: $0) }
        .filter { $0.functionType == .visible }
    pipelineDescriptor.fragmentLinkedFunctions = linked
    pipelineDescriptor.rasterSampleCount = 1
    pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled = false
    var reflection: MTLRenderPipelineReflection?
    let pipeline = try device.makeRenderPipelineState(
        descriptor: pipelineDescriptor, options: .bindingInfo, reflection: &reflection
    )
    guard let reflection else { throw CaptureError("Metal did not return shader binding information.") }
    for binding in reflection.fragmentBindings where binding.isUsed && binding.type == .texture {
        guard options.textures[binding.index] != nil else {
            throw CaptureError("Shader requires texture(\(binding.index)); supply --texture\(binding.index) PNG.")
        }
    }

    let targetDescriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm, width: options.width, height: options.height, mipmapped: false
    )
    targetDescriptor.storageMode = .private
    targetDescriptor.usage = .renderTarget
    guard let target = device.makeTexture(descriptor: targetDescriptor) else {
        throw CaptureError("Cannot allocate output texture.")
    }
    // A 256-byte pitch works across the supported Metal GPU families.
    let packedRowBytes = options.width * 4
    let alignedRowBytes = (packedRowBytes + 255) & ~255
    guard let readback = device.makeBuffer(length: alignedRowBytes * options.height, options: .storageModeShared),
          let command = queue.makeCommandBuffer() else {
        throw CaptureError("Cannot allocate capture resources.")
    }
    var textures: [Int: MTLTexture] = [:]
    for (slot, url) in options.textures { textures[slot] = try loadTexture(url, device: device) }
    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].texture = target
    pass.colorAttachments[0].loadAction = .clear
    pass.colorAttachments[0].storeAction = .store
    pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
    guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else {
        throw CaptureError("Cannot create render encoder.")
    }
    encoder.setRenderPipelineState(pipeline)
    encoder.setCullMode(.none)
    encoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(options.width), height: Double(options.height), znear: 0, zfar: 1))
    var uniforms = ComparisonUniforms(
        resolution: SIMD2(Float(options.width), Float(options.height)),
        time: options.time, displayScale: options.displayScale
    )
    encoder.setFragmentBytes(&uniforms, length: MemoryLayout<ComparisonUniforms>.stride, index: 0)
    for (slot, texture) in textures { encoder.setFragmentTexture(texture, index: slot) }
    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    encoder.endEncoding()
    guard let blit = command.makeBlitCommandEncoder() else {
        throw CaptureError("Cannot create readback encoder.")
    }
    blit.copy(
        from: target, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
        sourceSize: MTLSize(width: options.width, height: options.height, depth: 1),
        to: readback, destinationOffset: 0, destinationBytesPerRow: alignedRowBytes,
        destinationBytesPerImage: alignedRowBytes * options.height
    )
    blit.endEncoding()
    command.commit()
    command.waitUntilCompleted()
    if let error = command.error { throw CaptureError("Metal rendering failed: \(error.localizedDescription)") }
    guard command.status == .completed else { throw CaptureError("Metal command buffer did not complete.") }
    var packedBytes = Data(count: packedRowBytes * options.height)
    packedBytes.withUnsafeMutableBytes { destination in
        for row in 0..<options.height {
            destination.baseAddress!.advanced(by: row * packedRowBytes).copyMemory(
                from: readback.contents().advanced(by: row * alignedRowBytes), byteCount: packedRowBytes
            )
        }
    }
    try writePNG(packedBytes, width: options.width, height: options.height, to: options.output)
    let metadata: [String: Any] = [
        "api": "Metal", "device": device.name,
        "os": ProcessInfo.processInfo.operatingSystemVersionString,
        "pixelFormat": "RGBA8Unorm", "origin": "top-left",
        "width": options.width, "height": options.height,
        "time": options.time, "displayScale": options.displayScale,
        "capture": "offscreen-render-pipeline", "textureCount": textures.count
    ]
    let json = try JSONSerialization.data(withJSONObject: metadata, options: [.sortedKeys])
    print(String(decoding: json, as: UTF8.self))
}

do {
    try capture(Options(arguments: Array(CommandLine.arguments.dropFirst())))
} catch {
    FileHandle.standardError.write(Data("render-metal: \(error)\n".utf8))
    exit(1)
}
