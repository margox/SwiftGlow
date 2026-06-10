import Foundation

public enum GlowPresets {
    public static let neonGreen: PresetConfig = .init(states: [
        GlowState(
            name: .default,
            preset: .css(
                cornerRadius: 50,
                outlineWidth: 4,
                borderColor: ["#bfff3b", "#39ff14", "#fff35a"],
                backgroundColor: "#1a1a1a",
                animationSpeed: 3,
                borderSpeedMultiplier: 1,
                glowLayers: [
                    GlowLayerConfig(cssColors: ["#4cff8d", "#e2ff3f", "#39ff14"], opacity: 0.2, glowSize: [10, 20, 10], speedMultiplier: 1, glowPlacement: .behind, coverage: 1),
                    GlowLayerConfig(cssColors: ["#4cff8d", "#e2ff3f", "#39ff14"], opacity: 0.3, glowSize: [1, 8, 1], speedMultiplier: 1, glowPlacement: .behind, coverage: 1),
                    GlowLayerConfig(cssColors: ["#7fff24", "#f4ff43", "#39ff14"], opacity: 0.3, glowSize: [1, 8, 1], speedMultiplier: 1, glowPlacement: .behind, coverage: 0.75),
                    GlowLayerConfig(cssColors: ["#39ff14", "#4cff8d", "#7dff9a"], opacity: 0.5, glowSize: [2, 8, 2], speedMultiplier: 1, glowPlacement: .behind, coverage: 1)
                ]
            )
        )
    ])

    public static let appleIntelligence: PresetConfig = .init(states: [
        GlowState(
            name: .default,
            preset: .css(
                cornerRadius: 50,
                outlineWidth: 0,
                borderColor: ["#ffffff"],
                backgroundColor: "#000000",
                animationSpeed: 1,
                borderSpeedMultiplier: 1,
                glowLayers: [
                    GlowLayerConfig(cssColors: ["#322dff", "#d12d8d", "#ff2121", "#ff9f2f"], opacity: 0.3, glowSize: [24], speedMultiplier: 1, glowPlacement: .inside, coverage: 1),
                    GlowLayerConfig(cssColors: ["#6a3cff", "#6d18ce", "#ff2929", "#ffb13f"], opacity: 0.5, glowSize: [6], speedMultiplier: 1, glowPlacement: .inside, coverage: 1),
                    GlowLayerConfig(cssColors: ["#f3e8ff", "#ff63cb", "#ff447d", "#ffd498"], opacity: 1, glowSize: [1], speedMultiplier: 1, glowPlacement: .inside, coverage: 1),
                    GlowLayerConfig(cssColors: ["#6f7cff", "#c8e1ff"], opacity: 0.2, glowSize: [0, 4, 4, 0], speedMultiplier: 2, glowPlacement: .inside, coverage: 0.4),
                    GlowLayerConfig(cssColors: ["#ffffff"], opacity: 0.2, glowSize: [0, 2, 0], speedMultiplier: 2, glowPlacement: .inside, coverage: 0.4)
                ]
            )
        )
    ])
}
