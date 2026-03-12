import SwiftUI

struct ContentView: View {
    @State private var showSettings = !KeychainHelper.isConfigured

    var body: some View {
        Group {
            if KeychainHelper.isConfigured && !showSettings {
                BookmarkListView(showSettings: $showSettings)
            } else {
                SettingsView(showSettings: $showSettings, isInitialSetup: !KeychainHelper.isConfigured)
            }
        }
    }
}
