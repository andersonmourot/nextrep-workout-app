import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255, opacity: 1)
    }
}

enum Theme {
    enum ThemeMode: String, CaseIterable {
        case system = "system"
        case light = "light"
        case dark = "dark"
    }
    
    // Surfaces
    static let bg       = Color(hex: 0x08080A)  // ink-950
    static let input    = Color(hex: 0x0D0D10)  // ink-900
    static let surface  = Color(hex: 0x141417)  // ink-850 (cards)
    static let surface2 = Color(hex: 0x1B1B1F)  // ink-800 (ghost/chips)
    static let hover    = Color(hex: 0x26262B)  // ink-700
    // Text
    static let text     = Color(hex: 0xFAFAFA)  // zinc-50 (titles)
    static let text2    = Color(hex: 0xF4F4F5)  // zinc-100 (body)
    static let textDim  = Color(hex: 0xA1A1AA)  // zinc-400
    static let faint    = Color(hex: 0x71717A)  // zinc-500 (placeholder)
    static let inputBg  = Color(hex: 0x0D0D10)  // ink-900 (same as input)
    static let placeholder = Color(hex: 0x71717A)  // zinc-500
    static var accentHex = "355E3B"
    // Accent (override base/lt/dk at runtime from themeColor)
    static var accent   = Color(hex: 0x355E3B)
    static var accentLt = Color(hex: 0x4C8A55)
    static var accentDk = Color(hex: 0x284A30)
    
    static let THEME_COLORS = [
        (name: "Gold", hex: "355E3B"),
        (name: "Blue", hex: "3B82F6"),
        (name: "Purple", hex: "8B5CF6"),
        (name: "Pink", hex: "EC4899"),
        (name: "Orange", hex: "F97316"),
        (name: "Teal", hex: "14B8A6")
    ]
    
    static func setAccent(from colorString: String) {
        if let hex = UInt(colorString.replacingOccurrences(of: "#", with: ""), radix: 16) {
            accent = Color(hex: hex)
            accentLt = Color(hex: hex).opacity(1.3)
            accentDk = Color(hex: hex).opacity(0.8)
            accentHex = colorString.replacingOccurrences(of: "#", with: "")
        }
    }

    static func display(_ s: CGFloat, _ w: Font.Weight = .bold) -> Font {
        .custom(w == .bold ? "Oswald-Bold" : w == .semibold ? "Oswald-SemiBold" : "Oswald-Medium", size: s)
    }
    static func body(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font {
        let n = w == .bold ? "Inter-Bold" : w == .semibold ? "Inter-SemiBold"
              : w == .medium ? "Inter-Medium" : "Inter-Regular"
        return .custom(n, size: s)
    }
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = 20            // p-5; pass 16 for p-4 rows
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1))
            .overlay(alignment: .top) {                       // inset top hairline
                Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .shadow(color: .black.opacity(0.55), radius: 12, x: 0, y: 8)
    }
}
extension View {
    func cardStyle(_ padding: CGFloat = 20) -> some View { modifier(CardStyle(padding: padding)) }
    func eyebrow() -> some View {                            // .label-eyebrow
        self.font(Theme.body(11, .semibold)).textCase(.uppercase)
            .tracking(2.2).foregroundStyle(Theme.accent.opacity(0.8))
    }
    func screenTitle() -> some View {                        // h1
        self.font(Theme.display(30)).textCase(.uppercase)
            .tracking(0.5).foregroundStyle(Theme.text)
    }
    func sectionTitle() -> some View {                       // h2
        self.font(Theme.display(18)).textCase(.uppercase)
            .tracking(0.5).foregroundStyle(Theme.text)
    }
}

struct PrimaryButton: ButtonStyle {        // .btn-gold
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(14, .semibold)).foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 10).frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Theme.accentLt : Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
struct GhostButton: ButtonStyle {          // .btn-ghost
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(14, .semibold)).foregroundStyle(Theme.text2)
            .padding(.horizontal, 16).padding(.vertical, 10).frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Theme.hover : Theme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
