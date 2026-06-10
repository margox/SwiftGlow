import XCTest
@testable import SwiftGlow

final class GlowCompatibilityTests: XCTestCase {
    func testGlowSizeVectorMatchesReactNativeExpansion() {
        XCTAssertEqual(GlowCompatibility.glowSizeVector([]), SIMD4(0, 0, 0, 0))
        XCTAssertEqual(GlowCompatibility.glowSizeVector([10]), SIMD4(10, 10, 10, 10))
        XCTAssertEqual(GlowCompatibility.glowSizeVector([10, 20]), SIMD4(10, 20, 20, 10))
        XCTAssertEqual(GlowCompatibility.glowSizeVector([10, 20, 30]), SIMD4(10, 20, 30, 30))
        XCTAssertEqual(GlowCompatibility.glowSizeVector([10, 20, 30, 40]), SIMD4(10, 20, 30, 40))
    }

    func testColorParsingMatchesSupportedReactNativeInputs() {
        XCTAssertEqual(GlowColor(css: "#0f0"), GlowColor(red255: 0, green255: 255, blue255: 0))
        XCTAssertEqual(GlowColor(css: "#00ff0080"), GlowColor(red255: 0, green255: 255, blue255: 0, alpha: Float(0x80) / 255))
        XCTAssertEqual(GlowColor(css: "rgba(255, 89, 213, 0.5)"), GlowColor(red255: 255, green255: 89, blue255: 213, alpha: 0.5))
        XCTAssertEqual(GlowColor(css: "transparent"), .clear)
    }

    func testLayerMergeIsIndexBased() {
        let base = GlowConfig(glowLayers: [
            GlowLayerConfig(opacity: 0.2, glowSize: [10]),
            GlowLayerConfig(opacity: 0.3, glowSize: [8])
        ])
        let override = GlowConfig(glowLayers: [
            GlowLayerConfig(opacity: 1),
            GlowLayerConfig(glowSize: [4, 8, 4])
        ])

        let merged = GlowCompatibility.merge(base, with: override)
        XCTAssertEqual(merged.glowLayers?[0].opacity, 1)
        XCTAssertEqual(merged.glowLayers?[0].glowSize, [10])
        XCTAssertEqual(merged.glowLayers?[1].opacity, 0.3)
        XCTAssertEqual(merged.glowLayers?[1].glowSize, [4, 8, 4])
    }

    func testDefaultStatePresetOverrideAndActiveStateOrder() {
        let states = [
            GlowState(name: .default, preset: GlowConfig(cornerRadius: 10, animationSpeed: 1)),
            GlowState(name: .press, preset: GlowConfig(animationSpeed: 4))
        ]

        let resolved = GlowCompatibility.resolvedConfig(
            preset: GlowConfig(cornerRadius: 20),
            states: states,
            override: GlowConfig(outlineWidth: 3),
            activeState: .press
        )

        XCTAssertEqual(resolved.cornerRadius, 20)
        XCTAssertEqual(resolved.outlineWidth, 3)
        XCTAssertEqual(resolved.animationSpeed, 4)
    }
}
