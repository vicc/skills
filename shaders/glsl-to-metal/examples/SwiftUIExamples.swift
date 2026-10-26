import SwiftUI

/// Add both stitchable example .metal files to the app target without
/// COMPARISON_CAPTURE. Time is explicit so previews and captures are repeatable.
@available(iOS 17.0, macOS 14.0, *)
struct AuroraRibbonsExample: View {
    var time: Float = 1.25

    var body: some View {
        Rectangle().fill(ShaderLibrary.auroraRibbons(.boundingRect, .float(time)))
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct RippleDistortionExample: View {
    var image: Image
    var time: Float = 1.25
    var amplitude: Float = 7

    var body: some View {
        image.resizable().aspectRatio(8.0 / 5.0, contentMode: .fit)
            .visualEffect { content, geometry in
                content.distortionEffect(
                    ShaderLibrary.rippleDistortion(
                        .float2(geometry.size), .float(time), .float(amplitude)
                    ),
                    maxSampleOffset: CGSize(width: CGFloat(abs(amplitude)),
                                           height: CGFloat(abs(amplitude)))
                )
            }
    }
}

/// Optional animation for the procedural example. Fixed-time views above are
/// preferable when comparing captures. This wrapper freezes while inactive,
/// offscreen, or under Reduce Motion, and resumes without counting paused time.
@available(iOS 17.0, macOS 14.0, *)
struct AnimatedAuroraExample: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phaseClock = AuroraClock()
    @State private var visible = false

    private var shouldAnimate: Bool { visible && scenePhase == .active && !reduceMotion }

    var body: some View {
        TimelineView(.animation(paused: !shouldAnimate)) { _ in
            AuroraRibbonsExample(time: Float(phaseClock.elapsed()))
        }
        .onAppear { visible = true; phaseClock.setRunning(!reduceMotion && scenePhase == .active) }
        .onDisappear { phaseClock.setRunning(false); visible = false }
        .onChange(of: shouldAnimate) { _, running in phaseClock.setRunning(running) }
    }
}

private struct AuroraClock {
    private var started = ContinuousClock.now
    private var stored: Double = 0
    private var running = false

    func elapsed() -> Double {
        guard running else { return stored }
        let span = started.duration(to: .now).components
        // Both time frequencies (0.65 and 0.4) repeat after 40*pi seconds.
        // Reducing this shared period keeps Float precision without a phase jump.
        return (stored + Double(span.seconds) + Double(span.attoseconds) / 1e18)
            .truncatingRemainder(dividingBy: 40 * .pi)
    }

    mutating func setRunning(_ value: Bool) {
        stored = elapsed()
        started = .now
        running = value
    }
}