struct OutlineButton: ButtonStyle {        // .btn-outline
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.body(14, .semibold)).foregroundStyle(Theme.accent)
            .padding(.horizontal, 16).padding(.vertical, 10).frame(maxWidth: .infinity)
            .background((configuration.isPressed ? Theme.accent.opacity(0.1) : .clear))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct ChipStyle: ViewModifier {           // .chip
    func body(content: Content) -> some View {
        content.font(Theme.body(11, .medium)).foregroundStyle(Theme.text.opacity(0.84))
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Theme.surface2)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
extension View { func chip() -> some View { modifier(ChipStyle()) } }

struct AppTextFieldStyle: ViewModifier {   // .input
    func body(content: Content) -> some View {
        content.font(Theme.body(16)).foregroundStyle(Theme.text2)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Theme.input)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
extension View { func appField() -> some View { modifier(AppTextFieldStyle()) } }

// MARK: - Screen Shell Components (temporary location)
struct ScreenWrapper<Content: View>: View {
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 6
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            // Two top radial glows
            RadialGradient(
                gradient: Gradient(colors: [
                    Theme.accent.opacity(0.12),
                    Color.clear
                ]),
                center: UnitPoint(x: 0.5, y: -0.1),
                startRadius: 80 * UIScreen.main.bounds.width / 414,
                endRadius: 40 * UIScreen.main.bounds.width / 414
            )
            .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [
                    Theme.accent.opacity(0.07),
                    Color.clear
                ]),
                center: UnitPoint(x: 1.0, y: 0.0),
                startRadius: 60 * UIScreen.main.bounds.width / 414,
                endRadius: 30 * UIScreen.main.bounds.width / 414
            )
            .ignoresSafeArea()
            
            // Content with max-width and padding
            content
                .frame(maxWidth: 448)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .opacity(opacity)
                .offset(y: offset)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                opacity = 1
                offset = 0
            }
        }
    }
}

struct TopHeader: View {
    let onSettingsTap: () -> Void
    
    init(onSettingsTap: @escaping () -> Void = {}) {
        self.onSettingsTap = onSettingsTap
    }
    
    var body: some View {
        HStack {
            // NextRep logo (text for now)
            Text("NextRep")
                .font(Theme.display(20))
                .foregroundColor(Theme.text)
                .tracking(1)
            
            Spacer()
            
            // Settings icon button
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Theme.textDim)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color(hex: 0x08080A).opacity(0.8))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: Int
    let onTabTap: (Int) -> Void
    
    let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("dumbbell.fill", "Programs"),
        ("timer", "Timer"),
        ("magnifyingglass", "Search"),
        ("person.fill", "Profile")
    ]
    
    init(selectedTab: Binding<Int>, onTabTap: @escaping (Int) -> Void = { _ in }) {
        self._selectedTab = selectedTab
        self.onTabTap = onTabTap
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: { onTabTap(index) }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 20))
                            .foregroundColor(selectedTab == index ? Theme.accent : Theme.faint)
                            .shadow(
                                color: Theme.accentLt.opacity(0.6),
                                radius: selectedTab == index ? 6 : 0
                            )
                        
                        Text(tabs[index].label)
                            .font(Theme.body(11, .medium))
                            .foregroundColor(selectedTab == index ? Theme.accent : Theme.faint)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(hex: 0x0D0D10).opacity(0.9))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct ResumeWorkoutBanner: View {
    let onResume: () -> Void
    
    init(onResume: @escaping () -> Void = {}) {
        self.onResume = onResume
    }
    
    var body: some View {
        Button(action: onResume) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                
                Text("Resume workout")
                    .font(Theme.body(14, .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
    }
}

struct ProgramCardGradient: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.accent.opacity(0.12),
                        Color.clear
                    ]),
                    startPoint: UnitPoint(x: 0.0, y: 0.0),
                    endPoint: UnitPoint(x: 0.87, y: 1.0)
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func programCardGradient() -> some View { modifier(ProgramCardGradient()) }
}