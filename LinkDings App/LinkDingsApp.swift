import SwiftUI
import SwiftData

// When searching, do an on string change debounced search instead of waiting on enter
// When opening a bookmark's edit page, it should fetch the latest data from the server
// Clicking a bookmark should open it in the default web brower, long pressing should show a context menu
// Sort by unread first
// js popup is not centered
// Mark as unread should default to true (in js popup and app)
// If bookmark is already saved, alert user that adding this bookmark will replace the old bookmark (from safari extension)
// When editing/creating bookmark, list all current tags, with option to create new

@main
struct LinkDingsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CachedBookmark.self, CachedTag.self])
    }
}
