import SwiftUI

@main
struct MomentumAIWorkCoachApp: App {
    @State private var storage = StorageService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storage)
        }
    }
}
