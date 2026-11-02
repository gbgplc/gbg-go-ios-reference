# Tutorial Notes

Internal notes for transforming this reference build into the end-to-end linear tutorial (`docs/public/ios/tutorial.md`).

## Step-to-Section Mapping

| Reference Build Step | Tutorial Section | Key Content |
|---|---|---|
| Server setup | "Set Up the Backend" | Install Node.js, clone repo, configure `.env`, start server. Show the curl test. |
| Xcode project creation | "Create Your iOS Project" | File > New Project in Xcode. Add GBGBridge via SPM (`https://github.com/gbgplc/gbg-go-ios-sdk`, from 1.2.0). Configure Info.plist. |
| GBGGoReferenceApp.swift | "App Entry Point" | Standard `@main` — nothing special needed here. Brief mention. |
| RootView.swift | "Navigation Setup" | NavigationStack with programmatic path. Explain the flow. |
| SetupView.swift | "Configuration Screen" | Form with server URL and resource ID. AppStorage for persistence. |
| JourneyService.swift | "Calling Your Backend" | URLSession POST, error handling, response decoding. Include the full code. |
| JourneyView.swift | "The Bridge Integration" | **This is the core section.** BridgeHost init, handler assignment, BridgeWebView, fullScreenCover + onChange pattern. |
| Stub camera views | "Handling Capture Requests" | Explain the SDK's built-in stubs. Show the onCaptured/onCancelled callbacks. Mark the swap point. |

## Additional Prose Needed

1. **Introduction** — What the app does, what they'll learn, expected result (2 paragraphs).
2. **Prerequisites** — Same as README but with more detail on where to get GBG credentials.
3. **How the Bridge Works** — 1-2 paragraphs explaining the protocol at a high level before diving into code. Reference the Concepts page for deeper understanding.
4. **The Typed Slot Pattern** — A dedicated callout box explaining why `awaitCompletion()` exists and how the suspension/resume pattern integrates with SwiftUI's `fullScreenCover`. This is the conceptual heart of the integration.
5. **What's Next** — Pointers to SmartCapture SDK guide, NFC guide, UIKit integration, and the full API reference.

## Screenshots to Capture

1. The Setup screen with default values
2. The Setup screen showing a loading state
3. A journey running in the WebView
4. The stub document camera appearing as a fullScreenCover
5. The Xcode project navigator showing the file structure

## Common Pitfalls to Call Out

1. **Simulator vs Device**: `http://localhost:3000` only works in the Simulator. On a device, use your Mac's IP address.
2. **App Transport Security**: If you forget `NSAllowsLocalNetworking`, HTTP requests to the companion server will silently fail.
3. **Camera on Simulator**: The Simulator has no camera — the stub views automatically show programmatically-drawn placeholder images (a document card or face silhouette) with a shutter-style capture button. This is expected behaviour, not a bug.
4. **Connect Token Expiry**: The connect token from the server is short-lived (~120 seconds). If the journey URL doesn't load in time, request a new one.
5. **Handler Assignment Timing**: Assign handlers in `onAppear`, not in the initializer. The `@StateObject` host persists across re-renders, but `onAppear` is the SwiftUI-idiomatic place for setup.
6. **Memory Leak Prevention**: Use `[weak host]` in handler closures. Without it, the closure captures a strong reference to the host, which captures the WebView, creating a retain cycle.
7. **onChange Signature**: iOS 16 uses `onChange(of:) { newValue in ... }`. iOS 17+ uses `onChange(of:) { ... }` (no parameter). The reference app targets iOS 16.

## Tutorial Tone

- Second person ("you")
- Imperative for instructions ("Create a new file", "Add the following code")
- Present tense for explanations ("The BridgeHost manages...", "This handler suspends...")
- No hedging ("might", "could") — be direct
- Code-first: show the code, then explain it
- Every code block should be copy-pasteable and complete (no "..." or "add your code here")

## Estimated Length

~400-500 lines of markdown, including all inline code blocks. Should take someone 20-30 minutes to follow.

---

# Part 2 Tutorial Notes

Internal notes for transforming the Part 2 reference build (`part-2-smart-capture` branch) into "Tutorial Part 2: Integrate Smart Capture SDKs".

## Prerequisite

Part 2 assumes the reader has completed Part 1 or cloned the reference repo. The tutorial begins from the Part 1 working state.

## Step-to-Section Mapping

