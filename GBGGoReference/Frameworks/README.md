# Smart Capture Frameworks

This directory is where you place the Smart Capture SDK frameworks to enable real document scanning, face capture with liveness detection, and passport chip reading. `.xcframework` bundles here are gitignored: never commit them.

## Required Frameworks

Obtain the following frameworks from your GBG account representative (checked against Smart Capture iOS 1.7.0):

| Framework | Purpose |
|-----------|---------|
| `Document.xcframework` | Document scanning with guided capture, auto-crop, and quality scoring |
| `IDSCamera.xcframework` | Runtime dependency of Document |
| `FaceCamera.xcframework` | Face capture with liveness detection and encrypted biometric blobs |
| `IDLiveFaceCamera.xcframework` | Runtime dependency of FaceCamera |
| `IDLiveFaceIAD.xcframework` | Runtime dependency of FaceCamera |
| `OzoneNFC.xcframework` | Passport chip reading over NFC |

Two open-source Swift packages are needed at runtime as well. Add them with **File > Add Package Dependencies**, pinned to the exact versions the SDKs were built against:

| Package | Version | Needed by |
|---------|---------|-----------|
| `https://github.com/airbnb/lottie-spm.git` | `4.6.0` (exact) | Document |
| `https://github.com/krzyzanowskim/OpenSSL.git` | `3.6.3000` (exact) | OzoneNFC |

## Setup

1. Place all six `.xcframework` bundles in this directory
2. In Xcode, drag each framework into your target's **Frameworks, Libraries, and Embedded Content** section
3. Set each framework to **Embed & Sign**
4. Add the two Swift packages above
5. Under **Signing & Capabilities**, add **Near Field Communication Tag Reading** (the Info.plist entries chip reading needs are already in `Resources/Info.plist`)
6. Add `SMART_CAPTURE_ENABLED` to **Build Settings > Swift Compiler - Custom Flags > Active Compilation Conditions** for both Debug and Release
7. Build and run on a **physical iPhone** (Smart Capture SDKs require camera hardware; chip reading needs an NFC reader, which iPads and the Simulator lack)

## Without Smart Capture

If you don't have access to the Smart Capture SDKs, the app still builds and runs using stub camera views. The stubs provide basic camera capture on device and placeholder images on Simulator. There is no stub chip reader: the app reports chip reading as unsupported and the web journey offers its own alternative. See the main README for details.
