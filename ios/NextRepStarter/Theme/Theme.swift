import SwiftUI
import UIKit

enum Theme {
    static let accentStorageKey = "nextrep.themeColor"
    static let defaultAccentHex = "#355e3b"

    static let bg = Color(light: "#F7F7F4", dark: "#08080A")
    static let surface = Color(light: "#FFFFFF", dark: "#141417")
    static let surface2 = Color(light: "#F0F0EC", dark: "#1B1B1F")
    static let surface3 = Color(light: "#E5E5DF", dark: "#26262B")
    static let inputBg = Color(light: "#FFFFFF", dark: "#0D0D10")
    static let text = Color(light: "#18181B", dark: "#F4F4F5")
    static let textDim = Color(light: "#52525B", dark: "#A1A1AA")
    static let textFaint = Color(light: "#71717A", dark: "#71717A")
    static let border = Color(light: "#D4D4D0", dark: "#FFFFFF").opacity(0.10)
    static var accent: Color { .accentColor }
    static var accentLight: Color { .accentColor }
    static var accentDark: Color { .accentColor }

    private static var currentAccentHex: String {
        UserDefaults.standard.string(forKey: accentStorageKey) ?? defaultAccentHex
    }

    private static func mixHex(_ base: String, toward target: String, amount: Double) -> String {
        let a = rgb(base)
        let b = rgb(target)
        let mixed = (
            r: Int((Double(a.r) + (Double(b.r) - Double(a.r)) * amount).rounded()),
            g: Int((Double(a.g) + (Double(b.g) - Double(a.g)) * amount).rounded()),
            b: Int((Double(a.b) + (Double(b.b) - Double(a.b)) * amount).rounded())
        )
        return String(format: "#%02X%02X%02X", mixed.r, mixed.g, mixed.b)
    }

    private static func rgb(_ hex: String) -> (r: Int, g: Int, b: Int) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let expanded = clean.count == 3
            ? clean.map { "\($0)\($0)" }.joined()
            : clean
        var value: UInt64 = 0
        Scanner(string: expanded).scanHexInt64(&value)
        return (
            r: Int((value >> 16) & 0xFF),
            g: Int((value >> 8) & 0xFF),
            b: Int(value & 0xFF)
        )
    }
}

extension Color {
    init(light: String, dark: String) {
        self.init(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64

        switch clean.count {
        case 3:
            red = (value >> 8) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
            alpha = 255
        case 6:
            red = value >> 16
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
            alpha = 255
        case 8:
            red = value >> 24
            green = (value >> 16) & 0xFF
            blue = (value >> 8) & 0xFF
            alpha = value & 0xFF
        default:
            red = 244
            green = 244
            blue = 245
            alpha = 255
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64

        switch clean.count {
        case 3:
            red = (value >> 8) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
            alpha = 255
        case 6:
            red = value >> 16
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
            alpha = 255
        case 8:
            red = value >> 24
            green = (value >> 16) & 0xFF
            blue = (value >> 8) & 0xFF
            alpha = value & 0xFF
        default:
            red = 244
            green = 244
            blue = 245
            alpha = 255
        }

        self.init(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: CGFloat(alpha) / 255
        )
    }
}

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.6 : 0.10), radius: 12, y: 8)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func screenBackground() -> some View {
        background {
            ZStack(alignment: .top) {
                Theme.bg.ignoresSafeArea()
                RadialGradient(
                    colors: [Theme.accent.opacity(0.14), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 280
                )
                .ignoresSafeArea()
            }
            .allowsHitTesting(false)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .background(Theme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
