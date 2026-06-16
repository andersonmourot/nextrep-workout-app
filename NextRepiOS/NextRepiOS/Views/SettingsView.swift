import SwiftUI

struct SettingsView: View {
    @StateObject private var store = AppStore()
    @State private var displayName: String = ""
    @State private var selectedColorIndex: Int = 0
    @State private var selectedThemeMode: Theme.ThemeMode = .system
    @State private var selectedUnit: String = "lb"
    @State private var showingPrivacyPolicy: Bool = false
    @State private var showingTermsOfService: Bool = false
    @State private var showingDisclaimer: Bool = false
    @State private var showingAdminUsers: Bool = false
    @State private var showingAdminCatalog: Bool = false
    
    private var isAdmin: Bool {
        store.currentUser?.isAdmin ?? false
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Settings")
                        .font(Theme.display(32))
                        .foregroundColor(Theme.text)
                        .tracking(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
        }
        .onAppear {
            displayName = store.appData.name ?? ""
            if let themeColor = store.appData.themeColor {
                selectedColorIndex = Theme.THEME_COLORS.firstIndex(where: { $0.hex == themeColor }) ?? 0
            }
            selectedUnit = store.appData.unit
        }
        .navigationDestination(isPresented: $showingAdminUsers) {
            AdminUsersView()
        }
        .navigationDestination(isPresented: $showingAdminCatalog) {
            AdminCatalogView()
        }
        .navigationDestination(isPresented: $showingPrivacyPolicy) {
            LegalView(doc: .privacy)
        }
        .navigationDestination(isPresented: $showingTermsOfService) {
            LegalView(doc: .terms)
        }
        .navigationDestination(isPresented: $showingDisclaimer) {
            LegalView(doc: .disclaimer)
        }
    }
}