# LinkDings Client

An iOS and macOS SwiftUI app for [Linkding](https://github.com/sissbruecker/linkding) with a Safari Web Extension.

## Features

- Browse, search, sort, and filter bookmarks by tag
- Add, edit, and delete bookmarks
- Safari extension for saving the current page with one tap
- Offline cache via SwiftData
- Dark mode support

## Requirements

- iOS 17+ / macOS 14+
- Xcode 16+
- A running [Linkding](https://github.com/sissbruecker/linkding) instance with an API token

## Setup

1. Open `LinkDings Client.xcodeproj` in Xcode
2. Add the **App Groups** capability to both targets (`LinkDings Client` and `LinkDings Client Extension`) and set the variable `appGroupID` in `SharedConstants.swift` to the App Group you created
3. Select your development team and build

## Configuration

On first launch, open **Settings** in the app and enter your Linkding instance URL and API token. These are shared with the Safari extension via App Groups.

If your instance is on a local network over HTTP, this is supported — no additional configuration required.

## Architecture

| Component          | Technology                    |
|--------------------|-------------------------------|
| App UI             | SwiftUI                       |
| Local cache        | SwiftData                     |
| Networking         | URLSession (async/await)      |
| Credential sharing | App Groups (`UserDefaults`)   |
| Safari extension   | Manifest V3, native messaging |

The Safari extension relays messages from its popup to `SafariWebExtensionHandler` (Swift), which makes all API calls natively. The API token is never exposed to JavaScript.
