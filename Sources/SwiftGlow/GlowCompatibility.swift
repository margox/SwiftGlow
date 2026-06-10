import Foundation

public enum GlowCompatibility {
    public static let maximumLayerCount = 10
    public static let sampledColorCount = 8
    public static let speedFactor: Float = 0.166

    public static func merge(_ target: GlowConfig, with source: GlowConfig) -> GlowConfig {
        var output = target
        if let textColor = source.textColor { output.textColor = textColor }
        if let cornerRadius = source.cornerRadius { output.cornerRadius = cornerRadius }
        if let outlineWidth = source.outlineWidth { output.outlineWidth = outlineWidth }
        if let borderColor = source.borderColor { output.borderColor = borderColor }
        if let backgroundColor = source.backgroundColor { output.backgroundColor = backgroundColor }
        if let animationSpeed = source.animationSpeed { output.animationSpeed = animationSpeed }
        if let borderSpeedMultiplier = source.borderSpeedMultiplier { output.borderSpeedMultiplier = borderSpeedMultiplier }
        if let layers = source.glowLayers {
            output.glowLayers = mergeLayers(output.glowLayers ?? [], with: layers)
        }
        return output
    }

    public static func resolvedConfig(
        preset: GlowConfig = GlowConfig(),
        states: [GlowState],
        override: GlowConfig = GlowConfig(),
        activeState: GlowEvent
    ) -> GlowConfig {
        let defaultState = states.first { $0.name == .default }?.preset ?? GlowConfig()
        let baseConfig = merge(defaultState, with: preset)
        let overriddenBase = merge(baseConfig, with: override)
        let stateOverride = states.first { $0.name == activeState }?.preset ?? GlowConfig()
        return merge(overriddenBase, with: stateOverride)
    }

    public static func transitionDuration(
        states: [GlowState],
        activeState: GlowEvent,
        previousState: GlowEvent
    ) -> TimeInterval {
        if activeState == .default, previousState != .default {
            return states.first { $0.name == previousState }?.transition ?? 0
        }
        return states.first { $0.name == activeState }?.transition ?? 0
    }

    public static func glowSizeVector(_ glowSize: [Float]?) -> SIMD4<Float> {
        let values = glowSize ?? []
        if values.isEmpty {
            return SIMD4(0, 0, 0, 0)
        }
        if values.count == 1 {
            return SIMD4(values[0], values[0], values[0], values[0])
        }
        if values.count == 2 {
            return SIMD4(values[0], values[1], values[1], values[0])
        }
        if values.count == 3 {
            return SIMD4(values[0], values[1], values[2], values[2])
        }
        return SIMD4(values[0], values[1], values[2], values[3])
    }

    public static func interpolate(_ from: GlowConfig, _ to: GlowConfig, progress: Float) -> GlowConfig {
        let p = max(0, min(1, progress))
        return GlowConfig(
            textColor: interpolate(from.textColor, to.textColor, progress: p),
            cornerRadius: interpolate(from.cornerRadius, to.cornerRadius, progress: p),
            outlineWidth: interpolate(from.outlineWidth, to.outlineWidth, progress: p),
            borderColor: interpolateColorArrays(from.borderColor, to.borderColor, progress: p),
            backgroundColor: interpolate(from.backgroundColor, to.backgroundColor, progress: p),
            animationSpeed: interpolate(from.animationSpeed, to.animationSpeed, progress: p),
            borderSpeedMultiplier: interpolate(from.borderSpeedMultiplier, to.borderSpeedMultiplier, progress: p),
            glowLayers: interpolateLayers(from.glowLayers ?? [], to.glowLayers ?? [], progress: p)
        )
    }

    public static func sampleSeamlessColors(_ colors: [GlowColor]) -> [GlowColor] {
        guard !colors.isEmpty else {
            return Array(repeating: .clear, count: sampledColorCount)
        }

        let seamless = colors.count > 1 ? colors + [colors[0]] : colors + colors
        return (0..<sampledColorCount).map { index in
            let progress = Float(index) / Float(sampledColorCount - 1)
            return gradientColor(progress: progress, colors: seamless)
        }
    }

    private static func mergeLayers(_ target: [GlowLayerConfig], with source: [GlowLayerConfig]) -> [GlowLayerConfig] {
        var output = target
        for index in source.indices {
            if output.indices.contains(index) {
                output[index] = mergeLayer(output[index], with: source[index])
            } else {
                output.append(source[index])
            }
        }
        return output
    }

