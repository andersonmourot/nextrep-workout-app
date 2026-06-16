import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if store.user == nil {
                AuthView()
            } else {
                AppShellView()
            }
        }
        .task {
            await store.restoreSession()
        }
        .overlay {
            if store.isLoading {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    ProgressView()
                        .tint(Theme.accentLight)
                        .padding(24)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }
}

struct AppShellView: View {
    var body: some View {
        TabView {
            NavigationStack {
                PlaceholderView(title: "Home", systemImage: "house")
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                ProgramsListView()
            }
            .tabItem {
                Label("Programs", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                PlaceholderView(title: "Timer", systemImage: "timer")
            }
            .tabItem {
                Label("Timer", systemImage: "timer")
            }

            NavigationStack {
                PlaceholderView(title: "Search", systemImage: "magnifyingglass")
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }

            NavigationStack {
                PlaceholderView(title: "Profile", systemImage: "person")
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .tint(Theme.accentLight)
    }
}

struct PlaceholderView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Theme.accentLight)

            Text(title)
                .font(.system(.largeTitle, design: .default, weight: .semibold))
                .foregroundStyle(Theme.text)

            Text("This screen is mapped in docs/ios-swiftui-screens.md and is ready for the next phase.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textDim)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
    }
}
