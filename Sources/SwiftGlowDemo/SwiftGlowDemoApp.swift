import Foundation
import SwiftGlow
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
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
        ZStack {
            DemoTheme.windowBackground
                .ignoresSafeArea()

            HStack(spacing: 18) {
                InspectorView(model: model)
                    .frame(width: 386)

                PreviewStage(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
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
        loadPreset(GlowPresets.appleIntelligence, title: "Apple Intelligence")
    }

    var states: [GlowState] {
        [
            GlowState(name: .default, preset: config),
            importedHoverState ?? GlowState(
                name: .hover,
                preset: GlowConfig(
                    animationSpeed: Float(animationSpeed * 1.3),
                    glowLayers: enabledLayers.map { $0.hoverOverride }
                ),
                transition: 0.3
            ),
            importedPressState ?? GlowState(
                name: .press,
                preset: GlowConfig(
                    animationSpeed: Float(animationSpeed * 1.7),
                    glowLayers: enabledLayers.map { $0.pressOverride }
                ),
                transition: 0.1
            )
        ]
    }

    var enabledLayers: [EditableGlowLayer] {
        layers.filter(\.isEnabled)
    }

    var config: GlowConfig {
        .css(
            cornerRadius: Float(cornerRadius),
            outlineWidth: Float(outlineWidth),
            borderColor: parseColorList(borderColors),
            backgroundColor: backgroundColor,
            animationSpeed: Float(animationSpeed),
            borderSpeedMultiplier: Float(borderSpeedMultiplier),
            glowLayers: enabledLayers.map(\.config)
        )
    }

    var previewTextColor: Color {
        let color = GlowColor(css: textColor)
        return Color(red: Double(color.red), green: Double(color.green), blue: Double(color.blue), opacity: Double(color.alpha))
    }

    func loadAppleIntelligence() {
        loadPreset(GlowPresets.appleIntelligence, title: "Apple Intelligence")
    }

    func loadNeonGreen() {
        loadPreset(GlowPresets.neonGreen, title: "Neon Green")
    }

    func loadRainbow() {
        loadPreset(GlowPresets.rainbow, title: "Rainbow")
    }

    func loadAlert() {
        loadPreset(GlowPresets.alert, title: "Alert")
    }

    func loadVaporwave() {
        loadPreset(GlowPresets.vaporwave, title: "Vaporwave")
    }

    func loadGlimmer() {
        loadPreset(GlowPresets.glimmer, title: "Glimmer")
    }

    private func loadPreset(_ preset: PresetConfig, title: String) {
        activeState = .default
        let defaultConfig = preset.states.first { $0.name == .default }?.preset ?? GlowConfig()
        cornerRadius = Double(defaultConfig.cornerRadius ?? 50)
        outlineWidth = Double(defaultConfig.outlineWidth ?? 0)
        animationSpeed = Double(defaultConfig.animationSpeed ?? 1)
        borderSpeedMultiplier = Double(defaultConfig.borderSpeedMultiplier ?? 1)
        backgroundColor = defaultConfig.backgroundColor.map(cssString) ?? "#000000"
        borderColors = defaultConfig.borderColor.map(cssListString) ?? "#ffffff"
        textColor = defaultConfig.textColor.map(cssString) ?? "#ffffff"
        buttonTitle = title
        layers = (defaultConfig.glowLayers ?? []).enumerated().map { index, layer in
            EditableGlowLayer(glowLayer: layer, index: index)
        }
        importedHoverState = preset.states.first { $0.name == .hover }
        importedPressState = preset.states.first { $0.name == .press }
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

    func duplicateLayer(id: UUID) -> UUID? {
        guard let index = layers.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        var copy = layers[index]
        copy.id = UUID()
        copy.name += " Copy"
        layers.insert(copy, at: index + 1)
        selectedLayerID = copy.id
        return copy.id
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

    func removeLayer(id: UUID) {
        guard layers.count > 1,
              let index = layers.firstIndex(where: { $0.id == id }) else {
            return
        }
        layers.remove(at: index)
        if selectedLayerID == id {
            selectedLayerID = layers[min(index, layers.count - 1)].id
        }
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

    func copyReactNativeGlowJSON() {
        copyToClipboard(reactNativeGlowJSON())
    }

    func copySwiftGlowConfig() {
        copyToClipboard(swiftGlowConfigString())
    }

    private func reactNativeGlowJSON() -> String {
        let layerJSON = layers.map { layer in
            """
            {
              "colors": [\(parseColorList(layer.colors).map { "\"\($0)\"" }.joined(separator: ", "))],
              "opacity": \(formatNumber(layer.opacity)),
              "glowSize": [\(parseNumberList(layer.glowSize).map { formatNumber(Double($0)) }.joined(separator: ", "))],
              "speedMultiplier": \(formatNumber(layer.speedMultiplier)),
              "glowPlacement": "\(layer.placement.rawValue)",
              "coverage": \(formatNumber(layer.coverage)),
              "relativeOffset": \(formatNumber(layer.relativeOffset))
            }
            """
        }.joined(separator: ",\n")

        return """
        {
          "metadata": {
            "name": "\(buttonTitle)",
            "textColor": "\(textColor)"
          },
          "states": [
            {
              "name": "default",
              "preset": {
                "cornerRadius": \(formatNumber(cornerRadius)),
                "outlineWidth": \(formatNumber(outlineWidth)),
                "borderColor": [\(parseColorList(borderColors).map { "\"\($0)\"" }.joined(separator: ", "))],
                "backgroundColor": "\(backgroundColor)",
                "animationSpeed": \(formatNumber(animationSpeed)),
                "borderSpeedMultiplier": \(formatNumber(borderSpeedMultiplier)),
                "glowLayers": [
        \(layerJSON.split(separator: "\n").map { "          \($0)" }.joined(separator: "\n"))
                ]
              }
            }
          ]
        }
        """
    }

    private func swiftGlowConfigString() -> String {
        """
        GlowConfig.css(
            cornerRadius: \(formatNumber(cornerRadius)),
            outlineWidth: \(formatNumber(outlineWidth)),
            borderColor: \(parseColorList(borderColors)),
            backgroundColor: "\(backgroundColor)",
            animationSpeed: \(formatNumber(animationSpeed)),
            borderSpeedMultiplier: \(formatNumber(borderSpeedMultiplier))
        )
        """
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
    var isEnabled: Bool
    var placement: GlowPlacement
    var colors: String
    var glowSize: String
    var opacity: Double
    var speedMultiplier: Double
    var coverage: Double
    var relativeOffset: Double

    init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        placement: GlowPlacement,
        colors: String,
        glowSize: String,
        opacity: Double,
        speedMultiplier: Double,
        coverage: Double,
        relativeOffset: Double
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.placement = placement
        self.colors = colors
        self.glowSize = glowSize
        self.opacity = opacity
        self.speedMultiplier = speedMultiplier
        self.coverage = coverage
        self.relativeOffset = relativeOffset
    }

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
    init(glowLayer layer: GlowLayerConfig, index: Int) {
        self.init(
            name: "Layer \(index + 1)",
            placement: layer.glowPlacement ?? .behind,
            colors: cssListString(layer.colors ?? [.white]),
            glowSize: (layer.glowSize ?? [0]).map { formatNumber(Double($0)) }.joined(separator: ", "),
            opacity: Double(layer.opacity ?? 0.5),
            speedMultiplier: Double(layer.speedMultiplier ?? 1),
            coverage: Double(layer.coverage ?? 1),
            relativeOffset: Double(layer.relativeOffset ?? 0)
        )
    }

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
    @State private var expandedLayerIDs: Set<UUID> = []
    @State private var copyMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            ScrollView {
                VStack(spacing: 0) {
                    presetControls
                    stateControls
                    generalControls
                    layerList
                }
            }

            bottomActions
        }
        .padding(.vertical, 8)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DemoTheme.sidebarBackground, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(DemoTheme.sectionStroke, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 24, y: 14)
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
        .alert("Copied", isPresented: copyAlertBinding) {
            Button("OK") {
                copyMessage = nil
            }
        } message: {
            Text(copyMessage ?? "")
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Text("SwiftGlow")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DemoTheme.textPrimary)
            Spacer()
            Button("Import") {
                importError = nil
                isImporting = true
            }
            .buttonStyle(MiniButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DemoTheme.sectionStroke)
                .frame(height: 1)
        }
    }

    private var stateControls: some View {
        InspectorSection(title: "State") {
            CompactSegmentedPicker(selection: $model.activeState)
        }
    }

    private var presetControls: some View {
        InspectorSection {
            SectionTitleRow(title: "Presets")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                Button("Apple Intelligence") {
                    model.loadAppleIntelligence()
                }
                .buttonStyle(PresetButtonStyle())

                Button("Neon Green") {
                    model.loadNeonGreen()
                }
                .buttonStyle(PresetButtonStyle())

                Button("Rainbow") {
                    model.loadRainbow()
                }
                .buttonStyle(PresetButtonStyle())

                Button("Alert") {
                    model.loadAlert()
                }
                .buttonStyle(PresetButtonStyle())

                Button("Vaporwave") {
                    model.loadVaporwave()
                }
                .buttonStyle(PresetButtonStyle())

                Button("Glimmer") {
                    model.loadGlimmer()
                }
                .buttonStyle(PresetButtonStyle())
            }
        }
    }

    private var generalControls: some View {
        InspectorSection(title: "Base") {
            InspectorTextRow("Title", text: $model.buttonTitle)
            InspectorColorRow("Text", text: $model.textColor)
            InspectorColorRow("Fill", text: $model.backgroundColor)
            InspectorColorListRow("Border", text: $model.borderColors)
            InspectorSliderRow("Radius", value: $model.cornerRadius, range: 0...120, step: 1)
            InspectorSliderRow("Outline", value: $model.outlineWidth, range: 0...20, step: 1)
            InspectorSliderRow("Speed", value: $model.animationSpeed, range: 0...8, step: 0.1)
            InspectorSliderRow("Border Speed", value: $model.borderSpeedMultiplier, range: 0...5, step: 0.1)
        }
    }

    private var layerList: some View {
        InspectorSection {
            SectionTitleRow(title: "Layers") {
                HStack(spacing: 4) {
                    Button {
                        let previousIDs = Set(model.layers.map(\.id))
                        model.addLayer()
                        if let newID = model.layers.first(where: { !previousIDs.contains($0.id) })?.id {
                            expandedLayerIDs.insert(newID)
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(IconButtonStyle())
                }
            }

            VStack(spacing: 2) {
                ForEach($model.layers) { $layer in
                    let isExpanded = expandedLayerIDs.contains(layer.id)
                    VStack(spacing: 0) {
                        LayerTitleRow(
                            layer: $layer,
                            isExpanded: isExpanded,
                            canRemove: model.layers.count > 1,
                            onCopy: {
                                if let copiedID = model.duplicateLayer(id: layer.id) {
                                    expandedLayerIDs.insert(copiedID)
                                }
                            },
                            onRemove: {
                                expandedLayerIDs.remove(layer.id)
                                model.removeLayer(id: layer.id)
                            },
                            onToggleExpanded: {
                                if isExpanded {
                                    expandedLayerIDs.remove(layer.id)
                                } else {
                                    model.selectedLayerID = layer.id
                                    expandedLayerIDs.insert(layer.id)
                                }
                            }
                        )

                        if isExpanded {
                            LayerInlineEditor(layer: $layer)
                        }
                    }
                }
            }
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 6) {
            Button("Copy RNGlow Config") {
                model.copyReactNativeGlowJSON()
                copyMessage = "RNGlow config copied to clipboard."
            }
            .buttonStyle(ActionButtonStyle())

            Button("Copy SwiftGlow Config") {
                model.copySwiftGlowConfig()
                copyMessage = "SwiftGlow config copied to clipboard."
            }
            .buttonStyle(ActionButtonStyle(tint: DemoTheme.accent))
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DemoTheme.sectionStroke)
                .frame(height: 1)
        }
    }

    private var copyAlertBinding: Binding<Bool> {
        Binding(
            get: { copyMessage != nil },
            set: { isPresented in
                if !isPresented {
                    copyMessage = nil
                }
            }
        )
    }
}

struct LayerTitleRow: View {
    @Binding var layer: EditableGlowLayer
    let isExpanded: Bool
    let canRemove: Bool
    let onCopy: () -> Void
    let onRemove: () -> Void
    let onToggleExpanded: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onToggleExpanded) {
                Text(layer.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(layer.isEnabled ? DemoTheme.textPrimary : DemoTheme.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(IconButtonStyle())

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(IconButtonStyle())
            .disabled(!canRemove)

            Toggle("", isOn: $layer.isEnabled)
                .labelsHidden()
                .toggleStyle(InspectorCheckboxStyle())
                .controlSize(.mini)

            Button(action: onToggleExpanded) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .buttonStyle(IconButtonStyle())
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .contentShape(Rectangle())
        .background(isExpanded ? DemoTheme.accentSoft : DemoTheme.layerRowBackground, in: RoundedRectangle(cornerRadius: 6))
    }
}

struct LayerInlineEditor: View {
    @Binding var layer: EditableGlowLayer

    var body: some View {
        VStack(spacing: 4) {
            InspectorTextRow("Name", text: $layer.name)
            InspectorPlacementRow("Placement", selection: $layer.placement)
            InspectorColorListRow("Colors", text: $layer.colors)
            InspectorTextRow("Size", text: $layer.glowSize)
            InspectorSliderRow("Opacity", value: $layer.opacity, range: 0...1, step: 0.01)
            InspectorSliderRow("Speed", value: $layer.speedMultiplier, range: 0...5, step: 0.1)
            InspectorSliderRow("Coverage", value: $layer.coverage, range: 0...1, step: 0.01)
            InspectorSliderRow("Offset", value: $layer.relativeOffset, range: 0...1, step: 0.01)
        }
        .padding(.vertical, 6)
    }
}

struct InspectorSection<Content: View>: View {
    private let title: String?
    private let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 6) {
            if let title {
                SectionTitleRow(title: title)
            }
            content
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DemoTheme.sectionStroke)
                .frame(height: 1)
        }
    }
}

