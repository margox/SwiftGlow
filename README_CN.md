# SwiftGlow

`SwiftGlow` 是一个 Swift Package，用于在 SwiftUI + Metal 中构建动态发光边框和霓虹胶囊效果。

它尽量对齐 [`react-native-animated-glow`](https://github.com/realimposter/react-native-animated-glow) 的配置模型，这样 React Native 与 Apple 平台项目之间可以更直接地共享预设和调参方式。

## 特性

- 基于 Metal 的逐像素发光渲染，适合高性能动态效果
- 以 SwiftUI 为先，核心入口是 `.animatedGlow(...)`
- 配置模型兼容 `react-native-animated-glow` 的主体结构
- 支持 `default`、`hover`、`press` 三种状态
- 支持多层 glow 叠加
- 支持 `behind`、`inside`、`over` 三种发光位置
- 包含一个带实时参数面板的 macOS demo
- 包含一键导入 React Native glow JSON 的 demo 工作流

## 为什么用 Metal

这个效果本质上是一个 fragment shader 问题：

- 圆角矩形距离场
- 边框周长动画进度
- 多层渐变颜色采样
- 高斯型发光衰减

Metal 很适合这个负载。它能降低 CPU 开销，直接控制混合和时间推进，也比在 SwiftUI 或 Core Animation 中堆叠多层 blur、mask、material 更容易扩展。

## 平台支持

- iOS 15+
- macOS 12+
- tvOS 15+

## 安装

### Swift Package Manager

在 Xcode 或 `Package.swift` 中加入依赖：

```swift
dependencies: [
    .package(url: "https://github.com/margox/SwiftGlow.git", from: "0.1.0")
]
```

然后把产品加到目标 target：

```swift
dependencies: [
    .product(name: "SwiftGlow", package: "SwiftGlow")
]
```

## 快速开始

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
                status: .default
            )
            .padding(40)
            .background(.black)
    }
}
```

## Glow 配置示例

这个包的配置风格尽量贴近 React Native 版本。

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

应用方式：

```swift
Text("Default Rainbow")
    .padding(.horizontal, 36)
    .padding(.vertical, 18)
    .foregroundStyle(.white)
    .animatedGlow(states: states, status: .default)
