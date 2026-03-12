import SwiftUI

struct ContentView: View {
    @State private var showSettings = !KeychainHelper.isConfigured

    var body: some View {
        BookmarkListView(showSettings: $showSettings)
            .sheet(isPresented: $showSettings) {
                SettingsView(showSettings: $showSettings)
            }
    }
}
