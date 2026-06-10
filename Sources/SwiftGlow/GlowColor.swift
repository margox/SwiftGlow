import Foundation

public struct GlowColor: Equatable, Sendable {
    public var red: Float
    public var green: Float
    public var blue: Float
    public var alpha: Float

    public init(red: Float, green: Float, blue: Float, alpha: Float = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init(red255: Int, green255: Int, blue255: Int, alpha: Float = 1) {
        self.red = Float(red255) / 255
        self.green = Float(green255) / 255
        self.blue = Float(blue255) / 255
        self.alpha = alpha
    }

    public static let clear = GlowColor(red: 0, green: 0, blue: 0, alpha: 0)
    public static let white = GlowColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let black = GlowColor(red: 0, green: 0, blue: 0, alpha: 1)
}

public extension GlowColor {
    init(css string: String) {
        self = GlowColorParser.parse(string)
    }
}

enum GlowColorParser {
    static func parse(_ string: String?) -> GlowColor {
        guard let raw = string?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return .clear
        }
        if raw.lowercased() == "transparent" {
            return .clear
        }
        if let namedColor = parseNamedColor(raw) {
            return namedColor
        }
        if let rgba = parseRGBFunction(raw) {
            return rgba
        }
        if let hex = parseHex(raw) {
            return hex
        }
        return .clear
    }

    private static func parseNamedColor(_ string: String) -> GlowColor? {
        switch string.lowercased() {
        case "black":
            return .black
        case "white":
            return .white
        default:
            return nil
        }
    }

    private static func parseRGBFunction(_ string: String) -> GlowColor? {
        let lower = string.lowercased()
        guard lower.hasPrefix("rgb(") || lower.hasPrefix("rgba("),
              let open = lower.firstIndex(of: "("),
              let close = lower.lastIndex(of: ")") else {
            return nil
        }
        let body = lower[lower.index(after: open)..<close]
        let parts = body
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count >= 3,
              let red = Int(parts[0]),
              let green = Int(parts[1]),
              let blue = Int(parts[2]) else {
            return nil
        }

        let alpha = parts.count >= 4 ? Float(parts[3]) ?? 1 : 1
        return GlowColor(
            red255: clamp255(red),
            green255: clamp255(green),
            blue255: clamp255(blue),
            alpha: max(0, min(1, alpha))
        )
    }

    private static func parseHex(_ string: String) -> GlowColor? {
        var hex = string
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        guard hex.count == 6 || hex.count == 8,
              let value = UInt32(hex, radix: 16) else {
            return nil
        }

        if hex.count == 8 {
            return GlowColor(
                red255: Int((value >> 24) & 0xff),
                green255: Int((value >> 16) & 0xff),
                blue255: Int((value >> 8) & 0xff),
                alpha: Float(value & 0xff) / 255
            )
        }

        return GlowColor(
            red255: Int((value >> 16) & 0xff),
            green255: Int((value >> 8) & 0xff),
            blue255: Int(value & 0xff)
        )
    }

    private static func clamp255(_ value: Int) -> Int {
        max(0, min(255, value))
    }
}
