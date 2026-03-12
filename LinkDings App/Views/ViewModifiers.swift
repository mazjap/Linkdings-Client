import SwiftUI

extension View {
    /// Applies URL keyboard type and disables autocapitalization on iOS.
    func urlTextFieldStyle() -> some View {
        self
            .autocorrectionDisabled()
#if os(iOS)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
#endif
    }

    /// Disables autocapitalization on iOS.
    func noAutocapitalization() -> some View {
        self
            .autocorrectionDisabled()
#if os(iOS)
            .textInputAutocapitalization(.never)
#endif
    }
}
