# GBG Go iOS Reference — Part 2: Smart Capture SDK Integration

> **Branch:** `part-2-smart-capture` — builds on the [Part 1 reference](../../tree/main) (`main` branch) which covers core bridge integration with stub camera views.

A complete, runnable reference integration of the GBG Go identity verification journey in an iOS app using the [GBGBridge iOS SDK](https://github.com/gbgplc/gbg-go-ios-sdk) (v1.2.0, added via Swift Package Manager) **with real Smart Capture SDKs** for document scanning and face capture with liveness detection.

This project demonstrates:
- Everything from Part 1 (journey URL, BridgeWebView, bridge protocol, stub cameras)
- **Replacing stub camera views with Smart Capture SDKs** using a compile-time flag
- **Document scanning** with guided capture, auto-crop, and quality scoring (`Document.xcframework`)
- **Face capture with liveness** detection and encrypted biometric blobs (`FaceCamera.xcframework`)
- **Passport chip reading** over NFC through the GBGBridge `nfcRead` slot (`OzoneNFC.xcframework`)
- Conditional compilation so the app works with or without the SDKs
- Simulator fallback to stubs (Smart Capture SDKs require camera hardware)

## What Changed from Part 1

The diff between `main` and this branch is intentionally small — the bridge architecture was designed so that swapping stubs for real SDKs is a minimal change:

| File | Change |
|------|--------|
| `Sources/Capture/SmartCaptureDocumentView.swift` | New — thin wrapper around Document SDK |
| `Sources/Capture/SmartCaptureFaceView.swift` | New — thin wrapper around FaceCamera SDK |
| `Sources/Capture/SmartCaptureChipReaderView.swift` | New: thin wrapper around the Ozone NFC reader, mapping its result to `NfcReadResult` |
| `Sources/Journey/JourneyView.swift` | Modified: conditional compile at the swap points, plus the `nfcRead` slot and chip reader sheet |
| `Resources/Info.plist` | Modified: NFC usage description and the passport application identifier |
| `Frameworks/` | New — placeholder for Smart Capture SDK frameworks |

The handler setup, bridge wiring, `awaitCompletion()`/`complete()` pattern, server code, and all other files are unchanged.

## Prerequisites

- **Xcode 16.2+** (the GBGBridge binary is built with Swift 6.0.3)
- **iOS 16.0+** device or simulator
- **Node.js 18+** (for the companion server)
- **GBG Go account** with API credentials (client ID, client secret, username, password)
- **Smart Capture SDKs** (optional — obtained from your GBG account representative)
- **An iPhone with NFC** for chip reading (iPads and the Simulator have no chip reader)

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

Xcode resolves the GBGBridge package from GitHub on first open (pinned to 1.2.0 in `Package.resolved`). Select an iOS Simulator (or device) and press **Cmd+R**. Without the Smart Capture SDKs, the app uses stub camera views — identical to Part 1.

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
├── GBGGoReference/                 # iOS app
│   ├── GBGGoReference.xcodeproj    # SPM dependency on gbg-go-ios-sdk (GBGBridge 1.2.0)
│   ├── Sources/
│   │   ├── App/                    # App entry point, navigation
│   │   ├── Journey/                # BridgeWebView integration + camera swap points
│   │   ├── Capture/                # Smart Capture SDK wrappers (Part 2)
│   │   └── Settings/               # Configuration UI
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
   - **With Smart Capture:** Real document scanning, face capture with liveness, and passport chip reading
   - **Without Smart Capture:** Stub camera views (plain photos / placeholders); chip reading is reported as unsupported

## Enabling Smart Capture

The Smart Capture SDKs are **not included** in this repository. To enable real document scanning, face capture with liveness and passport chip reading:

### 1. Obtain the frameworks

Contact your GBG account representative to obtain the Smart Capture iOS XCFramework bundles (this reference was checked against Smart Capture 1.7.0):

| Framework | Purpose |
|-----------|---------|
| `Document.xcframework` | Document scanning with guided capture |
| `IDSCamera.xcframework` | Runtime dependency of Document |
| `FaceCamera.xcframework` | Face capture with liveness detection |
| `IDLiveFaceCamera.xcframework` | Runtime dependency of FaceCamera |
| `IDLiveFaceIAD.xcframework` | Runtime dependency of FaceCamera |
| `OzoneNFC.xcframework` | Passport chip reading over NFC |

Two open-source packages are also required at runtime. Add them with **File > Add Package Dependencies**, pinned to the exact versions the SDKs were built against:

| Package | Version | Needed by |
|---------|---------|-----------|
| `https://github.com/airbnb/lottie-spm.git` | `4.6.0` (exact) | Document |
| `https://github.com/krzyzanowskim/OpenSSL.git` | `3.6.3000` (exact) | OzoneNFC |

### 2. Add frameworks to the project

1. Place all six `.xcframework` bundles in `GBGGoReference/Frameworks/` (the folder is gitignored for `.xcframework` bundles)
2. In Xcode, select the **GBGGoReference** target
3. Go to **General > Frameworks, Libraries, and Embedded Content**
4. Click **+**, then **Add Other > Add Files** and select each framework
5. Set each to **Embed & Sign**

### 3. Add the NFC capability

Chip reading uses Core NFC, which needs an entitlement:

1. In Xcode, select the **GBGGoReference** target, then **Signing & Capabilities**
2. Click **+ Capability** and add **Near Field Communication Tag Reading**

The two Info.plist entries chip reading needs (`NFCReaderUsageDescription` and the passport application identifier `A0000002471001` under `com.apple.developer.nfc.readersession.iso7816.select-identifiers`) are already in `Resources/Info.plist`.

### 4. Enable the compiler flag

1. In Xcode, select the **GBGGoReference** target
2. Go to **Build Settings** (make sure "All" is selected, not "Basic")
3. Search for **Active Compilation Conditions** (`SWIFT_ACTIVE_COMPILATION_CONDITIONS`)
4. Add `SMART_CAPTURE_ENABLED` to both Debug and Release

### 5. Build and run on device

Smart Capture SDKs require camera hardware, and chip reading needs an NFC reader. Build and run on a **physical iPhone**:

```bash
# Or press Cmd+R in Xcode with a device selected
xcodebuild \
  -project GBGGoReference/GBGGoReference.xcodeproj \
  -scheme GBGGoReference \
  -destination 'generic/platform=iOS' \
  build
```

On Simulator, the app automatically falls back to stub camera views even with the flag enabled, and chip reading is reported as unsupported.

### How chip reading works

GBGBridge 1.2.0 adds a third typed slot, `host.nfcRead`, alongside `documentCapture` and `selfieCapture`. It follows the same `awaitCompletion()` / `complete()` pattern. The app does two things:

- Tells the SDK whether this device can read a chip: `host.nfcRead.deviceCanRead = { NFCTagReaderSession.readingAvailable }`. The SDK does not link Core NFC, so without this the slot reports chip reading as unsupported.
- Runs the Ozone reader when a request arrives and hands back what it read. `SmartCaptureChipReaderView` builds the reader from the request's document number, date of birth and date of expiry, then maps the result: every data group the chip returned as `NfcReadFile`s, and the BAC, PACE, chip authentication, active authentication and passive authentication outcomes as `NfcAuthCheck`s.

The SDK does the rest: validating the request, answering busy and unsupported states, and shaping the response the web journey expects. The reader is presented as a sheet rather than a full-screen cover, so the person can always swipe it away; dismissing it answers the read as cancelled.

## Without Smart Capture

The app builds and runs without the Smart Capture SDKs — it behaves identically to the [Part 1 reference](../../tree/main) on `main`. This is the default state of the project:

- No frameworks needed in `Frameworks/`
- No compiler flags to set
- Stubs work on both Simulator and device
- Chip reading is reported as unsupported, so the web journey offers its own alternative (there is no stub reader)
- Full bridge protocol flow is exercised end-to-end

## Building from the Command Line

```bash
# Default (stubs only)
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

- [GBGBridge iOS SDK](https://github.com/gbgplc/gbg-go-ios-sdk): SDK repository and releases
- **Android Reference** — Equivalent reference build for Android (coming soon)
