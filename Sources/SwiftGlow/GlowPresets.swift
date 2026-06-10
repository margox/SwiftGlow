import Foundation

public enum GlowPresets {
    public static let neonGreen: PresetConfig = .init(states: [
        GlowState(
            name: .default,
            preset: .css(
                textColor: "#39ff14",
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
                textColor: "#ffffff",
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

    public static let rainbow: PresetConfig = .init(states: [
        GlowState(
            name: .default,
            preset: .css(
                textColor: "#ffffff",
                cornerRadius: 30,
                outlineWidth: 4,
                borderColor: [
                    "rgba(238, 255, 0, 1)",
                    "rgba(79, 255, 0, 1)",
                    "rgba(46, 90, 255, 1)",
                    "rgba(254, 0, 255, 1)",
                    "rgba(231, 23, 23, 1)"
                ],
                backgroundColor: "rgba(10, 10, 10, 1)",
                animationSpeed: 1.2,
                borderSpeedMultiplier: 1,
                glowLayers: [
                    GlowLayerConfig(cssColors: ["rgba(205, 201, 35, 1)", "rgba(0, 255, 79, 1)", "rgba(0, 119, 255, 1)", "rgba(239, 0, 255, 1)", "rgba(222, 28, 28, 1)"], opacity: 0.2, glowSize: 34, speedMultiplier: 1, glowPlacement: .behind, coverage: 1, relativeOffset: 0),
                    GlowLayerConfig(cssColors: ["rgba(185, 182, 32, 1)", "rgba(0, 255, 79, 1)", "rgba(0, 119, 255, 1)", "rgba(239, 0, 255, 1)", "rgba(222, 28, 28, 1)"], opacity: 0.5, glowSize: 6, speedMultiplier: 1, glowPlacement: .behind, coverage: 1, relativeOffset: 0),
                    GlowLayerConfig(cssColors: ["#ffffff"], opacity: 0.2, glowSize: [2, 8, 8, 2], speedMultiplier: 2, glowPlacement: .behind, coverage: 0.5, relativeOffset: 0)
                ]
            )
        ),
        GlowState(
            name: .hover,
            preset: GlowConfig(
                animationSpeed: 1.8,
                glowLayers: [
                    GlowLayerConfig(opacity: 0.24, glowSize: [40]),
                    GlowLayerConfig(opacity: 0.6, glowSize: [7]),
                    GlowLayerConfig(opacity: 0.24, glowSize: [2, 10, 10, 2])
                ]
            ),
            transition: 0.3
        ),
        GlowState(
            name: .press,
            preset: GlowConfig(
                animationSpeed: 2.4,
                glowLayers: [
                    GlowLayerConfig(opacity: 0.28, glowSize: [40]),
                    GlowLayerConfig(opacity: 0.7, glowSize: [8]),
                    GlowLayerConfig(opacity: 0.28, glowSize: [3, 11, 11, 3])
                ]
            ),
            transition: 0.1
        )
    ])

    public static let alert: PresetConfig = .init(states: [
        GlowState(
            name: .default,
            preset: .css(
                textColor: "#ffffff",
                cornerRadius: 30,
                outlineWidth: 6,
                borderColor: ["rgba(255, 255, 255, 1)"],
                backgroundColor: "#222",
                animationSpeed: 5,
                borderSpeedMultiplier: 1,
                glowLayers: [
                    GlowLayerConfig(cssColors: ["#001cff", "rgba(179, 0, 255, 1)", "#ff0000", "#ff00b0"], opacity: 0.7, glowSize: 12, speedMultiplier: 1, glowPlacement: .behind, coverage: 1, relativeOffset: 0),
                    GlowLayerConfig(cssColors: ["#001cff", "rgba(179, 0, 255, 1)", "#ff0000", "#ff00b0"], opacity: 0.7, glowSize: 7, speedMultiplier: 1, glowPlacement: .behind, coverage: 1, relativeOffset: 0),
                    GlowLayerConfig(cssColors: ["rgba(0, 171, 255, 1)", "rgba(0, 190, 255, 1)", "#ff6f00"], opacity: 1, glowSize: 7, speedMultiplier: 1, glowPlacement: .behind, coverage: 1, relativeOffset: 0)
                ]
            )
        ),
        GlowState(
            name: .hover,
            preset: GlowConfig(
                animationSpeed: 7.5,
                glowLayers: [
                    GlowLayerConfig(opacity: 0.84, glowSize: [14]),
                    GlowLayerConfig(opacity: 0.84, glowSize: [8]),
                    GlowLayerConfig(opacity: 1, glowSize: [8])
                ]
            ),
            transition: 0.3
        ),
        GlowState(
            name: .press,
            preset: GlowConfig(
                animationSpeed: 10,
                glowLayers: [
                    GlowLayerConfig(opacity: 0.98, glowSize: [17]),
                    GlowLayerConfig(opacity: 0.98, glowSize: [10]),
                    GlowLayerConfig(opacity: 1, glowSize: [10])
                ]
            ),
            transition: 0.1
        )
    ])

    public static let vaporwave: PresetConfig = .init(states: [
        GlowState(
            name: .default,
            preset: .css(
                textColor: "#ffffff",
                cornerRadius: 10,
                outlineWidth: 0,
                borderColor: ["white"],
                backgroundColor: "rgba(0, 0, 0, 1)",
                animationSpeed: 2,
                borderSpeedMultiplier: 1,
                glowLayers: [
                    GlowLayerConfig(cssColors: ["rgba(255, 75, 169, 1)", "#01CDFE", "#05ffd2", "rgba(0, 0, 0, 0)", "rgba(0, 0, 0, 0)"], opacity: 0.5, glowSize: 5, speedMultiplier: 1, glowPlacement: .behind, coverage: 1, relativeOffset: 0),
                    GlowLayerConfig(cssColors: ["rgba(255, 76, 156, 1)", "#01CDFE", "#05ffd2", "rgba(0, 0, 0, 0)", "rgba(0, 0, 0, 0)"], opacity: 0.5, glowSize: 10, speedMultiplier: 1, glowPlacement: .behind, coverage: 1, relativeOffset: 0),
                    GlowLayerConfig(cssColors: ["#66d3ff", "#ff67ef"], opacity: 0.9, glowSize: 4, speedMultiplier: 0.8, glowPlacement: .behind, coverage: 1, relativeOffset: 0)
                ]
            )
        ),
        GlowState(
            name: .hover,
            preset: GlowConfig(
                animationSpeed: 3,
                glowLayers: [
                    GlowLayerConfig(opacity: 0.6, glowSize: [6]),
                    GlowLayerConfig(opacity: 0.6, glowSize: [12]),
                    GlowLayerConfig(opacity: 1, glowSize: [5])
                ]
            ),
            transition: 0.3
        ),
        GlowState(
            name: .press,
            preset: GlowConfig(
                animationSpeed: 4,
                glowLayers: [
                    GlowLayerConfig(opacity: 0.7, glowSize: [7]),
                    GlowLayerConfig(opacity: 0.7, glowSize: [14]),
                    GlowLayerConfig(opacity: 1, glowSize: [6])
                ]
            ),
            transition: 0.1
        )
    ])

    public static let glimmer: PresetConfig = .init(states: [
        GlowState(
            name: .default,
            preset: .css(
                textColor: "#ffffff",
                cornerRadius: 90,
                outlineWidth: 0,
                borderColor: ["rgba(0, 0, 0, 1)"],
                backgroundColor: "rgba(10, 10, 10, 1)",
                animationSpeed: 1,
                borderSpeedMultiplier: 1,
                glowLayers: [
                    GlowLayerConfig(cssColors: ["rgba(145, 46, 166, 1)", "#5a4ff9"], opacity: 0.1, glowSize: [30, 40, 30], speedMultiplier: 1, glowPlacement: .behind, coverage: 1, relativeOffset: 0),
                    GlowLayerConfig(cssColors: ["rgba(190, 84, 245, 1)", "rgba(88, 47, 236, 1)"], opacity: 0.5, glowSize: 1, speedMultiplier: 1, glowPlacement: .behind, coverage: 1, relativeOffset: 0),
                    GlowLayerConfig(cssColors: ["rgba(194, 106, 255, 1)", "rgba(226, 114, 255, 1)"], opacity: 0.05, glowSize: [0, 30], speedMultiplier: 2, glowPlacement: .over, coverage: 0.6, relativeOffset: 0),
                    GlowLayerConfig(cssColors: ["rgba(0, 0, 0, 1)", "rgba(255, 118, 118, 1)"], opacity: 1, glowSize: [0, 1], speedMultiplier: 2, glowPlacement: .behind, coverage: 0.5, relativeOffset: 0)
                ]
            )
        ),
        GlowState(
            name: .hover,
            preset: GlowConfig(
                animationSpeed: 1.5,
                glowLayers: [
                    GlowLayerConfig(opacity: 0.12, glowSize: [36, 40, 36]),
                    GlowLayerConfig(opacity: 0.6, glowSize: [1]),
                    GlowLayerConfig(opacity: 0.06, glowSize: [0, 36]),
                    GlowLayerConfig(opacity: 1, glowSize: [0, 1])
                ]
            ),
            transition: 0.3
        ),
        GlowState(
            name: .press,
            preset: GlowConfig(
                animationSpeed: 2,
                glowLayers: [
                    GlowLayerConfig(opacity: 0.14, glowSize: [40, 40, 40]),
                    GlowLayerConfig(opacity: 0.7, glowSize: [1]),
                    GlowLayerConfig(opacity: 0.07, glowSize: [0, 40]),
                    GlowLayerConfig(opacity: 1, glowSize: [0, 1])
                ]
            ),
            transition: 0.1
        )
    ])
}
