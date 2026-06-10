import simd

struct GlowLayerUniform {
    var coverage: Float = 0
    var opacity: Float = 0
    var relativeOffset: Float = 0
    var placement: Float = 0
    var progress: Float = 0
    var glowSize: SIMD4<Float> = .zero
}

struct GlowUniforms {
    var resolution: SIMD2<Float> = .zero
    var rectSize: SIMD2<Float> = .zero
    var cornerRadius: Float = 10
    var borderWidth: Float = 2
    var borderProgress: Float = 0
    var layerCount: UInt32 = 0
    var masterOpacity: Float = 1
    var isBorderAnimated: Float = 0
    var backgroundColor: SIMD4<Float> = .zero
    var layers: (
        GlowLayerUniform, GlowLayerUniform, GlowLayerUniform, GlowLayerUniform, GlowLayerUniform,
        GlowLayerUniform, GlowLayerUniform, GlowLayerUniform, GlowLayerUniform, GlowLayerUniform
    ) = (
        GlowLayerUniform(), GlowLayerUniform(), GlowLayerUniform(), GlowLayerUniform(), GlowLayerUniform(),
        GlowLayerUniform(), GlowLayerUniform(), GlowLayerUniform(), GlowLayerUniform(), GlowLayerUniform()
    )
    var borderColors: (
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>
    ) = (
        .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero
    )
    var layerColors: (
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>
    ) = (
        .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
        .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
        .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
        .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
        .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
        .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
        .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
        .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
        .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
        .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero
    )
}

extension GlowColor {
    var simd: SIMD4<Float> {
        SIMD4(red, green, blue, alpha)
    }
}
