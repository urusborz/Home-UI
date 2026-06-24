import SwiftUI

@main
struct LesariaApp: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(store.appAppearance.preferredColorScheme)
        }
    }
}
