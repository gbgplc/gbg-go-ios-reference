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
