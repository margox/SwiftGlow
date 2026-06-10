import SwiftUI

public struct AnimatedGlow<Content: View>: View {
    private let preset: GlowConfig
    private let states: [GlowState]
    private let override: GlowConfig
    private let status: GlowStatus
    private let isVisible: Bool
    private let content: Content
    @GestureState private var isPressed = false

    public init(
        preset: GlowConfig = GlowConfig(),
        states: [GlowState],
        override: GlowConfig = GlowConfig(),
        activeState: GlowEvent = .default,
        isVisible: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            preset: preset,
            states: states,
            override: override,
            status: .manual(activeState),
            isVisible: isVisible,
            content: content
        )
    }

    public init(
        preset: GlowConfig = GlowConfig(),
        states: [GlowState],
        override: GlowConfig = GlowConfig(),
        status: GlowStatus,
        isVisible: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.preset = preset
        self.states = states
        self.override = override
        self.status = status
        self.isVisible = isVisible
        self.content = content()
    }

    public var body: some View {
        let resolved = GlowCompatibility.resolvedConfig(
            preset: preset,
            states: states,
            override: override,
            activeState: status.activeState(isPressed: isPressed)
        )

        let glowContent = content
            .background {
                GeometryReader { proxy in
                    MetalGlowView(
                        configuration: resolved,
                        isVisible: isVisible,
                        contentSize: proxy.size
                    )
                    .allowsHitTesting(false)
                    .frame(
                        width: proxy.size.width + MetalGlowView.margin * 2,
                        height: proxy.size.height + MetalGlowView.margin * 2
                    )
                    .offset(x: -MetalGlowView.margin, y: -MetalGlowView.margin)
                }
            }

        if status == .auto {
            glowContent.simultaneousGesture(pressGesture)
        } else {
            glowContent
        }
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isPressed) { _, isPressed, _ in
                isPressed = true
            }
    }
}

public extension View {
    func animatedGlow(
        preset: GlowConfig = GlowConfig(),
        states: [GlowState],
        override: GlowConfig = GlowConfig(),
        activeState: GlowEvent = .default,
        isVisible: Bool = true
    ) -> some View {
        AnimatedGlow(
            preset: preset,
            states: states,
            override: override,
            activeState: activeState,
            isVisible: isVisible
        ) {
            self
        }
    }

    func animatedGlow(
        preset: GlowConfig = GlowConfig(),
        states: [GlowState],
        override: GlowConfig = GlowConfig(),
        status: GlowStatus,
        isVisible: Bool = true
    ) -> some View {
        AnimatedGlow(
            preset: preset,
            states: states,
            override: override,
            status: status,
            isVisible: isVisible
        ) {
            self
        }
    }
}