    private static func mergeLayer(_ target: GlowLayerConfig, with source: GlowLayerConfig) -> GlowLayerConfig {
        GlowLayerConfig(
            colors: source.colors ?? target.colors,
            opacity: source.opacity ?? target.opacity,
            glowSize: source.glowSize ?? target.glowSize,
            speedMultiplier: source.speedMultiplier ?? target.speedMultiplier,
            glowPlacement: source.glowPlacement ?? target.glowPlacement,
            coverage: source.coverage ?? target.coverage,
            relativeOffset: source.relativeOffset ?? target.relativeOffset
        )
    }

    private static func interpolate(_ from: Float?, _ to: Float?, progress: Float) -> Float? {
        guard let to else {
            return from
        }
        let fromValue = from ?? to
        return fromValue + (to - fromValue) * progress
    }

    private static func interpolate(_ from: GlowColor?, _ to: GlowColor?, progress: Float) -> GlowColor? {
        guard let to else {
            return from
        }
        let fromValue = from ?? to
        return GlowColor(
            red: fromValue.red + (to.red - fromValue.red) * progress,
            green: fromValue.green + (to.green - fromValue.green) * progress,
            blue: fromValue.blue + (to.blue - fromValue.blue) * progress,
            alpha: fromValue.alpha + (to.alpha - fromValue.alpha) * progress
        )
    }

    private static func interpolateLayers(_ from: [GlowLayerConfig], _ to: [GlowLayerConfig], progress: Float) -> [GlowLayerConfig] {
        let count = min(max(from.count, to.count), maximumLayerCount)
        return (0..<count).map { index in
            let fromLayer = from.indices.contains(index) ? from[index] : GlowLayerConfig()
            let toLayer = to.indices.contains(index) ? to[index] : GlowLayerConfig()
            let targetOpacity: Float = toLayer.opacity ?? 0.5
            let targetSpeedMultiplier: Float = toLayer.speedMultiplier ?? 1
            let targetCoverage: Float = toLayer.coverage ?? 1
            let targetRelativeOffset: Float = toLayer.relativeOffset ?? 0
            return GlowLayerConfig(
                colors: interpolateColorArrays(fromLayer.colors, toLayer.colors, progress: progress),
                opacity: interpolateRequired(fromLayer.opacity, targetOpacity, progress: progress),
                glowSize: interpolateNumberArrays(fromLayer.glowSize, toLayer.glowSize, progress: progress),
                speedMultiplier: interpolateRequired(fromLayer.speedMultiplier, targetSpeedMultiplier, progress: progress),
                glowPlacement: toLayer.glowPlacement ?? fromLayer.glowPlacement ?? .behind,
                coverage: interpolateRequired(fromLayer.coverage, targetCoverage, progress: progress),
                relativeOffset: interpolateRequired(fromLayer.relativeOffset, targetRelativeOffset, progress: progress)
            )
        }
    }

    private static func interpolateColorArrays(_ from: [GlowColor]?, _ to: [GlowColor]?, progress: Float) -> [GlowColor]? {
        guard let to, !to.isEmpty else {
            return from
        }
        guard let from, !from.isEmpty else {
            return to
        }

        let count = max(from.count, to.count)
        return (0..<count).map { index in
            let fromColor = from[min(index, from.count - 1)]
            let toColor = to[min(index, to.count - 1)]
            return interpolate(fromColor, toColor, progress: progress) ?? toColor
        }
    }

    private static func interpolateNumberArrays(_ from: [Float]?, _ to: [Float]?, progress: Float) -> [Float]? {
        guard let to, !to.isEmpty else {
            return from
        }
        guard let from, !from.isEmpty else {
            return to.map { $0 * progress }
        }

        let count = max(from.count, to.count)
        return (0..<count).map { index in
            let fromValue = from[min(index, from.count - 1)]
            let toValue = to[min(index, to.count - 1)]
            return fromValue + (toValue - fromValue) * progress
        }
    }

    private static func gradientColor(progress: Float, colors: [GlowColor]) -> GlowColor {
        guard !colors.isEmpty else {
            return .clear
        }
        guard colors.count > 1 else {
            return colors[0]
        }

        let segmentLength = Float(1) / Float(colors.count - 1)
        let rawIndex = Int(floor(progress / segmentLength))
        let index = min(rawIndex, colors.count - 2)
        let segmentProgress = (progress - Float(index) * segmentLength) / segmentLength
        return interpolate(colors[index], colors[index + 1], progress: segmentProgress) ?? colors[index]
    }

    private static func interpolateRequired(_ from: Float?, _ to: Float, progress: Float) -> Float {
        let fromValue = from ?? to
        return fromValue + (to - fromValue) * progress
    }
}
