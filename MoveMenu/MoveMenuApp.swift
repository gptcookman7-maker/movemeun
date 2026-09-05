import SwiftUI

@main
struct MoveMenuApp: App {
    @State private var store = AppStore()
    @State private var health = HealthService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(health)
                .tint(.teal)
        }
    }
}
