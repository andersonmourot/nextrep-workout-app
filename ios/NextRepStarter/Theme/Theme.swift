import SwiftUI

enum Theme {
    static let bg = Color(hex: "#08080A")
    static let surface = Color(hex: "#141417")
    static let surface2 = Color(hex: "#1B1B1F")
    static let surface3 = Color(hex: "#26262B")
    static let inputBg = Color(hex: "#0D0D10")
    static let text = Color(hex: "#F4F4F5")
    static let textDim = Color(hex: "#A1A1AA")
    static let textFaint = Color(hex: "#71717A")
    static let accent = Color(hex: "#355E3B")
    static let accentLight = Color(hex: "#4C8A55")
}

extension Color {
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

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.05), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.6), radius: 12, y: 8)
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
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