| Reference Build Step | Tutorial Section | Key Content |
|---|---|---|
| Branch checkout | "Start from Part 1" | `git checkout part-2-smart-capture`. Explain the branch structure. Brief diff overview. |
| Obtain SDKs | "Prerequisites: Smart Capture SDKs" | **Critical section.** Explain that SDKs are not in the repo. Contact GBG representative. List all 6 frameworks and their purposes, plus the two exact-version Swift packages (Lottie for Document, OpenSSL for OzoneNFC). |
| Framework setup | "Add the Smart Capture SDKs" | Step-by-step: place in `Frameworks/`, drag into Xcode, Embed & Sign. Screenshots of Xcode UI. |
| Compiler flag | "Enable the Compiler Flag" | Add `SMART_CAPTURE_ENABLED` to Active Compilation Conditions. Explain what the flag does. Screenshot of Build Settings. |
| SmartCaptureDocumentView.swift | "Document Capture with SmartCapture" | Walk through the wrapper view. Explain `DocumentSDK`, `DocumentScannerConfig`, auto-capture toggle, `onReceive` result handling. Compare with the stub. |
| SmartCaptureFaceView.swift | "Face Capture with Liveness" | Walk through the delegate pattern. Explain `FaceCameraSDK.controllerSwiftUIWrapper`, `FaceCameraListenable` protocol, biometric blobs (encrypted vs unencrypted). Compare with the stub. |
| SmartCaptureChipReaderView.swift | "Passport Chip Reading" | The `host.nfcRead` slot (GBGBridge 1.2.0). What the app does (run the Ozone reader, hand back files and checks) versus what the SDK does (validate the request, busy/unsupported, shape the response). `deviceCanRead`. The NFC capability and Info.plist keys. Sheet rather than full-screen cover. No stub: unsupported without the SDK. Link to the Passport Chip Reading section of Capability Handling. |
| JourneyView.swift changes | "The Swap Pattern" | Show the `#if SMART_CAPTURE_ENABLED && !targetEnvironment(simulator)` conditional. Explain why simulator falls back to stubs. Highlight that nothing else in the bridge integration changed. |
| CameraDetector | "Camera Permissions" | Explain `CameraDetector.check()` and `permissionState` population. Why this matters for capability.query responses. |
| Run on device | "Test on a Physical Device" | Start server, configure IP, run on device. Expected: SmartCapture document scanner, face camera with liveness overlay. |

## Additional Prose Needed

1. **Introduction** — What Part 2 adds on top of Part 1. Expected result: same app, real document scanning and face capture. (1 paragraph)
2. **The Conditional Compile Pattern** — A callout explaining why we use `#if` instead of runtime switching. Benefits: zero overhead when disabled, no unused framework imports, clear separation.
3. **What the Real SDKs Provide** — A comparison table: stubs vs SmartCapture. Document: no detection/crop/quality → guided capture, auto-crop, quality scoring. Face: raw photo → liveness detection, face positioning, encrypted biometric blobs.
4. **Without the SDKs** — Reassure that the app works without them. Same as Part 1. This is intentional.
5. **What's Next** — Pointers to NFC guide, UIKit integration, Android reference.

## Screenshots to Capture

1. The `Frameworks/` directory in Finder with the 4 XCFrameworks placed
2. Xcode target settings showing Embed & Sign for frameworks
3. Xcode Build Settings showing `SMART_CAPTURE_ENABLED` in Active Compilation Conditions
4. The SmartCapture document scanner running on a device (guided overlay)
5. The FaceCamera SDK running on a device (face positioning feedback)
6. `git diff main..part-2-smart-capture --stat` output showing the small changeset

## Common Pitfalls to Call Out

1. **Missing runtime dependencies**: If you add `FaceCamera.xcframework` but forget `IDLiveFaceCamera.xcframework` or `IDLiveFaceIAD.xcframework`, the app will crash at launch with a "Library not loaded" error.
2. **Flag not set**: If you add the frameworks but forget the `SMART_CAPTURE_ENABLED` flag, the app still uses stubs. No error — it just silently uses the old code path.
3. **Simulator with flag**: Even with the flag, Simulator uses stubs. This is by design — SmartCapture SDKs require camera hardware. Don't file a bug.
4. **Framework signing**: All frameworks must be set to **Embed & Sign**, not "Embed Without Signing" or "Do Not Embed". Incorrect embedding causes runtime crashes.
5. **Image format**: The Document SDK returns raw image data. The mimeType defaults to `"image/jpeg"` if not specified in the `DocumentCaptureResult` constructor.
6. **Smart Capture 1.7.0 dependencies**: Document needs `IDSCamera.xcframework` and Lottie; OzoneNFC needs OpenSSL. Missing any of them is a "Library not loaded" crash at launch. Pin Lottie and OpenSSL to the exact versions the SDKs were built against.
7. **NFC capability missing**: Without the Near Field Communication Tag Reading capability the reader session fails to start. Without the `A0000002471001` select identifier in Info.plist, iOS cannot select the passport application and every read fails.
8. **Chip reading on iPad or Simulator**: `NFCTagReaderSession.readingAvailable` is false, so the app reports chip reading as unsupported and the journey offers an alternative. Expected, not a bug.

## Tutorial Tone

Same as Part 1:
- Second person, imperative, present tense
- Code-first: show the code, then explain
- Every code block is copy-pasteable
- Call out what changed vs Part 1 — readers should see the minimal diff

## Estimated Length

~300-400 lines of markdown, including inline code blocks. Should take 15-20 minutes to follow (shorter than Part 1 since the foundation is already built).
