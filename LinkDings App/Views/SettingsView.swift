import SwiftUI

struct SettingsView: View {
    @Binding private var showSettings: Bool
    private let isInitialSetup = !KeychainHelper.isConfigured
    
    @State private var instanceURL = ""
    @State private var apiKey = ""
    @State private var isTesting = false
    @State private var testResult: String? = nil
    @State private var testSuccess = false
    
    init(showSettings: Binding<Bool>) {
        self._showSettings = showSettings
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://linkding.example.com", text: $instanceURL)
                        .urlTextFieldStyle()
                } header: {
                    Text("Linkding Instance URL")
                } footer: {
                    Text("The base URL of your Linkding instance.")
                }
                
                Section {
                    SecureField("API Token", text: $apiKey)
                        .noAutocapitalization()
                } header: {
                    Text("API Token")
                } footer: {
                    Text("Found in Linkding under Settings → Integrations → REST API.")
                }
                
                Section {
                    Button {
                        Task { await testConnection() }
                    } label: {
                        HStack {
                            Text("Test Connection")
                            Spacer()
                            if isTesting {
                                ProgressView()
                            } else if let _ = testResult {
                                Image(systemName: testSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(testSuccess ? .green : .red)
                            }
                        }
                    }
                    .disabled(instanceURL.isEmpty || apiKey.isEmpty || isTesting)
                    
                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(testSuccess ? .green : .red)
                    }
                }
                
                Section {
                    Button("Save") { save() }
                        .disabled(instanceURL.isEmpty || apiKey.isEmpty)
                }
            }
            .navigationTitle(isInitialSetup ? "Welcome to LinkDings" : "Settings")
            .toolbar {
                if !isInitialSetup {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showSettings = false }
                    }
                }
            }
            .onAppear { loadExisting() }
        }
        .interactiveDismissDisabled()
    }
    
    private func loadExisting() {
        instanceURL = KeychainHelper.instanceURL ?? ""
        apiKey = KeychainHelper.apiKey ?? ""
    }
    
    private func testConnection() async {
        var urlString = instanceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if urlString.hasSuffix("/") { urlString = String(urlString.dropLast()) }
        guard let url = URL(string: urlString) else {
            testResult = "Invalid URL"
            testSuccess = false
            return
        }
        isTesting = true
        testResult = nil
        let api = LinkdingAPI(baseURL: url, apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
        do {
            _ = try await api.fetchBookmarks(limit: 1)
            testResult = "Connected successfully"
            testSuccess = true
        } catch {
            testSuccess = false
        }
        isTesting = false
    }
    
    private func save() {
        var urlString = instanceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if urlString.hasSuffix("/") { urlString = String(urlString.dropLast()) }
        KeychainHelper.instanceURL = urlString
        KeychainHelper.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        showSettings = false
    }
}
