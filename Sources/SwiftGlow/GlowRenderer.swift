import Foundation
import MetalKit
import QuartzCore

final class GlowRenderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var startTime = CACurrentMediaTime()
    private var lastTime = CACurrentMediaTime()
    private var borderProgress: Float = 0
    private var layerProgress = Array(repeating: Float(0), count: GlowCompatibility.maximumLayerCount)
    private var configuration = GlowConfig()
    private var isVisible = true
    private var contentSize: CGSize = .zero

    func attach(to view: MTKView) {
        guard let device = view.device else {
            return
        }
        self.device = device
        commandQueue = device.makeCommandQueue()
        vertexBuffer = makeVertexBuffer(device: device)
        pipelineState = makePipelineState(device: device, pixelFormat: view.colorPixelFormat)
    }

    func update(configuration: GlowConfig, isVisible: Bool, contentSize: CGSize) {
        self.configuration = configuration
        self.isVisible = isVisible
        self.contentSize = contentSize
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard isVisible,
              let commandQueue,
              let pipelineState,
              let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              contentSize.width > 0,
              contentSize.height > 0 else {
            return
        }

        let now = CACurrentMediaTime()
        let deltaTime = Float(now - lastTime)
        lastTime = now
        advance(deltaTime: deltaTime)

        var uniforms = makeUniforms(
            drawableSize: view.drawableSize,
            boundsSize: view.bounds.size
        )
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<GlowUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func advance(deltaTime: Float) {
        let animationSpeed = configuration.animationSpeed ?? 0.7
        let borderSpeedMultiplier = configuration.borderSpeedMultiplier ?? 1
        borderProgress = fmod(borderProgress + deltaTime * GlowCompatibility.speedFactor * animationSpeed * borderSpeedMultiplier, 1)

        let layers = configuration.glowLayers ?? []
        for index in 0..<GlowCompatibility.maximumLayerCount {
            let speedMultiplier = layers.indices.contains(index) ? layers[index].speedMultiplier ?? 1 : 0
            layerProgress[index] = fmod(layerProgress[index] + deltaTime * GlowCompatibility.speedFactor * animationSpeed * speedMultiplier, 1)
        }
    }

    private func makeUniforms(drawableSize: CGSize, boundsSize: CGSize) -> GlowUniforms {
        var uniforms = GlowUniforms()
        let scaleX = boundsSize.width > 0 ? Float(drawableSize.width / boundsSize.width) : 1
        let scaleY = boundsSize.height > 0 ? Float(drawableSize.height / boundsSize.height) : 1
        let uniformScale = min(scaleX, scaleY)

        uniforms.resolution = SIMD2(Float(drawableSize.width), Float(drawableSize.height))
        uniforms.rectSize = SIMD2(
            Float(contentSize.width) * scaleX,
            Float(contentSize.height) * scaleY
        )
        uniforms.cornerRadius = min(
            (configuration.cornerRadius ?? 10) * uniformScale,
            Float(contentSize.width / 2) * scaleX,
            Float(contentSize.height / 2) * scaleY
        )
        uniforms.borderWidth = (configuration.outlineWidth ?? 2) * uniformScale
        uniforms.borderProgress = borderProgress
        uniforms.masterOpacity = isVisible ? 1 : 0
        uniforms.backgroundColor = (configuration.backgroundColor ?? GlowColor.clear).simd
        uniforms.isBorderAnimated = (configuration.borderColor?.count ?? 0) > 1 ? 1 : 0

        fillBorderColors(&uniforms)
        fillLayers(&uniforms, scale: uniformScale)
        return uniforms
    }

    private func fillBorderColors(_ uniforms: inout GlowUniforms) {
        let colors = GlowCompatibility.sampleSeamlessColors(configuration.borderColor ?? [.white])
        for index in 0..<GlowCompatibility.sampledColorCount {
            setBorderColor(colors[index].simd, at: index, in: &uniforms)
        }
    }

    private func fillLayers(_ uniforms: inout GlowUniforms, scale: Float) {
        let layers = Array((configuration.glowLayers ?? []).prefix(GlowCompatibility.maximumLayerCount))
        uniforms.layerCount = UInt32(layers.count)

        for index in 0..<GlowCompatibility.maximumLayerCount {
            guard layers.indices.contains(index) else {
                continue
            }

            let layer = layers[index]
            var layerUniform = GlowLayerUniform()
            layerUniform.coverage = layer.coverage ?? 1
            layerUniform.opacity = layer.opacity ?? 0.5
            layerUniform.relativeOffset = layer.relativeOffset ?? 0
            layerUniform.placement = (layer.glowPlacement ?? GlowPlacement.behind).shaderValue
            layerUniform.progress = layerProgress[index]
            layerUniform.glowSize = GlowCompatibility.glowSizeVector(layer.glowSize) * scale
            setLayer(layerUniform, at: index, in: &uniforms)

            let colors = GlowCompatibility.sampleSeamlessColors(layer.colors ?? [])
            for colorIndex in 0..<GlowCompatibility.sampledColorCount {
                setLayerColor(colors[colorIndex].simd, layer: index, color: colorIndex, in: &uniforms)
            }
        }
    }

    private func makeVertexBuffer(device: MTLDevice) -> MTLBuffer? {
        let vertices: [SIMD2<Float>] = [
            SIMD2(-1, -1),
            SIMD2(1, -1),
            SIMD2(-1, 1),
            SIMD2(1, 1)
        ]
        return device.makeBuffer(bytes: vertices, length: MemoryLayout<SIMD2<Float>>.stride * vertices.count)
    }

    private func makePipelineState(device: MTLDevice, pixelFormat: MTLPixelFormat) -> MTLRenderPipelineState? {
        guard let shaderURL = Bundle.module.url(forResource: "GlowShaders", withExtension: "metal") else {
            print("SwiftGlow: GlowShaders.metal resource was not found.")
            return nil
        }
        guard let shaderSource = try? String(contentsOf: shaderURL) else {
            print("SwiftGlow: failed to read GlowShaders.metal.")
            return nil
        }

        let library: MTLLibrary
        do {
            library = try device.makeLibrary(source: shaderSource, options: nil)
        } catch {
            print("SwiftGlow: failed to compile Metal shader: \(error)")
            return nil
        }

        guard let vertexFunction = library.makeFunction(name: "glowVertex"),
              let fragmentFunction = library.makeFunction(name: "glowFragment") else {
            print("SwiftGlow: glowVertex or glowFragment function was not found.")
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        do {
            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("SwiftGlow: failed to create pipeline state: \(error)")
            return nil
        }
    }
}

private extension GlowRenderer {
    func setLayer(_ value: GlowLayerUniform, at index: Int, in uniforms: inout GlowUniforms) {
        switch index {
        case 0: uniforms.layers.0 = value
        case 1: uniforms.layers.1 = value
        case 2: uniforms.layers.2 = value
        case 3: uniforms.layers.3 = value
        case 4: uniforms.layers.4 = value
        case 5: uniforms.layers.5 = value
        case 6: uniforms.layers.6 = value
        case 7: uniforms.layers.7 = value
        case 8: uniforms.layers.8 = value
        case 9: uniforms.layers.9 = value
        default: break
        }
    }

    func setBorderColor(_ value: SIMD4<Float>, at index: Int, in uniforms: inout GlowUniforms) {
        switch index {
        case 0: uniforms.borderColors.0 = value
        case 1: uniforms.borderColors.1 = value
        case 2: uniforms.borderColors.2 = value
        case 3: uniforms.borderColors.3 = value
        case 4: uniforms.borderColors.4 = value
        case 5: uniforms.borderColors.5 = value
        case 6: uniforms.borderColors.6 = value
        case 7: uniforms.borderColors.7 = value
        default: break
        }
    }

    func setLayerColor(_ value: SIMD4<Float>, layer: Int, color: Int, in uniforms: inout GlowUniforms) {
        let index = layer * GlowCompatibility.sampledColorCount + color
        switch index {
        case 0: uniforms.layerColors.0 = value
        case 1: uniforms.layerColors.1 = value
        case 2: uniforms.layerColors.2 = value
        case 3: uniforms.layerColors.3 = value
        case 4: uniforms.layerColors.4 = value
        case 5: uniforms.layerColors.5 = value
        case 6: uniforms.layerColors.6 = value
        case 7: uniforms.layerColors.7 = value
        case 8: uniforms.layerColors.8 = value
        case 9: uniforms.layerColors.9 = value
        case 10: uniforms.layerColors.10 = value
        case 11: uniforms.layerColors.11 = value
        case 12: uniforms.layerColors.12 = value
        case 13: uniforms.layerColors.13 = value
        case 14: uniforms.layerColors.14 = value
        case 15: uniforms.layerColors.15 = value
        case 16: uniforms.layerColors.16 = value
        case 17: uniforms.layerColors.17 = value
        case 18: uniforms.layerColors.18 = value
        case 19: uniforms.layerColors.19 = value
        case 20: uniforms.layerColors.20 = value
        case 21: uniforms.layerColors.21 = value
        case 22: uniforms.layerColors.22 = value
        case 23: uniforms.layerColors.23 = value
        case 24: uniforms.layerColors.24 = value
        case 25: uniforms.layerColors.25 = value
        case 26: uniforms.layerColors.26 = value
        case 27: uniforms.layerColors.27 = value
        case 28: uniforms.layerColors.28 = value
        case 29: uniforms.layerColors.29 = value
        case 30: uniforms.layerColors.30 = value
        case 31: uniforms.layerColors.31 = value
        case 32: uniforms.layerColors.32 = value
        case 33: uniforms.layerColors.33 = value
        case 34: uniforms.layerColors.34 = value
        case 35: uniforms.layerColors.35 = value
        case 36: uniforms.layerColors.36 = value
        case 37: uniforms.layerColors.37 = value
        case 38: uniforms.layerColors.38 = value
        case 39: uniforms.layerColors.39 = value
        case 40: uniforms.layerColors.40 = value
        case 41: uniforms.layerColors.41 = value
        case 42: uniforms.layerColors.42 = value
        case 43: uniforms.layerColors.43 = value
        case 44: uniforms.layerColors.44 = value
        case 45: uniforms.layerColors.45 = value
        case 46: uniforms.layerColors.46 = value
        case 47: uniforms.layerColors.47 = value
        case 48: uniforms.layerColors.48 = value
        case 49: uniforms.layerColors.49 = value
        case 50: uniforms.layerColors.50 = value
        case 51: uniforms.layerColors.51 = value
        case 52: uniforms.layerColors.52 = value
        case 53: uniforms.layerColors.53 = value
        case 54: uniforms.layerColors.54 = value
        case 55: uniforms.layerColors.55 = value
        case 56: uniforms.layerColors.56 = value
        case 57: uniforms.layerColors.57 = value
        case 58: uniforms.layerColors.58 = value
        case 59: uniforms.layerColors.59 = value
        case 60: uniforms.layerColors.60 = value
        case 61: uniforms.layerColors.61 = value
        case 62: uniforms.layerColors.62 = value
        case 63: uniforms.layerColors.63 = value
        case 64: uniforms.layerColors.64 = value
        case 65: uniforms.layerColors.65 = value
        case 66: uniforms.layerColors.66 = value
        case 67: uniforms.layerColors.67 = value
        case 68: uniforms.layerColors.68 = value
        case 69: uniforms.layerColors.69 = value
        case 70: uniforms.layerColors.70 = value
        case 71: uniforms.layerColors.71 = value
        case 72: uniforms.layerColors.72 = value
        case 73: uniforms.layerColors.73 = value
        case 74: uniforms.layerColors.74 = value
        case 75: uniforms.layerColors.75 = value
        case 76: uniforms.layerColors.76 = value
        case 77: uniforms.layerColors.77 = value
        case 78: uniforms.layerColors.78 = value
        case 79: uniforms.layerColors.79 = value
        default: break
        }
    }
}
