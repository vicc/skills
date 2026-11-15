import Foundation
import SwiftUI

@main
struct CheckBindings {
    @MainActor
    static func main() async throws {
        guard CommandLine.arguments.count == 2 else {
            print("Usage: check-bindings <production.metallib>")
            exit(1)
        }
        guard #available(macOS 15.0, *) else {
            print("SKIP: SwiftUI precompilation needs macOS 15+. Static builds still apply.")
            return
        }
        let library = ShaderLibrary(url: URL(fileURLWithPath: CommandLine.arguments[1]))
        let aurora = Shader(function: ShaderFunction(library: library, name: "auroraRibbons"),
                            arguments: [.boundingRect, .float(1.25)])
        try await aurora.compile(as: .shapeStyle)
        let ripple = Shader(function: ShaderFunction(library: library, name: "rippleDistortion"),
                            arguments: [.float2(640, 400), .float(1.25), .float(7)])
        try await ripple.compile(as: .distortionEffect)
        for name in ["negativeModulo", "noiseHash"] {
            let shader = Shader(function: ShaderFunction(library: library, name: name),
                                arguments: [.boundingRect, .float(1.25)])
            try await shader.compile(as: .shapeStyle)
        }
        print("PASS: SwiftUI shape-style and distortion shader bindings precompiled on this Mac.")
    }
}