```

## API 参考

### 视图修饰器

```swift
func animatedGlow(
    preset: GlowConfig = GlowConfig(),
    states: [GlowState],
    viewOverride: GlowConfig = GlowConfig(),
    status: GlowStatus,
    isVisible: Bool = true
) -> some View
```

参数说明：

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `preset` | `GlowConfig` | 在 `.default` 状态之后应用的基础配置，适合放共享默认值。 |
| `states` | `[GlowState]` | 状态变体集合。实际使用时通常至少应提供一个 `.default` 状态，必要时再补 `.hover` / `.press`。 |
| `viewOverride` | `GlowConfig` | 单个视图级别的覆盖配置，应用顺序在 `preset` 之后、选中状态之前。 |
| `status` | `GlowStatus` | 状态选择。可直接用 `.default`、`.hover`、`.press` 显式指定，也可以用 `.auto` 在 `.default` 和 `.press` 之间自动切换。 |
| `isVisible` | `Bool` | 控制 glow 的 Metal 渲染是否启用。 |

按钮这类可交互控件可以这样写：

```swift
Button("Buy") {
    purchase()
}
.buttonStyle(.plain)
.animatedGlow(
    states: GlowPresets.neonGreen.states,
    status: .auto
)
```

`status: .auto` 会在空闲时解析为 `.default`，按下时解析为 `.press`。它不会自动使用 `.hover`。

为了兼容旧用法，`activeState:` 这一套入口还保留着，但公开 API 现在优先推荐 `status:`。

配置合并顺序：

1. `.default` 状态的 `preset`
2. `preset`
3. `viewOverride`
4. 当前选中状态对应的 `preset`

这个顺序由 `GlowCompatibility.resolvedConfig(...)` 实现。标量字段在后者有值时覆盖前者，`glowLayers` 则按数组下标逐层合并，而不是整体替换。

### GlowConfig

`GlowConfig` 用来描述一个最终状态下的边框、背景和 glow layer。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `textColor` | `GlowColor?` | 兼容性和元数据字段。它会存储在模型里，但 `.animatedGlow(...)` 不会自动把它应用到 SwiftUI 文本上。文本颜色仍需你自己设置 `.foregroundStyle(...)` 或 `.foregroundColor(...)`。 |
| `cornerRadius` | `Float?` | 圆角矩形半径，单位是 points。未提供时渲染阶段默认是 `10`。 |
| `outlineWidth` | `Float?` | 动态边框宽度，单位是 points。未提供时渲染阶段默认是 `2`。 |
| `borderColor` | `[GlowColor]?` | 边框渐变颜色数组。多个颜色会沿周长做动画。 |
| `backgroundColor` | `GlowColor?` | 圆角矩形内部的填充色。默认透明。 |
| `animationSpeed` | `Float?` | 全局动画速度系数。未提供时默认 `0.7`。 |
| `borderSpeedMultiplier` | `Float?` | 只作用于边框动画的速度乘数，默认 `1`。 |
| `glowLayers` | `[GlowLayerConfig]?` | 每一层 glow 的配置。当前最多渲染 10 层。 |

补充说明：

- `borderColor` 当前在提供两个及以上颜色时会呈现动态边框。
- 如果 `glowLayers` 为空或未提供，则只会渲染背景和动态边框。
- `GlowConfig.css(...)` 支持直接传 CSS 风格字符串，并自动转换为 `GlowColor`。

### GlowLayerConfig

每个 `GlowLayerConfig` 表示一层 glow pass。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `colors` | `[GlowColor]?` | 当前 coverage 区段内使用的渐变颜色。空值或省略时会退化为透明。 |
| `opacity` | `Float?` | 该层的不透明度乘数。默认 `0.5`。 |
| `glowSize` | `[Float]?` | 该层沿动画区段的 glow 半径轮廓，支持 1 到 4 个值。省略时视为零发光。 |
| `speedMultiplier` | `Float?` | 在 `animationSpeed` 基础上叠加的单层速度乘数。默认 `1`。 |
| `glowPlacement` | `GlowPlacement?` | 相对内容形状的位置：`.behind`、`.inside`、`.over`。默认 `.behind`。 |
| `coverage` | `Float?` | 动态区段覆盖周长的比例。`1` 表示整圈，`0.5` 表示半圈，`0` 表示禁用该层。默认 `1`。 |
| `relativeOffset` | `Float?` | 沿周长方向的归一化偏移量。默认 `0`。 |

`glowSize` 的扩展规则与 React Native 包一致：

- `[a] -> [a, a, a, a]`
- `[a, b] -> [a, b, b, a]`
- `[a, b, c] -> [a, b, c, c]`
- `[a, b, c, d] -> [a, b, c, d]`

### GlowState 与 PresetConfig

| 类型 | 字段 | 说明 |
| --- | --- | --- |
| `GlowState` | `name`、`preset`、`transition` | 一个具名状态覆盖。`name` 可取 `.default`、`.hover`、`.press`。 |
| `GlowStatus` | `.default`、`.hover`、`.press`、`.auto`、`.manual(GlowEvent)` | 控制当前解析哪个状态变体。 |
| `PresetConfig` | `states` | 预设容器，内建预设例如 `GlowPresets.appleIntelligence` 就是这个结构。 |

`transition` 目前主要用于兼容 React Native 配置模型。SwiftUI 包装层暂时还没有把状态切换做成插值动画，所以修改 `activeState` 时会立即切换到解析后的目标状态。

### 支持的颜色格式

`GlowColor(css:)` 和 `GlowConfig.css(...)` 目前支持：

- `#fff`
- `#ffffff`
- `#ffffffff`
- `rgb(255, 0, 0)`
- `rgba(255, 0, 0, 0.5)`
- `transparent`

## 可用类型

当前对外公开的核心类型：

- `GlowColor`
- `GlowPlacement`
- `GlowEvent`
- `GlowStatus`
- `GlowLayerConfig`
- `GlowConfig`
- `GlowState`
- `PresetConfig`
- `GlowPresets`
- `AnimatedGlow`

## React Native 兼容性

