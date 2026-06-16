import SwiftUI

// MARK: - Screen Wrapper
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

// MARK: - Top Header
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

// MARK: - Bottom Tab Bar
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

// MARK: - Resume Workout Banner
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

// MARK: - Program Card with Gradient
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