struct SectionTitleRow<Accessory: View>: View {
    let title: String
    private let accessory: Accessory

    init(title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    init(title: String) where Accessory == EmptyView {
        self.title = title
        self.accessory = EmptyView()
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DemoTheme.textPrimary)
            Spacer()
            accessory
        }
        .frame(height: 22)
    }
}

struct CompactSegmentedPicker: View {
    @Binding var selection: GlowEvent

    var body: some View {
        HStack(spacing: 2) {
            segment("Default", value: .default)
            segment("Hover", value: .hover)
            segment("Press", value: .press)
        }
        .padding(2)
        .background(DemoTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 7))
    }

    private func segment(_ title: String, value: GlowEvent) -> some View {
        Button {
            selection = value
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(selection == value ? Color.white : DemoTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 22)
                .contentShape(Rectangle())
                .background(selection == value ? DemoTheme.accent : Color.clear, in: RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}

struct InspectorTextRow: View {
    let title: String
    @Binding var text: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    var body: some View {
        HStack(spacing: InspectorLayout.rowSpacing) {
            InspectorRowLabel(title)
            TextField(title, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DemoTheme.textPrimary)
                .padding(.horizontal, 7)
                .frame(height: 24)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .background(DemoTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 5))
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(DemoTheme.sectionStroke, lineWidth: 1)
                }
        }
        .frame(height: 28)
    }
}

