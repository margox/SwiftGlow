# SwiftGlow

`SwiftGlow` is a Swift Package for building animated glow borders and neon capsule effects with SwiftUI + Metal.

It is designed to closely mirror the configuration model of [`react-native-animated-glow`](https://github.com/realimposter/react-native-animated-glow), so presets and tuning workflows can be shared across React Native and Apple-platform projects with minimal translation.

## Highlights

- Metal-based renderer for high-performance per-pixel glow animation
- SwiftUI-first API with a simple `.animatedGlow(...)` modifier
- Config model compatible with the core shape of `react-native-animated-glow`
- Supports `default`, `hover`, and `press` state definitions
- Supports multi-layer glow composition
- Supports `behind`, `inside`, and `over` glow placement
- Includes a macOS demo app with a live parameter inspector
- Includes a one-click React Native glow JSON import workflow in the demo

## Why Metal

This effect is fundamentally a fragment-shader problem:

- rounded-rect distance fields
- animated perimeter progress
- layered color gradients
- gaussian glow falloff

Metal is the right base for that workload. It keeps CPU overhead low, gives direct control over blending and timing, and scales better than stacking multiple blur/mask/material layers in SwiftUI or Core Animation.

## Platforms

- iOS 15+
- macOS 12+
- tvOS 15+

## Installation

### Swift Package Manager

Add this package in Xcode or `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/SwiftGlow.git", from: "0.1.0")
]
```

Then add the product to your target:

```swift
dependencies: [
    .product(name: "SwiftGlow", package: "SwiftGlow")
]
```

## Quick Start

```swift
import SwiftUI
import SwiftGlow

struct DemoView: View {
    var body: some View {
        Text("Apple Intelligence")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 52)
            .padding(.vertical, 22)
            .animatedGlow(
                states: GlowPresets.appleIntelligence.states,
                activeState: .default
            )
            .padding(40)
            .background(.black)
    }
}
```

## Configuring a Glow

The package mirrors the React Native library's configuration style.

```swift
import SwiftGlow

let states = [
    GlowState(
        name: .default,
        preset: .css(
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
                GlowLayerConfig(
                    cssColors: [
                        "rgba(205, 201, 35, 1)",
                        "rgba(0, 255, 79, 1)",
                        "rgba(0, 119, 255, 1)",
                        "rgba(239, 0, 255, 1)",
                        "rgba(222, 28, 28, 1)"
                    ],
                    opacity: 0.2,
                    glowSize: [34],
                    speedMultiplier: 1,
                    glowPlacement: .behind,
                    coverage: 1,
                    relativeOffset: 0
                ),
                GlowLayerConfig(
                    cssColors: ["#FFFFFF"],
                    opacity: 0.2,
                    glowSize: [2, 8, 8, 2],
                    speedMultiplier: 2,
                    glowPlacement: .behind,
                    coverage: 0.5,
                    relativeOffset: 0
                )
            ]
        )
    ),
    GlowState(
        name: .hover,
        preset: .css(animationSpeed: 1.8),
        transition: 0.3
    ),
    GlowState(
        name: .press,
        preset: .css(animationSpeed: 2.4),
        transition: 0.1
    )
]
```

Apply it:

```swift
Text("Default Rainbow")
    .padding(.horizontal, 36)
    .padding(.vertical, 18)
    .foregroundStyle(.white)
    .animatedGlow(states: states, activeState: .default)
```

## Available Types

Core public types:

- `GlowColor`
- `GlowPlacement`
- `GlowEvent`
- `GlowLayerConfig`
- `GlowConfig`
- `GlowState`
- `PresetConfig`
- `GlowPresets`
- `AnimatedGlow`

## React Native Compatibility

`SwiftGlow` is intentionally built around the same mental model as `react-native-animated-glow`.

Implemented compatibility rules:

- `glowPlacement`: `behind | inside | over`
- `glowLayers` are merged by array index
- `default / hover / press` state structure is supported
- CSS-style colors such as `#fff`, `#ffffff`, `#ffffffff`, `rgb(...)`, and `rgba(...)` are supported
- seamless gradient sampling loops back to the first color

`glowSize` expansion matches the React Native package:

- `[a] -> [a, a, a, a]`
- `[a, b] -> [a, b, b, a]`
- `[a, b, c] -> [a, b, c, c]`
- `[a, b, c, d] -> [a, b, c, d]`

## Presets

Built-in presets currently include:

- `GlowPresets.appleIntelligence`
- `GlowPresets.neonGreen`

These are useful as references for creating your own effects and for validating rendering behavior.

## macOS Demo

The repository includes a macOS demo app with a live parameter editor.

Run it with:

```sh
swift run SwiftGlowDemo
```

Demo features:

- switch between built-in presets
- edit general glow parameters live
- add, duplicate, and remove glow layers
- edit per-layer placement, colors, sizes, coverage, speed, and offset
- switch preview state between `default`, `hover`, and `press`
- import JSON presets from `react-native-animated-glow`

### Importing React Native JSON

The demo includes an `Import RN JSON` action. Paste a preset JSON document in the same shape as the React Native package:

```json
{
  "metadata": {
    "name": "Default Rainbow",
    "textColor": "#FFFFFF"
  },
  "states": [
    {
      "name": "default",
      "preset": {
        "cornerRadius": 30,
        "outlineWidth": 4,
        "borderColor": ["#ff0", "#0f0", "#00f"],
        "backgroundColor": "rgba(10, 10, 10, 1)",
        "animationSpeed": 1.2,
        "borderSpeedMultiplier": 1,
        "glowLayers": [
          {
            "glowPlacement": "behind",
            "colors": ["#ff0", "#0f0", "#00f"],
            "glowSize": 34,
            "opacity": 0.2,
            "speedMultiplier": 1,
            "coverage": 1,
            "relativeOffset": 0
          }
        ]
      }
    }
  ]
}
```

The importer supports:

- `metadata.name`
- `metadata.textColor`
- `states.default / hover / press`
- `transition` in React Native milliseconds
- `borderColor` as a single string or array
- `glowSize` as a single number or array

## Current Status

What is solid today:

- package builds cleanly with SwiftPM
- unit tests cover compatibility helpers
- Metal shader rendering is wired and running
- demo import/edit workflow is in place

Current limitations:

- state transition timing is parsed and stored, but the SwiftUI wrapper does not yet animate interpolation between states the same way the React Native implementation does
- visual parity is close, but not yet validated by automated snapshot comparison against the React Native reference on multiple devices
- UIKit/AppKit-first wrappers are not exposed as public APIs yet; the primary experience is SwiftUI

## Development

Build:

```sh
swift build
```

Run tests:

```sh
swift test
```

Run the demo:

```sh
swift run SwiftGlowDemo
```

## Project Structure

```text
Sources/
  SwiftGlow/
    AnimatedGlow.swift
    GlowColor.swift
    GlowCompatibility.swift
    GlowConfiguration.swift
    GlowPresets.swift
    GlowRenderer.swift
    GlowUniforms.swift
    MetalGlowView.swift
    Resources/GlowShaders.metal
  SwiftGlowDemo/
    SwiftGlowDemoApp.swift
Tests/
  SwiftGlowTests/
```

## Roadmap

- animated interpolation between `default`, `hover`, and `press`
- public preset import/export helpers outside the demo app
- snapshot-based visual regression tests
- more built-in presets
- performance tuning for large numbers of simultaneous glow views

## Attribution

SwiftGlow is inspired by [`realimposter/react-native-animated-glow`](https://github.com/realimposter/react-native-animated-glow). The package aims to bring a similar configuration model and animated glow aesthetic to SwiftUI and Metal.

## License

MIT. See [LICENSE](LICENSE).