`SwiftGlow` 是围绕与 `react-native-animated-glow` 相同的使用心智构建的。

当前已实现的兼容规则：

- `glowPlacement`: `behind | inside | over`
- `glowLayers` 按数组下标合并
- 支持 `default / hover / press` 状态结构
- 支持 CSS 风格颜色：`#fff`、`#ffffff`、`#ffffffff`、`rgb(...)`、`rgba(...)`
- 渐变颜色采样会无缝回到第一个颜色

`glowSize` 扩展规则：

- `[a] -> [a, a, a, a]`
- `[a, b] -> [a, b, b, a]`
- `[a, b, c] -> [a, b, c, c]`
- `[a, b, c, d] -> [a, b, c, d]`

## 预设

当前内建预设包括：

- `GlowPresets.appleIntelligence`
- `GlowPresets.neonGreen`
- `GlowPresets.rainbow`
- `GlowPresets.alert`
- `GlowPresets.vaporwave`
- `GlowPresets.glimmer`

它们既可以直接使用，也适合作为你自己效果配置时的参考。

## macOS Demo

仓库中包含一个带实时参数编辑器的 macOS demo。

运行方式：

```sh
swift run SwiftGlowDemo
```

Demo 支持：

- 切换内建预设
- 实时编辑全局 glow 参数
- 添加、复制、删除 glow layer
- 编辑每层的位置、颜色、尺寸、coverage、速度和偏移
- 在 `default`、`hover`、`press` 状态之间切换预览
- 导入 `react-native-animated-glow` JSON 预设

## 给 Agent 使用

如果你想让 agent 帮你把 `SwiftGlow` 集成到别的 SwiftUI 项目中，可以安装配套 skill：

```sh
npx skills add margox/swiftglow-integration
```

之后可以直接让 agent 做这些事：

- 把 `SwiftGlow` 加到我的 SwiftUI app，并做一个霓虹 CTA 按钮
- 把这个 `react-native-animated-glow` 预设迁移成 SwiftGlow
- 给这个设置页加一个 Apple Intelligence 风格的 glow 处理

这个 skill 主要帮助 agent：

- 添加 Swift Package 依赖
- 在内建预设与自定义 `GlowState` 配置之间做选择
- 正确迁移 React Native glow JSON 和数值语义
- 发现并修正常见集成问题，比如 glow 被裁切、`inside` layer 被内容盖住

### 导入 React Native JSON

demo 里包含 `Import RN JSON` 操作。可以粘贴与 React Native 包相同结构的 JSON：

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

当前导入器支持：

- `metadata.name`
- `metadata.textColor`
- `states.default / hover / press`
- React Native 毫秒单位的 `transition`
- 单个字符串或数组形式的 `borderColor`
- 单个数值或数组形式的 `glowSize`

## 当前状态

目前已经比较稳定的部分：

- SwiftPM 构建正常
- 单元测试覆盖了兼容性辅助逻辑
- Metal shader 渲染已接通并可运行
- demo 的导入和编辑流程已经具备

当前限制：

- 状态切换时间虽然会被解析和存储，但 SwiftUI 包装层还没有像 React Native 实现那样对状态切换做插值动画
- 视觉一致性已经比较接近，但还没有通过多设备自动快照与 React Native 参考实现做系统对比
- 还没有公开 UIKit / AppKit 风格的一层包装 API，主要使用方式仍然是 SwiftUI

## 开发

构建：

```sh
swift build
```

运行测试：

```sh
swift test
```

运行 demo：

```sh
swift run SwiftGlowDemo
```

## 项目结构

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

- 为 `default`、`hover`、`press` 提供状态插值动画
- 在 demo 之外公开预设导入 / 导出辅助工具
- 增加基于 snapshot 的视觉回归测试
- 增加更多内建预设
- 优化大量 glow 视图同时存在时的性能

## 致谢

SwiftGlow 的灵感来自 [`realimposter/react-native-animated-glow`](https://github.com/realimposter/react-native-animated-glow)。这个包的目标是把相近的配置模型和动态 glow 视觉效果带到 SwiftUI 和 Metal。

## 许可证

MIT。见 [LICENSE](LICENSE)。
