import SwiftUI
import SwiftData

@main
struct LinkDingsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CachedBookmark.self, CachedTag.self])
    }
}
