# GBG Go iOS Reference

A complete, runnable reference integration of the GBG Go identity verification journey in an iOS app using the [GBGBridge iOS SDK](https://github.com/gbgplc/gbg-go-ios-sdk) (v1.2.0, added via Swift Package Manager).

This project demonstrates:
- Obtaining a journey URL from your backend using the GBG Go Core SDK
- Loading the journey in a `BridgeWebView` with the GBGBridge iOS SDK
- Handling native capability requests (document capture, selfie capture) with stub camera views
- The full communication flow between the web journey and native host

## Prerequisites

- **Xcode 16.2+** (the GBGBridge binary is built with Swift 6.0.3)
- **iOS 16.0+** device or simulator
- **Node.js 18+** (for the companion server)
- **GBG Go account** with API credentials (client ID, client secret, username, password)

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/gbgplc/gbg-go-ios-reference.git
cd gbg-go-ios-reference
```

### 2. Set up the companion server

```bash
cd server
npm install
cp .env.example .env
# Edit .env with your GBG Go API credentials
```

### 3. Start the server

```bash
node index.mjs
# Server starts at http://localhost:3000
```

### 4. Open the iOS project

```bash
open GBGGoReference/GBGGoReference.xcodeproj
```

### 5. Build and run

Xcode resolves the GBGBridge package from GitHub on first open (pinned to 1.2.0 in `Package.resolved`). Select an iOS Simulator (or device) and press **Cmd+R**. The app will launch with a settings screen where you can configure the companion server URL and start a journey.

## Project Structure

```
gbg-go-ios-reference/
├── server/                         # Companion Node.js server
│   ├── index.mjs                   # Express server using @gbg/go-core
│   ├── .env.example                # Credential template
│   └── README.md                   # Server setup guide
│
├── GBGGoReference/                 # iOS app
│   ├── GBGGoReference.xcodeproj    # SPM dependency on gbg-go-ios-sdk (GBGBridge 1.2.0)
│   ├── Sources/
│   │   ├── App/                    # App entry point, navigation
│   │   ├── Journey/                # BridgeWebView integration + stub camera swap points
│   │   └── Settings/               # Configuration UI
│   └── Resources/                  # Assets, Info.plist
│
└── docs/                           # Development notes
```

## How It Works

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   iOS App    │──1──▸ │  Companion   │──2──▸ │ GBG Go Core  │
│              │       │   Server     │       │    SDK       │
│              │◂──4── │              │◂──3── │              │
└──────┬───────┘       └──────────────┘       └──────────────┘
       │
       │ 5. Load journey URL in BridgeWebView
       ▼
┌──────────────┐
│  Web Journey │──6──▸ Requests native capabilities (camera, etc.)
│  (WKWebView) │◂──7── Receives capture results from native views
└──────────────┘
```

1. The iOS app calls the companion server to start a journey
2. The server uses `@gbg/go-core` to create a session
3. The Core SDK returns an instance ID and journey URL
4. The server returns the URL to the iOS app
5. The app loads the URL in a `BridgeWebView`
6. The web journey requests native capabilities via the bridge protocol
7. The app presents stub camera views and returns results

## Building from the Command Line

```bash
xcodebuild \
  -project GBGGoReference/GBGGoReference.xcodeproj \
  -scheme GBGGoReference \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

## SDK Dependency

The GBGBridge SDK is pulled in as a Swift Package Manager dependency on [`gbgplc/gbg-go-ios-sdk`](https://github.com/gbgplc/gbg-go-ios-sdk), distributed as a pre-built XCFramework. The project uses "Up to Next Major Version" from `1.2.0`, and `Package.resolved` pins the exact release.

To move to a newer release:

1. In Xcode, select the project, then **Package Dependencies**
2. Edit the `gbg-go-ios-sdk` rule's minimum version to the new release
3. **File > Packages > Update to Latest Package Versions**
4. Commit the updated `project.pbxproj` and `Package.resolved`

Release notes and checksums are on the [SDK releases page](https://github.com/gbgplc/gbg-go-ios-sdk/releases).

## Next Steps

- [GBGBridge iOS SDK](https://github.com/gbgplc/gbg-go-ios-sdk): SDK repository and releases
- **SmartCapture SDK Integration** — Replace stub camera views with production capture (coming soon)
- **Android Reference** — Equivalent reference build for Android (coming soon)