struct InspectorColorRow: View {
    let title: String
    @Binding var text: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: InspectorLayout.rowSpacing) {
            InspectorRowLabel(title)
            ColorValueEditor(
                cssText: text,
                color: colorBinding,
                opacity: opacityBinding
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { colorFromCSS(text) },
            set: { text = cssString($0, alpha: alphaFromCSS(text)) }
        )
    }

    private var opacityBinding: Binding<Double> {
        Binding(
            get: { alphaFromCSS(text) },
            set: { text = cssString(colorFromCSS(text), alpha: $0) }
        )
    }
}

struct InspectorColorListRow: View {
    let title: String
    @Binding var text: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: InspectorLayout.rowSpacing) {
            InspectorRowLabel(title)
            VStack(alignment: .leading, spacing: 5) {
                ForEach(colorValues.indices, id: \.self) { index in
                    ColorValueEditor(
                        cssText: colorValues[index],
                        color: colorBinding(at: index),
                        opacity: opacityBinding(at: index),
                        canDelete: colorValues.count > 1,
                        onDelete: {
                            removeColor(at: index)
                        }
                    )
                }

                Button {
                    appendColor()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .semibold))
                        Text("Add color")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(DemoTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    private var colorValues: [String] {
        let values = parseColorList(text)
        return values.isEmpty ? ["#FFFFFFFF"] : values
    }

    private func colorBinding(at index: Int) -> Binding<Color> {
        Binding(
            get: {
                let values = colorValues
                return colorFromCSS(values[min(index, values.count - 1)])
            },
            set: { color in
                var values = colorValues
                guard values.indices.contains(index) else {
                    return
                }
                values[index] = cssString(color, alpha: alphaFromCSS(values[index]))
                text = values.joined(separator: ", ")
            }
        )
    }

    private func opacityBinding(at index: Int) -> Binding<Double> {
        Binding(
            get: {
                let values = colorValues
                return alphaFromCSS(values[min(index, values.count - 1)])
            },
            set: { opacity in
                var values = colorValues
                guard values.indices.contains(index) else {
                    return
                }
                values[index] = cssString(colorFromCSS(values[index]), alpha: opacity)
                text = values.joined(separator: ", ")
            }
        )
    }

    private func appendColor() {
        var values = colorValues
        values.append(values.last ?? "#FFFFFFFF")
        text = values.joined(separator: ", ")
    }

    private func removeColor(at index: Int) {
        var values = colorValues
        guard values.count > 1, values.indices.contains(index) else {
            return
        }
        values.remove(at: index)
        text = values.joined(separator: ", ")
    }
}

struct ColorValueEditor: View {
    let cssText: String
    @Binding var color: Color
    @Binding var opacity: Double
    var canDelete = false
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: InspectorLayout.controlSpacing) {
            ZStack {
                ColorPicker("", selection: $color, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(x: 1.8, y: 0.95)
                    .frame(width: 42, height: 20)
                    .clipShape(Capsule())

                Capsule()
                    .stroke(DemoTheme.sectionStroke, lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .frame(width: 42, height: 22)

            Text(hexRGBAString(cssText))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(DemoTheme.textPrimary)
                .lineLimit(1)
                .frame(width: 72, alignment: .leading)

            CompactSlider(value: $opacity, range: 0...1, step: 0.01)
                .frame(width: 72)

            if let onDelete {
                Spacer(minLength: 0)

                Button(action: onDelete) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(IconButtonStyle())
                .disabled(!canDelete)
            }
        }
        .frame(height: 26)
    }
}

struct InspectorPlacementRow: View {
    let title: String
    @Binding var selection: GlowPlacement

    init(_ title: String, selection: Binding<GlowPlacement>) {
        self.title = title
        self._selection = selection
    }

    var body: some View {
        HStack(spacing: InspectorLayout.rowSpacing) {
            InspectorRowLabel(title)
            HStack(spacing: 2) {
                segment("Behind", value: .behind)
                segment("Inside", value: .inside)
                segment("Over", value: .over)
            }
            .padding(2)
            .background(DemoTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 7))
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 28)
    }

    private func segment(_ title: String, value: GlowPlacement) -> some View {
        Button {
            selection = value
        } label: {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(selection == value ? Color.white : DemoTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 20)
                .contentShape(Rectangle())
                .background(selection == value ? DemoTheme.accent : Color.clear, in: RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}

struct CompactSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width)
            let progress = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let clampedProgress = min(1, max(0, progress))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DemoTheme.fieldRaised)
                    .frame(height: 4)
                Capsule()
                    .fill(DemoTheme.accent)
                    .frame(width: width * clampedProgress, height: 4)
                Circle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 14, height: 14)
                    .offset(x: max(0, min(width - 14, width * clampedProgress - 7)))
            }
            .frame(height: 18)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        updateValue(locationX: gesture.location.x, width: width)
                    }
            )
        }
        .frame(height: 18)
    }

    private func updateValue(locationX: CGFloat, width: CGFloat) {
        let progress = min(1, max(0, Double(locationX / width)))
        let rawValue = range.lowerBound + (range.upperBound - range.lowerBound) * progress
        let steppedValue = (rawValue / step).rounded() * step
        value = min(range.upperBound, max(range.lowerBound, steppedValue))
    }
}

