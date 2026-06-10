import Foundation

public enum GlowPlacement: String, Codable, Sendable {
    case inside
    case over
    case behind

    var shaderValue: Float {
        switch self {
        case .behind:
            return 0
        case .inside:
            return 1
        case .over:
            return 2
        }
    }
}

public enum GlowEvent: String, Codable, Sendable {
    case `default`
    case hover
    case press
}

public struct GlowLayerConfig: Equatable, Sendable {
    public var colors: [GlowColor]?
    public var opacity: Float?
    public var glowSize: [Float]?
    public var speedMultiplier: Float?
    public var glowPlacement: GlowPlacement?
    public var coverage: Float?
    public var relativeOffset: Float?

    public init(
        colors: [GlowColor]? = nil,
        opacity: Float? = nil,
        glowSize: [Float]? = nil,
        speedMultiplier: Float? = nil,
        glowPlacement: GlowPlacement? = nil,
        coverage: Float? = nil,
        relativeOffset: Float? = nil
    ) {
        self.colors = colors
        self.opacity = opacity
        self.glowSize = glowSize
        self.speedMultiplier = speedMultiplier
        self.glowPlacement = glowPlacement
        self.coverage = coverage
        self.relativeOffset = relativeOffset
    }

    public init(
        cssColors: [String],
        opacity: Float,
        glowSize: Float,
        speedMultiplier: Float,
        glowPlacement: GlowPlacement,
        coverage: Float,
        relativeOffset: Float? = nil
    ) {
        self.init(
            colors: cssColors.map(GlowColor.init(css:)),
            opacity: opacity,
            glowSize: [glowSize],
            speedMultiplier: speedMultiplier,
            glowPlacement: glowPlacement,
            coverage: coverage,
            relativeOffset: relativeOffset
        )
    }

    public init(
        cssColors: [String],
        opacity: Float,
        glowSize: [Float],
        speedMultiplier: Float,
        glowPlacement: GlowPlacement,
        coverage: Float,
        relativeOffset: Float? = nil
    ) {
        self.init(
            colors: cssColors.map(GlowColor.init(css:)),
            opacity: opacity,
            glowSize: glowSize,
            speedMultiplier: speedMultiplier,
            glowPlacement: glowPlacement,
            coverage: coverage,
            relativeOffset: relativeOffset
        )
    }
}

public struct GlowConfig: Equatable, Sendable {
    public var textColor: GlowColor?
    public var cornerRadius: Float?
    public var outlineWidth: Float?
    public var borderColor: [GlowColor]?
    public var backgroundColor: GlowColor?
    public var animationSpeed: Float?
    public var borderSpeedMultiplier: Float?
    public var glowLayers: [GlowLayerConfig]?

    public init(
        textColor: GlowColor? = nil,
        cornerRadius: Float? = nil,
        outlineWidth: Float? = nil,
        borderColor: [GlowColor]? = nil,
        backgroundColor: GlowColor? = nil,
        animationSpeed: Float? = nil,
        borderSpeedMultiplier: Float? = nil,
        glowLayers: [GlowLayerConfig]? = nil
    ) {
        self.textColor = textColor
        self.cornerRadius = cornerRadius
        self.outlineWidth = outlineWidth
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.animationSpeed = animationSpeed
        self.borderSpeedMultiplier = borderSpeedMultiplier
        self.glowLayers = glowLayers
    }

    public static func css(
        textColor: String? = nil,
        cornerRadius: Float? = nil,
        outlineWidth: Float? = nil,
        borderColor: [String]? = nil,
        backgroundColor: String? = nil,
        animationSpeed: Float? = nil,
        borderSpeedMultiplier: Float? = nil,
        glowLayers: [GlowLayerConfig]? = nil
    ) -> GlowConfig {
        GlowConfig(
            textColor: textColor.map(GlowColor.init(css:)),
            cornerRadius: cornerRadius,
            outlineWidth: outlineWidth,
            borderColor: borderColor?.map(GlowColor.init(css:)),
            backgroundColor: backgroundColor.map(GlowColor.init(css:)),
            animationSpeed: animationSpeed,
            borderSpeedMultiplier: borderSpeedMultiplier,
            glowLayers: glowLayers
        )
    }
}

public struct GlowState: Equatable, Sendable {
    public var name: GlowEvent
    public var preset: GlowConfig
    public var transition: TimeInterval?

    public init(name: GlowEvent, preset: GlowConfig, transition: TimeInterval? = nil) {
        self.name = name
        self.preset = preset
        self.transition = transition
    }
}

public struct PresetConfig: Equatable, Sendable {
    public var states: [GlowState]

    public init(states: [GlowState]) {
        self.states = states
    }
}
