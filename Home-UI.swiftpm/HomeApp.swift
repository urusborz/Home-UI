import SwiftUI

@main
struct HomeApp: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(store.appAppearance.preferredColorScheme)
        }
    }
}