struct InspectorSliderRow: View {
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
        HStack(spacing: InspectorLayout.rowSpacing) {
            InspectorRowLabel(title)
            CompactSlider(value: $value, range: range, step: step)
            Text(value.formatted(.number.precision(.fractionLength(0...2))))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(DemoTheme.textPrimary)
                .frame(width: 34, alignment: .trailing)
        }
        .frame(height: 28)
    }
}

struct InspectorRowLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(DemoTheme.textSecondary)
            .frame(width: InspectorLayout.labelWidth, alignment: .leading)
    }
}

enum InspectorLayout {
    static let labelWidth: CGFloat = 88
    static let rowSpacing: CGFloat = 16
    static let controlSpacing: CGFloat = 8
}

struct MiniButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(DemoTheme.textPrimary)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .contentShape(Rectangle())
            .background(DemoTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 5))
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(DemoTheme.sectionStroke, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(DemoTheme.textSecondary)
            .frame(width: 22, height: 22)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}

struct InspectorCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DemoTheme.textSecondary)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct PresetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(DemoTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .frame(height: 26)
            .contentShape(Rectangle())
            .background(configuration.isPressed ? DemoTheme.fieldRaised : DemoTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(DemoTheme.sectionStroke, lineWidth: 1)
            }
    }
}

