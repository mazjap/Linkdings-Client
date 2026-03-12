import SwiftUI

struct ContentView: View {
    @State private var isConfigured = KeychainHelper.isConfigured
    @State private var showSettings = false

    var body: some View {
        if isConfigured && !showSettings {
            BookmarkListView(showSettings: $showSettings)
                .onChange(of: showSettings) { _, showing in
                    if !showing { isConfigured = KeychainHelper.isConfigured }
                }
        } else {
            SettingsView(showSettings: $showSettings, isInitialSetup: !isConfigured)
                .onChange(of: showSettings) { _, showing in
                    if !showing { isConfigured = KeychainHelper.isConfigured }
                }
        }
    }
}
