# Smart Capture Frameworks

This directory is where you place the Smart Capture SDK frameworks to enable real document scanning and face capture with liveness detection.

## Required Frameworks

Obtain the following frameworks from your GBG account representative:

| Framework | Purpose |
|-----------|---------|
| `Document.xcframework` | Document scanning with guided capture, auto-crop, and quality scoring |
| `FaceCamera.xcframework` | Face capture with liveness detection and encrypted biometric blobs |
| `IDLiveFaceCamera.xcframework` | Runtime dependency of FaceCamera |
| `IDLiveFaceIAD.xcframework` | Runtime dependency of FaceCamera |

## Setup

1. Place all four `.xcframework` bundles in this directory
2. In Xcode, drag each framework into your target's **Frameworks, Libraries, and Embedded Content** section
3. Set each framework to **Embed & Sign**
4. Add `SMART_CAPTURE_ENABLED` to **Build Settings > Swift Compiler - Custom Flags > Active Compilation Conditions** for both Debug and Release
5. Build and run on a **physical device** (Smart Capture SDKs require camera hardware)

## Without Smart Capture

If you don't have access to the Smart Capture SDKs, the app still builds and runs using stub camera views. The stubs provide basic camera capture on device and placeholder images on Simulator. See the main README for details.
