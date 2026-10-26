import SwiftUI
import MetalKit
import QuartzCore

/// Add this file and effect.metal to the app target. Supply the two bundled PNG
/// URLs. `time` is fixed for reproducible frames; an external timeline may update
/// it without rebuilding the pipeline or reloading the textures.
///
/// The display uses BGRA8Unorm, which CAMetalLayer supports. The comparison
/// harness uses RGBA8Unorm offscreen: both store the same unorm color components,
/// with different byte order. Window compositing may still color-manage display
/// output; the published comparisons measure raw offscreen channels instead.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
public struct TwoTextureBlendView: View {
    public let firstTextureURL: URL
    public let secondTextureURL: URL
    public var time: Float
    public let shaderBundle: Bundle

    @State private var state: LoadState = .loading

    public init(
        firstTextureURL: URL,
        secondTextureURL: URL,
        time: Float = 1.25,
        shaderBundle: Bundle = .main
    ) {
        self.firstTextureURL = firstTextureURL
        self.secondTextureURL = secondTextureURL
        self.time = time
        self.shaderBundle = shaderBundle
    }

    public var body: some View {
        Group {
            if !time.isFinite {
                unavailable("Time must be a finite number of seconds.")
            } else {
                switch state {
                case .loading:
                    ProgressView("Loading shader…")
                case .failed(let message):
                    unavailable(message)
                case .ready(let renderer):
                    TwoTextureMetalBridge(renderer: renderer, time: time)
                        // A new resource set needs a new retained coordinator.
                        .id(ObjectIdentifier(renderer))
                }
            }
        }
        .task(id: InputIdentity(
            first: firstTextureURL, second: secondTextureURL,
            bundle: shaderBundle.bundleURL
        )) {
            do {
                state = .ready(try TwoTextureRenderer(
                    firstURL: firstTextureURL, secondURL: secondTextureURL,
                    shaderBundle: shaderBundle
                ))
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func unavailable(_ message: String) -> some View {
        ContentUnavailableView(
            "Shader unavailable", systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }

    private struct InputIdentity: Hashable {
        let first: URL
        let second: URL
        let bundle: URL
    }

    private enum LoadState {
        case loading
        case ready(TwoTextureRenderer)
        case failed(String)
    }
}

private struct BlendUniforms {
    var resolution: SIMD2<Float>
    var time: Float
    var displayScale: Float = 1 // Matches the Metal struct's 16-byte layout.
}

private enum BlendSetupError: LocalizedError {
    case deviceUnavailable
    case queueUnavailable
    case missingShaderFunctions
    case invalidUniformLayout

    var errorDescription: String? {
        switch self {
        case .deviceUnavailable: return "This device does not provide a Metal GPU."
        case .queueUnavailable: return "Metal could not create a command queue."
        case .missingShaderFunctions:
            return "Add effect.metal to the app target, or pass the bundle containing twoTextureVertex and twoTextureFragment."
        case .invalidUniformLayout: return "Swift and Metal uniform layouts do not match."
        }
    }
}

@MainActor
private final class TwoTextureRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    private let queue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let firstTexture: MTLTexture
    private let secondTexture: MTLTexture
    private var time: Float = 0

    init(firstURL: URL, secondURL: URL, shaderBundle: Bundle) throws {
        guard MemoryLayout<BlendUniforms>.stride == 16 else {
            throw BlendSetupError.invalidUniformLayout
        }
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw BlendSetupError.deviceUnavailable
        }
        guard let queue = device.makeCommandQueue() else {
            throw BlendSetupError.queueUnavailable
        }
        let library = try device.makeDefaultLibrary(bundle: shaderBundle)
        guard let vertex = library.makeFunction(name: "twoTextureVertex"),
              let fragment = library.makeFunction(name: "twoTextureFragment") else {
            throw BlendSetupError.missingShaderFunctions
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = false
        descriptor.rasterSampleCount = 1
        let loader = MTKTextureLoader(device: device)
        let textureOptions: [MTKTextureLoader.Option: Any] = [
            .SRGB: false,
            .origin: MTKTextureLoader.Origin.topLeft.rawValue,
            .generateMipmaps: false,
            .textureUsage: MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode: MTLStorageMode.private.rawValue
        ]
        self.device = device
        self.queue = queue
        self.pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        self.firstTexture = try loader.newTexture(URL: firstURL, options: textureOptions)
        self.secondTexture = try loader.newTexture(URL: secondURL, options: textureOptions)
        super.init()
    }

    func makeView(time: Float) -> MTKView {
        let view = MTKView(frame: .zero, device: device)
        view.colorPixelFormat = .bgra8Unorm
        #if os(macOS)
        view.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        #else
        (view.layer as? CAMetalLayer)?.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        #endif
        view.sampleCount = 1
        view.framebufferOnly = true
        view.autoResizeDrawable = true
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        view.clearColor = MTLClearColorMake(0, 0, 0, 1)
        view.delegate = self
        update(time: time, view: view)
        return view
    }

    func update(time: Float, view: MTKView) {
        self.time = time
        requestDraw(view)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // autoResizeDrawable follows layout and backing-scale changes. The next
        // draw reads the actual drawable dimensions, not cached screen points.
        requestDraw(view)
    }

    func draw(in view: MTKView) {
        guard time.isFinite, view.drawableSize.width > 0, view.drawableSize.height > 0,
              let drawable = view.currentDrawable,
              let pass = view.currentRenderPassDescriptor,
              let command = queue.makeCommandBuffer(),
              let encoder = command.makeRenderCommandEncoder(descriptor: pass) else {
            // A hidden, zero-sized, or temporarily unavailable drawable can be
            // skipped; a subsequent layout/parameter invalidation draws again.
            return
        }
        var uniforms = BlendUniforms(
            resolution: SIMD2(Float(drawable.texture.width), Float(drawable.texture.height)),
            time: time
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setCullMode(.none)
        // setFragmentBytes copies this small value into command-owned storage;
        // no shared uniform buffer is overwritten while the GPU reads it.
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<BlendUniforms>.stride, index: 0)
        encoder.setFragmentTexture(firstTexture, index: 0)
        encoder.setFragmentTexture(secondTexture, index: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        command.present(drawable)
        command.commit()
    }

    func dismantle(_ view: MTKView) {
        view.isPaused = true
        view.delegate = nil
        view.releaseDrawables()
    }

    private func requestDraw(_ view: MTKView) {
        #if os(macOS)
        view.needsDisplay = true
        #else
        view.setNeedsDisplay()
        #endif
    }
}

#if os(macOS)
@MainActor
private struct TwoTextureMetalBridge: NSViewRepresentable {
    let renderer: TwoTextureRenderer
    let time: Float

    func makeCoordinator() -> TwoTextureRenderer { renderer }
    func makeNSView(context: Context) -> MTKView { context.coordinator.makeView(time: time) }
    func updateNSView(_ view: MTKView, context: Context) {
        context.coordinator.update(time: time, view: view)
    }
    static func dismantleNSView(_ view: MTKView, coordinator: TwoTextureRenderer) {
        coordinator.dismantle(view)
    }
}
#else
// iOS and Mac Catalyst use the UIKit bridge.
@MainActor
private struct TwoTextureMetalBridge: UIViewRepresentable {
    let renderer: TwoTextureRenderer
    let time: Float

    func makeCoordinator() -> TwoTextureRenderer { renderer }
    func makeUIView(context: Context) -> MTKView { context.coordinator.makeView(time: time) }
    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.update(time: time, view: view)
    }
    static func dismantleUIView(_ view: MTKView, coordinator: TwoTextureRenderer) {
        coordinator.dismantle(view)
    }
}
#endif
