# GBG Go iOS Reference

A complete, runnable reference integration of the GBG Go identity verification journey in an iOS app using the GBGBridge SDK.

This project demonstrates:
- Obtaining a journey URL from your backend using the GBG Go Core SDK
- Loading the journey in a `BridgeWebView` with the GBGBridge iOS SDK
- Handling native capability requests (document capture, selfie capture) with stub camera views
- The full communication flow between the web journey and native host

## Prerequisites

- **Xcode 15+** (Swift 5.9)
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

Select an iOS Simulator (or device) and press **Cmd+R**. The app will launch with a settings screen where you can configure the companion server URL and start a journey.

## Project Structure

```
gbg-go-ios-reference/
├── server/                         # Companion Node.js server
│   ├── index.mjs                   # Express server using @gbg/go-core
│   ├── .env.example                # Credential template
│   └── README.md                   # Server setup guide
│
├── Packages/GBGBridge/             # GBGBridge SDK (local Swift Package)
│
├── GBGGoReference/                 # iOS app
│   ├── Sources/
│   │   ├── App/                    # App entry point, navigation
│   │   ├── Journey/                # BridgeWebView integration
│   │   ├── Capture/                # Stub camera views
│   │   ├── Settings/               # Configuration UI
│   │   └── Extensions/             # Bridge handler setup
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
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

## Switching to the Published SDK

When the GBGBridge SDK is published via SPM, replace the local package dependency:

1. In Xcode, remove the local `GBGBridge` package reference
2. Go to **File > Add Package Dependencies**
3. Enter the GBGBridge SPM URL: `https://github.com/gbgplc/gbg-bridge-ios.git`
4. Select your version requirement (e.g., "Up to Next Minor" from `1.0.0`)
5. Delete the `Packages/GBGBridge/` directory

## Next Steps

- [GBGBridge iOS Documentation](https://github.com/gbgplc/gbg-bridge-ios) — Full SDK reference
- **SmartCapture SDK Integration** — Replace stub camera views with production capture (coming soon)
- **Android Reference** — Equivalent reference build for Android (coming soon)
