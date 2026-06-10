import Foundation
import SwiftGlow
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

@main
struct SwiftGlowDemoApp: App {
    #if canImport(AppKit)
    @NSApplicationDelegateAdaptor(DemoAppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            DemoRootView()
                .frame(minWidth: 1120, minHeight: 720)
        }
    }
}

#if canImport(AppKit)
final class DemoAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}
#endif

struct DemoRootView: View {
    @StateObject private var model = DemoModel()

    var body: some View {
        HStack(spacing: 0) {
            InspectorView(model: model)
                .frame(width: 420)
                .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            PreviewStage(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

@MainActor
final class DemoModel: ObservableObject {
    @Published var activeState: GlowEvent = .default
    @Published var cornerRadius: Double = 50
    @Published var outlineWidth: Double = 0
    @Published var animationSpeed: Double = 1
    @Published var borderSpeedMultiplier: Double = 1
    @Published var backgroundColor = "#000000"
    @Published var borderColors = "#ffffff"
    @Published var textColor = "#ffffff"
    @Published var buttonTitle = "Apple Intelligence"
    @Published var selectedLayerID: UUID?
    @Published var layers: [EditableGlowLayer] = .appleIntelligence
    @Published var importedHoverState: GlowState?
    @Published var importedPressState: GlowState?

    init() {
        selectedLayerID = layers.first?.id
    }

    var states: [GlowState] {
        [
            GlowState(name: .default, preset: config),
            importedHoverState ?? GlowState(
                name: .hover,
                preset: GlowConfig(
                    animationSpeed: Float(animationSpeed * 1.3),
                    glowLayers: layers.map { $0.hoverOverride }
                ),
                transition: 0.3
            ),
            importedPressState ?? GlowState(
                name: .press,
                preset: GlowConfig(
                    animationSpeed: Float(animationSpeed * 1.7),
                    glowLayers: layers.map { $0.pressOverride }
                ),
                transition: 0.1
            )
        ]
    }

    var config: GlowConfig {
        .css(
            cornerRadius: Float(cornerRadius),
            outlineWidth: Float(outlineWidth),
            borderColor: parseColorList(borderColors),
            backgroundColor: backgroundColor,
            animationSpeed: Float(animationSpeed),
            borderSpeedMultiplier: Float(borderSpeedMultiplier),
            glowLayers: layers.map(\.config)
        )
    }

    var previewTextColor: Color {
        let color = GlowColor(css: textColor)
        return Color(red: Double(color.red), green: Double(color.green), blue: Double(color.blue), opacity: Double(color.alpha))
    }

    var selectedLayerBinding: Binding<EditableGlowLayer>? {
        guard let selectedLayerID,
              let index = layers.firstIndex(where: { $0.id == selectedLayerID }) else {
            return nil
        }
        return Binding(
            get: { self.layers[index] },
            set: { self.layers[index] = $0 }
        )
    }

    func loadAppleIntelligence() {
        activeState = .default
        cornerRadius = 50
        outlineWidth = 0
        animationSpeed = 1
        borderSpeedMultiplier = 1
        backgroundColor = "#000000"
        borderColors = "#ffffff"
        textColor = "#ffffff"
        buttonTitle = "Apple Intelligence"
        layers = .appleIntelligence
        importedHoverState = nil
        importedPressState = nil
        selectedLayerID = layers.first?.id
    }

    func loadNeonGreen() {
        activeState = .default
        cornerRadius = 50
        outlineWidth = 4
        animationSpeed = 3
        borderSpeedMultiplier = 1
        backgroundColor = "#1a1a1a"
        borderColors = "#bfff3b, #39ff14, #fff35a"
        textColor = "#39ff14"
        buttonTitle = "Neon Green"
        layers = .neonGreen
        importedHoverState = nil
        importedPressState = nil
        selectedLayerID = layers.first?.id
    }

    func addLayer() {
        let layer = EditableGlowLayer(
            name: "Layer \(layers.count + 1)",
            placement: .behind,
            colors: "#ffffff, #39ff14",
            glowSize: "4, 12, 4",
            opacity: 0.3,
            speedMultiplier: 1,
            coverage: 1,
            relativeOffset: 0
        )
        layers.append(layer)
        selectedLayerID = layer.id
    }

    func duplicateSelectedLayer() {
        guard let selectedLayerID,
              let index = layers.firstIndex(where: { $0.id == selectedLayerID }) else {
            return
        }
        var copy = layers[index]
        copy.id = UUID()
        copy.name += " Copy"
        layers.insert(copy, at: index + 1)
        self.selectedLayerID = copy.id
    }

    func removeSelectedLayer() {
        guard layers.count > 1,
              let selectedLayerID,
              let index = layers.firstIndex(where: { $0.id == selectedLayerID }) else {
            return
        }
        layers.remove(at: index)
        self.selectedLayerID = layers[min(index, layers.count - 1)].id
    }

    func importReactNativeJSON(_ json: String) throws {
        let data = Data(json.utf8)
        let document = try JSONDecoder().decode(ReactNativeGlowDocument.self, from: data)
        guard let defaultState = document.states.first(where: { $0.name == .default }) ?? document.states.first else {
            throw ImportError.missingStates
        }

        activeState = .default
        buttonTitle = document.metadata?.name ?? "Imported Glow"
        textColor = document.metadata?.textColor ?? textColor

        let preset = defaultState.preset
        cornerRadius = preset.cornerRadius ?? cornerRadius
        outlineWidth = preset.outlineWidth ?? outlineWidth
        animationSpeed = preset.animationSpeed ?? animationSpeed
        borderSpeedMultiplier = preset.borderSpeedMultiplier ?? borderSpeedMultiplier
        backgroundColor = preset.backgroundColor ?? backgroundColor
        borderColors = preset.borderColor?.values.joined(separator: ", ") ?? borderColors

        if let glowLayers = preset.glowLayers, !glowLayers.isEmpty {
            layers = glowLayers.enumerated().map { index, layer in
                EditableGlowLayer(reactNativeLayer: layer, index: index)
            }
            selectedLayerID = layers.first?.id
        }

        importedHoverState = document.states.first(where: { $0.name == .hover })?.glowState
        importedPressState = document.states.first(where: { $0.name == .press })?.glowState
    }
}

enum ImportError: LocalizedError {
    case missingStates

    var errorDescription: String? {
        switch self {
        case .missingStates:
            return "The JSON does not contain any states."
        }
    }
}

struct EditableGlowLayer: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var placement: GlowPlacement
    var colors: String
    var glowSize: String
    var opacity: Double
    var speedMultiplier: Double
    var coverage: Double
    var relativeOffset: Double

    var config: GlowLayerConfig {
        GlowLayerConfig(
            cssColors: parseColorList(colors),
            opacity: Float(opacity),
            glowSize: parseNumberList(glowSize),
            speedMultiplier: Float(speedMultiplier),
            glowPlacement: placement,
            coverage: Float(coverage),
            relativeOffset: Float(relativeOffset)
        )
    }

    var hoverOverride: GlowLayerConfig {
        GlowLayerConfig(
            opacity: Float(min(1, opacity * 1.2)),
            glowSize: parseNumberList(glowSize).map { $0 * 1.15 }
        )
    }

    var pressOverride: GlowLayerConfig {
        GlowLayerConfig(
            opacity: Float(min(1, opacity * 1.35)),
            glowSize: parseNumberList(glowSize).map { $0 * 1.25 }
        )
    }
}

extension EditableGlowLayer {
    init(reactNativeLayer layer: ReactNativeGlowLayer, index: Int) {
        self.init(
            name: "Layer \(index + 1)",
            placement: layer.glowPlacement ?? .behind,
            colors: (layer.colors ?? ["#ffffff"]).joined(separator: ", "),
            glowSize: (layer.glowSize?.values ?? [0]).map(formatNumber).joined(separator: ", "),
            opacity: layer.opacity ?? 0.5,
            speedMultiplier: layer.speedMultiplier ?? 1,
            coverage: layer.coverage ?? 1,
            relativeOffset: layer.relativeOffset ?? 0
        )
    }
}

extension Array where Element == EditableGlowLayer {
    static let appleIntelligence: [EditableGlowLayer] = [
        EditableGlowLayer(name: "Violet Core", placement: .inside, colors: "#322dff, #d12d8d, #ff2121, #ff9f2f", glowSize: "24", opacity: 0.3, speedMultiplier: 1, coverage: 1, relativeOffset: 0),
        EditableGlowLayer(name: "Warm Ribbon", placement: .inside, colors: "#6a3cff, #6d18ce, #ff2929, #ffb13f", glowSize: "6", opacity: 0.5, speedMultiplier: 1, coverage: 1, relativeOffset: 0),
        EditableGlowLayer(name: "Hot Edge", placement: .inside, colors: "#f3e8ff, #ff63cb, #ff447d, #ffd498", glowSize: "1", opacity: 1, speedMultiplier: 1, coverage: 1, relativeOffset: 0),
        EditableGlowLayer(name: "Blue Sweep", placement: .inside, colors: "#6f7cff, #c8e1ff", glowSize: "0, 4, 4, 0", opacity: 0.2, speedMultiplier: 2, coverage: 0.4, relativeOffset: 0),
        EditableGlowLayer(name: "White Spark", placement: .inside, colors: "#ffffff", glowSize: "0, 2, 0", opacity: 0.2, speedMultiplier: 2, coverage: 0.4, relativeOffset: 0)
    ]

    static let neonGreen: [EditableGlowLayer] = [
        EditableGlowLayer(name: "Outer Bloom", placement: .behind, colors: "#4cff8d, #e2ff3f, #39ff14", glowSize: "10, 20, 10", opacity: 0.2, speedMultiplier: 1, coverage: 1, relativeOffset: 0),
        EditableGlowLayer(name: "Middle Glow", placement: .behind, colors: "#4cff8d, #e2ff3f, #39ff14", glowSize: "1, 8, 1", opacity: 0.3, speedMultiplier: 1, coverage: 1, relativeOffset: 0),
        EditableGlowLayer(name: "Segment", placement: .behind, colors: "#7fff24, #f4ff43, #39ff14", glowSize: "1, 8, 1", opacity: 0.3, speedMultiplier: 1, coverage: 0.75, relativeOffset: 0),
        EditableGlowLayer(name: "Soft Edge", placement: .behind, colors: "#39ff14, #4cff8d, #7dff9a", glowSize: "2, 8, 2", opacity: 0.5, speedMultiplier: 1, coverage: 1, relativeOffset: 0)
    ]
}

struct InspectorView: View {
    @ObservedObject var model: DemoModel
    @State private var isImporting = false
    @State private var importJSON = ""
    @State private var importError: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    presetControls
                    generalControls
                    layerList
                    if let selectedLayer = model.selectedLayerBinding {
                        LayerEditor(layer: selectedLayer)
                    }
                }
                .padding(18)
            }
        }
        .sheet(isPresented: $isImporting) {
            ReactNativeImportSheet(
                jsonText: $importJSON,
                errorMessage: $importError,
                onImport: {
                    do {
                        try model.importReactNativeJSON(importJSON)
                        importError = nil
                        isImporting = false
                    } catch {
                        importError = error.localizedDescription
                    }
                }
            )
        }
    }

    private var header: some View {
        HStack {
            Text("SwiftGlow")
                .font(.title2.bold())
            Spacer()
            Picker("", selection: $model.activeState) {
                Text("Default").tag(GlowEvent.default)
                Text("Hover").tag(GlowEvent.hover)
                Text("Press").tag(GlowEvent.press)
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
        }
        .padding(18)
    }

    private var presetControls: some View {
        SectionBlock("Presets") {
            HStack {
                Button("Apple Intelligence") {
                    model.loadAppleIntelligence()
                }
                Button("Neon Green") {
                    model.loadNeonGreen()
                }
            }
            Button("Import RN JSON") {
                importError = nil
                isImporting = true
            }
        }
    }

    private var generalControls: some View {
        SectionBlock("General") {
            TextField("Title", text: $model.buttonTitle)
                .textFieldStyle(.roundedBorder)
            TextField("Text Color", text: $model.textColor)
                .textFieldStyle(.roundedBorder)

            LabeledSlider("Corner Radius", value: $model.cornerRadius, range: 0...120, step: 1)
            LabeledSlider("Outline Width", value: $model.outlineWidth, range: 0...20, step: 1)
            LabeledSlider("Animation Speed", value: $model.animationSpeed, range: 0...8, step: 0.1)
            LabeledSlider("Border Speed", value: $model.borderSpeedMultiplier, range: 0...5, step: 0.1)

            TextField("Background Color", text: $model.backgroundColor)
                .textFieldStyle(.roundedBorder)
            TextField("Border Colors", text: $model.borderColors)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var layerList: some View {
        SectionBlock("Layers") {
            VStack(spacing: 8) {
                ForEach(model.layers) { layer in
                    Button {
                        model.selectedLayerID = layer.id
                    } label: {
                        HStack {
                            Text(layer.name)
                            Spacer()
                            Text(layer.placement.rawValue)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .background(selectionBackground(for: layer), in: RoundedRectangle(cornerRadius: 6))
                }
            }

            HStack {
                Button("Add") {
                    model.addLayer()
                }
                Button("Duplicate") {
                    model.duplicateSelectedLayer()
                }
                Button("Remove") {
                    model.removeSelectedLayer()
                }
                .disabled(model.layers.count <= 1)
            }
        }
    }

    private func selectionBackground(for layer: EditableGlowLayer) -> Color {
        layer.id == model.selectedLayerID ? Color.accentColor.opacity(0.16) : Color(nsColor: .textBackgroundColor)
    }
}

struct LayerEditor: View {
    @Binding var layer: EditableGlowLayer

    var body: some View {
        SectionBlock("Selected Layer") {
            TextField("Layer Name", text: $layer.name)
                .textFieldStyle(.roundedBorder)

            Picker("Placement", selection: $layer.placement) {
                Text("Behind").tag(GlowPlacement.behind)
                Text("Inside").tag(GlowPlacement.inside)
                Text("Over").tag(GlowPlacement.over)
            }
            .pickerStyle(.segmented)

            TextField("Colors", text: $layer.colors)
                .textFieldStyle(.roundedBorder)
            TextField("Glow Size", text: $layer.glowSize)
                .textFieldStyle(.roundedBorder)

            LabeledSlider("Opacity", value: $layer.opacity, range: 0...1, step: 0.01)
            LabeledSlider("Speed", value: $layer.speedMultiplier, range: 0...5, step: 0.1)
            LabeledSlider("Coverage", value: $layer.coverage, range: 0...1, step: 0.01)
            LabeledSlider("Offset", value: $layer.relativeOffset, range: 0...1, step: 0.01)
        }
    }
}

struct ReactNativeImportSheet: View {
    @Binding var jsonText: String
    @Binding var errorMessage: String?
    let onImport: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Import React Native Glow JSON")
                    .font(.title3.bold())
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }

            TextEditor(text: $jsonText)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 720, minHeight: 460)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Clear") {
                    jsonText = ""
                    errorMessage = nil
                }
                Spacer()
                Button("Import") {
                    onImport()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
    }
}

struct PreviewStage: View {
    @ObservedObject var model: DemoModel

    var body: some View {
        ZStack {
            Color.black
            checkerboard
                .opacity(0.08)

            VStack(spacing: 28) {
                Text(model.buttonTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(model.previewTextColor)
                    .padding(.horizontal, 52)
                    .padding(.vertical, 22)
                    .animatedGlow(
                        states: model.states,
                        activeState: model.activeState
                    )

                HStack(spacing: 12) {
                    statusPill("Layers", "\(model.layers.count)")
                    statusPill("Speed", formatted(model.animationSpeed))
                    statusPill("Radius", formatted(model.cornerRadius))
                }
            }
        }
    }

    private var checkerboard: some View {
        GeometryReader { proxy in
            Path { path in
                let step: CGFloat = 42
                var x: CGFloat = 0
                while x <= proxy.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    x += step
                }
                var y: CGFloat = 0
                while y <= proxy.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    y += step
                }
            }
            .stroke(Color.white, lineWidth: 1)
        }
    }

    private func statusPill(_ title: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .monospacedDigit()
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}

struct SectionBlock<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
    }
}

struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    init(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value.formatted(.number.precision(.fractionLength(0...2))))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

func parseColorList(_ text: String) -> [String] {
    splitTopLevelComma(text)
}

func parseNumberList(_ text: String) -> [Float] {
    text
        .split(separator: ",")
        .compactMap { Float($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
}

func splitTopLevelComma(_ text: String) -> [String] {
    var values: [String] = []
    var current = ""
    var parenthesisDepth = 0

    for character in text {
        if character == "(" {
            parenthesisDepth += 1
            current.append(character)
        } else if character == ")" {
            parenthesisDepth = max(0, parenthesisDepth - 1)
            current.append(character)
        } else if character == "," && parenthesisDepth == 0 {
            let value = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty {
                values.append(value)
            }
            current = ""
        } else {
            current.append(character)
        }
    }

    let lastValue = current.trimmingCharacters(in: .whitespacesAndNewlines)
    if !lastValue.isEmpty {
        values.append(lastValue)
    }
    return values
}

func formatNumber(_ value: Double) -> String {
    let rounded = value.rounded()
    if abs(value - rounded) < 0.000_001 {
        return String(Int(rounded))
    }
    let trimmed = (value * 1000).rounded() / 1000
    return String(trimmed)
}

struct ReactNativeGlowDocument: Decodable {
    var metadata: ReactNativeGlowMetadata?
    var states: [ReactNativeGlowState]
}

struct ReactNativeGlowMetadata: Decodable {
    var name: String?
    var textColor: String?
}

struct ReactNativeGlowState: Decodable {
    var name: GlowEvent
    var transition: Double?
    var preset: ReactNativeGlowConfig

    var glowState: GlowState {
        GlowState(
            name: name,
            preset: preset.glowConfig,
            transition: transition.map { $0 / 1000 }
        )
    }
}

struct ReactNativeGlowConfig: Decodable {
    var cornerRadius: Double?
    var outlineWidth: Double?
    var borderColor: ReactNativeColorList?
    var backgroundColor: String?
    var animationSpeed: Double?
    var borderSpeedMultiplier: Double?
    var glowLayers: [ReactNativeGlowLayer]?

    var glowConfig: GlowConfig {
        GlowConfig(
            cornerRadius: cornerRadius.map(Float.init),
            outlineWidth: outlineWidth.map(Float.init),
            borderColor: borderColor?.values.map(GlowColor.init(css:)),
            backgroundColor: backgroundColor.map(GlowColor.init(css:)),
            animationSpeed: animationSpeed.map(Float.init),
            borderSpeedMultiplier: borderSpeedMultiplier.map(Float.init),
            glowLayers: glowLayers?.map(\.glowLayerConfig)
        )
    }
}

struct ReactNativeGlowLayer: Decodable {
    var colors: [String]?
    var opacity: Double?
    var glowSize: ReactNativeGlowSize?
    var speedMultiplier: Double?
    var glowPlacement: GlowPlacement?
    var coverage: Double?
    var relativeOffset: Double?

    var glowLayerConfig: GlowLayerConfig {
        GlowLayerConfig(
            colors: colors?.map(GlowColor.init(css:)),
            opacity: opacity.map(Float.init),
            glowSize: glowSize?.values.map(Float.init),
            speedMultiplier: speedMultiplier.map(Float.init),
            glowPlacement: glowPlacement,
            coverage: coverage.map(Float.init),
            relativeOffset: relativeOffset.map(Float.init)
        )
    }
}

struct ReactNativeColorList: Decodable {
    var values: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            values = [value]
        } else {
            values = try container.decode([String].self)
        }
    }
}

struct ReactNativeGlowSize: Decodable {
    var values: [Double]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Double.self) {
            values = [value]
        } else {
            values = try container.decode([Double].self)
        }
    }
}
