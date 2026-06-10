import MetalKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MetalGlowView {
    static let margin: CGFloat = 100

    var configuration: GlowConfig
    var activeState: GlowEvent
    var states: [GlowState]
    var isVisible: Bool
    var contentSize: CGSize
}

#if canImport(UIKit)
extension MetalGlowView: UIViewRepresentable {
    func makeCoordinator() -> GlowRenderer {
        GlowRenderer()
    }

    func makeUIView(context: Context) -> MTKView {
        makeView(renderer: context.coordinator)
    }

    func updateUIView(_ view: MTKView, context: Context) {
        update(view, renderer: context.coordinator)
    }
}
#elseif canImport(AppKit)
final class GlowMTKView: MTKView {
    override var acceptsFirstResponder: Bool {
        false
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

extension MetalGlowView: NSViewRepresentable {
    func makeCoordinator() -> GlowRenderer {
        GlowRenderer()
    }

    func makeNSView(context: Context) -> MTKView {
        makeView(renderer: context.coordinator)
    }

    func updateNSView(_ view: MTKView, context: Context) {
        update(view, renderer: context.coordinator)
    }
}
#endif

private extension MetalGlowView {
    func makeView(renderer: GlowRenderer) -> MTKView {
        #if canImport(AppKit)
        let view = GlowMTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        #else
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        #endif
        view.framebufferOnly = true
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.colorPixelFormat = .bgra8Unorm
        #if canImport(UIKit)
        view.isOpaque = false
        view.backgroundColor = .clear
        #elseif canImport(AppKit)
        view.layer?.isOpaque = false
        #endif
        view.delegate = renderer
        renderer.attach(to: view)
        return view
    }

    func update(_ view: MTKView, renderer: GlowRenderer) {
        renderer.update(
            configuration: configuration,
            activeState: activeState,
            states: states,
            isVisible: isVisible,
            contentSize: contentSize
        )
        view.isPaused = !isVisible
    }
}