struct ActionButtonStyle: ButtonStyle {
    var tint: Color = DemoTheme.fieldBackground
    var isProminent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(isProminent || tint != DemoTheme.fieldBackground ? Color.white : DemoTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 26)
            .background(backgroundColor(pressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isProminent ? tint.opacity(0.25) : DemoTheme.sectionStroke, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.94 : 1)
    }

    private func backgroundColor(pressed: Bool) -> Color {
        pressed ? tint.opacity(isProminent ? 0.86 : 0.92) : tint
    }
}

struct DialogButtonStyle: ButtonStyle {
    var tint: Color = DemoTheme.fieldBackground
    var isProminent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isProminent ? Color.white : DemoTheme.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 28)
            .background(configuration.isPressed ? tint.opacity(0.82) : tint, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isProminent ? tint.opacity(0.2) : DemoTheme.sectionStroke, lineWidth: 1)
            }
    }
}

struct HiddenTextEditorBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

enum DemoTheme {
    static let windowBackground = Color(red: 0.09, green: 0.09, blue: 0.1)
    static let sidebarBackground = Color(red: 0.145, green: 0.145, blue: 0.155)
    static let previewPanelBackground = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let fieldBackground = Color(red: 0.205, green: 0.205, blue: 0.215)
    static let fieldRaised = Color.white.opacity(0.08)
    static let layerRowBackground = Color.white.opacity(0.035)
    static let sectionStroke = Color.white.opacity(0.07)
    static let textPrimary = Color.white.opacity(0.94)
    static let textSecondary = Color.white.opacity(0.58)
    static let accent = Color(red: 0.37, green: 0.5, blue: 0.98)
    static let accentSoft = accent.opacity(0.18)
    static let danger = Color(red: 0.84, green: 0.39, blue: 0.42)
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
                    .foregroundStyle(DemoTheme.textPrimary)
                Spacer()
                Button("Get presets from https://reactnativeglow.com/") {
                    openExternalURL("https://reactnativeglow.com/")
                }
                .buttonStyle(MiniButtonStyle())
            }

            TextEditor(text: $jsonText)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 720, minHeight: 460)
                .padding(10)
                .modifier(HiddenTextEditorBackground())
                .background(DemoTheme.fieldBackground, in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(DemoTheme.sectionStroke, lineWidth: 1)
                }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(DemoTheme.danger)
            }

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(DialogButtonStyle())

                Button("Confirm") {
                    onImport()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(DialogButtonStyle(tint: DemoTheme.accent, isProminent: true))
            }
        }
        .padding(20)
        .background(DemoTheme.sidebarBackground)
        .preferredColorScheme(.dark)
    }
}

