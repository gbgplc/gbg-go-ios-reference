# GBG Go iOS Reference — Part 2: Smart Capture SDK Integration

> **Branch:** `part-2-smart-capture` — builds on the [Part 1 reference](../../tree/main) (`main` branch) which covers core bridge integration with stub camera views.

A complete, runnable reference integration of the GBG Go identity verification journey in an iOS app using the GBGBridge SDK **with real Smart Capture SDKs** for document scanning and face capture with liveness detection.

This project demonstrates:
- Everything from Part 1 (journey URL, BridgeWebView, bridge protocol, stub cameras)
- **Replacing stub camera views with Smart Capture SDKs** using a compile-time flag
- **Document scanning** with guided capture, auto-crop, and quality scoring (`Document.xcframework`)
- **Face capture with liveness** detection and encrypted biometric blobs (`FaceCamera.xcframework`)
- Conditional compilation so the app works with or without the SDKs
- Simulator fallback to stubs (Smart Capture SDKs require camera hardware)

## What Changed from Part 1

The diff between `main` and this branch is intentionally small — the bridge architecture was designed so that swapping stubs for real SDKs is a minimal change:

| File | Change |
|------|--------|
| `Sources/Capture/SmartCaptureDocumentView.swift` | New — thin wrapper around Document SDK |
| `Sources/Capture/SmartCaptureFaceView.swift` | New — thin wrapper around FaceCamera SDK |
| `Sources/Journey/JourneyView.swift` | Modified — conditional compile at the swap points |
| `Frameworks/` | New — placeholder for Smart Capture SDK frameworks |

The handler setup, bridge wiring, `awaitCompletion()`/`complete()` pattern, server code, and all other files are unchanged.

## Prerequisites

- **Xcode 15+** (Swift 5.9)
- **iOS 16.0+** device or simulator
- **Node.js 18+** (for the companion server)
- **GBG Go account** with API credentials (client ID, client secret, username, password)
- **Smart Capture SDKs** (optional — obtained from your GBG account representative)

## Quick Start

### 1. Clone and check out Part 2

```bash
git clone https://github.com/gbgplc/gbg-go-ios-reference.git
cd gbg-go-ios-reference
git checkout part-2-smart-capture
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

### 5. Build and run (stubs mode)

Select an iOS Simulator (or device) and press **Cmd+R**. Without the Smart Capture SDKs, the app uses stub camera views — identical to Part 1.

### 6. Enable Smart Capture (optional)

See [Enabling Smart Capture](#enabling-smart-capture) below.

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
│   │   ├── Capture/                # Smart Capture SDK wrappers (Part 2)
│   │   ├── Settings/               # Configuration UI
│   │   └── Extensions/             # Bridge handler setup
│   ├── Frameworks/                 # Drop Smart Capture SDKs here
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
7. The app presents camera views and returns results:
   - **With Smart Capture:** Real document scanning and face capture with liveness
   - **Without Smart Capture:** Stub camera views (plain photos / placeholders)

## Enabling Smart Capture

The Smart Capture SDKs are **not included** in this repository. To enable real document scanning and face capture with liveness:

### 1. Obtain the frameworks

Contact your GBG account representative to obtain the following XCFramework bundles:

| Framework | Purpose |
|-----------|---------|
| `Document.xcframework` | Document scanning with guided capture |
| `FaceCamera.xcframework` | Face capture with liveness detection |
| `IDLiveFaceCamera.xcframework` | Runtime dependency of FaceCamera |
| `IDLiveFaceIAD.xcframework` | Runtime dependency of FaceCamera |

### 2. Add frameworks to the project

1. Place all four `.xcframework` bundles in `GBGGoReference/Frameworks/`
2. In Xcode, select the **GBGGoReference** target
3. Go to **General > Frameworks, Libraries, and Embedded Content**
4. Click **+**, then **Add Other > Add Files** and select each framework
5. Set each to **Embed & Sign**

### 3. Enable the compiler flag

1. In Xcode, select the **GBGGoReference** target
2. Go to **Build Settings** (make sure "All" is selected, not "Basic")
3. Search for **Active Compilation Conditions** (`SWIFT_ACTIVE_COMPILATION_CONDITIONS`)
4. Add `SMART_CAPTURE_ENABLED` to both Debug and Release

### 4. Build and run on device

Smart Capture SDKs require camera hardware — build and run on a **physical iOS device**:

```bash
# Or press Cmd+R in Xcode with a device selected
xcodebuild \
  -project GBGGoReference/GBGGoReference.xcodeproj \
  -scheme GBGGoReference \
  -destination 'generic/platform=iOS' \
  build
```

On Simulator, the app automatically falls back to stub camera views even with the flag enabled.

## Without Smart Capture

The app builds and runs without the Smart Capture SDKs — it behaves identically to the [Part 1 reference](../../tree/main) on `main`. This is the default state of the project:

- No frameworks needed in `Frameworks/`
- No compiler flags to set
- Stubs work on both Simulator and device
- Full bridge protocol flow is exercised end-to-end

## Building from the Command Line

```bash
# Default (stubs only)
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

## Branch Structure

| Branch | Content |
|--------|---------|
| `main` | Part 1 — Core bridge integration with stub camera views |
| `part-2-smart-capture` | Part 2 — Smart Capture SDK integration (this branch) |

To see exactly what Part 2 adds, diff the branches:

```bash
git diff main..part-2-smart-capture
```

## Next Steps

- [GBGBridge iOS Documentation](https://github.com/gbgplc/gbg-bridge-ios) — Full SDK reference
- **Android Reference** — Equivalent reference build for Android (coming soon)
