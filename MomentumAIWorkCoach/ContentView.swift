import SwiftUI

struct ContentView: View {
    @Environment(StorageService.self) private var storage
    @State private var showSplash: Bool = true
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                TabView(selection: $selectedTab) {
                    Tab("Home", systemImage: "house.fill", value: 0) {
                        HomeView()
                    }
                    Tab("Wins", systemImage: "star.fill", value: 1) {
                        WinsView()
                    }
                    Tab("Settings", systemImage: "slider.horizontal.3", value: 2) {
                        SettingsView()
                    }
                }
                .tint(Theme.primaryTeal)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showSplash = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToWinsTab)) { _ in
            selectedTab = 1
        }
    }
}
