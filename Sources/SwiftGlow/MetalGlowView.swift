import MetalKit
import SwiftUI

struct MetalGlowView {
    static let margin: CGFloat = 100

    var configuration: GlowConfig
    var isVisible: Bool
    var contentSize: CGSize
}

#if canImport(UIKit)
extension MetalGlowView: UIViewRepresentable {
    func makeCoordinator() -> GlowRenderer {
        GlowRenderer()
    }

    func makeUIView(context: Context) -> MTKView {
        makeView(context: context)
    }

    func updateUIView(_ view: MTKView, context: Context) {
        update(view, coordinator: context.coordinator)
    }
}
#elseif canImport(AppKit)
extension MetalGlowView: NSViewRepresentable {
    func makeCoordinator() -> GlowRenderer {
        GlowRenderer()
    }

    func makeNSView(context: Context) -> MTKView {
        makeView(context: context)
    }

    func updateNSView(_ view: MTKView, context: Context) {
        update(view, coordinator: context.coordinator)
    }
}
#endif

private extension MetalGlowView {
    func makeView(context: Any) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.framebufferOnly = true
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.colorPixelFormat = .bgra8Unorm
        #if canImport(UIKit)
        view.isOpaque = false
        #elseif canImport(AppKit)
        view.layer?.isOpaque = false
        #endif
        view.delegate = renderer(from: context)
        renderer(from: context).attach(to: view)
        return view
    }

    func update(_ view: MTKView, coordinator: GlowRenderer) {
        coordinator.update(configuration: configuration, isVisible: isVisible, contentSize: contentSize)
        view.isPaused = !isVisible
    }

    func renderer(from context: Any) -> GlowRenderer {
        #if canImport(UIKit)
        if let context = context as? UIViewRepresentableContext<MetalGlowView> {
            return context.coordinator
        }
        #elseif canImport(AppKit)
        if let context = context as? NSViewRepresentableContext<MetalGlowView> {
            return context.coordinator
        }
        #endif
        return GlowRenderer()
    }
}
