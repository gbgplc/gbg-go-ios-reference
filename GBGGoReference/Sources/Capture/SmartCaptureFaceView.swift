// SmartCaptureFaceView.swift
//
// A SwiftUI wrapper around the SmartCapture FaceCamera SDK for face capture
// with liveness detection.
//
// This view replaces StubSelfieCameraView when SMART_CAPTURE_ENABLED is set.
// It provides guided face positioning, passive liveness detection, and encrypted
// biometric blobs that pass server-side validation — none of which the stub offers.
//
// The FaceCamera SDK is not included in this repository. Obtain the following
// frameworks from your GBG account representative and add them to your project:
//   - FaceCamera.xcframework
//   - IDLiveFaceCamera.xcframework  (runtime dependency)
//   - IDLiveFaceIAD.xcframework     (runtime dependency)
//
// See the README for setup instructions.

#if SMART_CAPTURE_ENABLED

import FaceCamera
import SwiftUI
import UIKit

struct SmartCaptureFaceView: View {
    let onCaptured: (UIImage, Data, Data) -> Void
    let onFailed: (String) -> Void
    let onCancelled: () -> Void

    var body: some View {
        FaceCameraSDK.controllerSwiftUIWrapper(
            delegate: FaceCameraDelegateHandler(
                onCaptured: onCaptured,
                onFailed: onFailed,
                onCancelled: onCancelled
            )
        )
    }
}

// MARK: - FaceCamera Delegate

/// Bridges FaceCamera's delegate callbacks to SwiftUI-friendly closures.
class FaceCameraDelegateHandler: NSObject, FaceCameraListenable {
    let onCaptured: (UIImage, Data, Data) -> Void
    let onFailed: (String) -> Void
    let onCancelled: () -> Void

    init(
        onCaptured: @escaping (UIImage, Data, Data) -> Void,
        onFailed: @escaping (String) -> Void,
        onCancelled: @escaping () -> Void
    ) {
        self.onCaptured = onCaptured
        self.onFailed = onFailed
        self.onCancelled = onCancelled
    }

    func didCapture(_ result: FaceCameraResult) {
        onCaptured(result.previewPhoto, result.encryptedBlob, result.unencryptedBlob)
    }

    func didEncounterError(_ error: FaceCameraError) {
        onFailed(error.description)
    }

    func didCancel() {
        onCancelled()
    }

    func didTapBack() {
        onCancelled()
    }
}

#endif