struct PreviewStage: View {
    @ObservedObject var model: DemoModel

    var body: some View {
        ZStack {
            DemoTheme.previewPanelBackground

            previewTitle
                .foregroundStyle(model.previewTextColor)
                .padding(.horizontal, 52)
                .padding(.vertical, 22)
                .animatedGlow(
                    states: model.states,
                    status: .manual(model.activeState)
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(DemoTheme.sectionStroke, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.3), radius: 28, y: 18)
    }

    private var previewTitle: Text {
        Text(model.buttonTitle)
            .font(.system(size: 22, weight: .bold))
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

func cssListString(_ colors: [GlowColor]) -> String {
    colors.map(cssString).joined(separator: ", ")
}

func cssString(_ color: GlowColor) -> String {
    hexRGBAString(
        red: CGFloat(color.red),
        green: CGFloat(color.green),
        blue: CGFloat(color.blue),
        alpha: CGFloat(color.alpha)
    )
}

func colorFromCSS(_ text: String) -> Color {
    let color = GlowColor(css: text)
    return Color(
        red: Double(color.red),
        green: Double(color.green),
        blue: Double(color.blue),
        opacity: Double(color.alpha)
    )
}

func alphaFromCSS(_ text: String) -> Double {
    Double(GlowColor(css: text).alpha)
}

func cssString(_ color: Color) -> String {
    let components = colorComponents(color)
    return hexRGBAString(red: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
}

func cssString(_ color: Color, alpha: Double) -> String {
    let components = colorComponents(color)
    return hexRGBAString(
        red: components.red,
        green: components.green,
        blue: components.blue,
        alpha: CGFloat(min(1, max(0, alpha)))
    )
}

private func colorComponents(_ color: Color) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    #if canImport(AppKit)
    let nsColor = NSColor(color)
    let converted = nsColor.usingColorSpace(.sRGB) ?? nsColor
    return (converted.redComponent, converted.greenComponent, converted.blueComponent, converted.alphaComponent)
    #elseif canImport(UIKit)
    let uiColor = UIColor(color)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return (red, green, blue, alpha)
    #else
    return (1, 1, 1, 1)
    #endif
}

func hexRGBAString(_ text: String) -> String {
    let color = GlowColor(css: text)
    return hexRGBAString(
        red: CGFloat(color.red),
        green: CGFloat(color.green),
        blue: CGFloat(color.blue),
        alpha: CGFloat(color.alpha)
    )
}

private func hexRGBAString(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> String {
    let red255 = Int((red * 255).rounded())
    let green255 = Int((green * 255).rounded())
    let blue255 = Int((blue * 255).rounded())
    let alpha255 = Int((alpha * 255).rounded())
    return String(format: "#%02X%02X%02X%02X", red255, green255, blue255, alpha255)
}

func copyToClipboard(_ text: String) {
    #if canImport(AppKit)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    #elseif canImport(UIKit)
    UIPasteboard.general.string = text
    #endif
}

func openExternalURL(_ text: String) {
    guard let url = URL(string: text) else {
        return
    }
    #if canImport(AppKit)
    NSWorkspace.shared.open(url)
    #elseif canImport(UIKit)
    UIApplication.shared.open(url)
    #endif
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
