// SmartCaptureDocumentView.swift
//
// A SwiftUI wrapper around the SmartCapture Document SDK for real document scanning.
//
// This view replaces StubDocumentCameraView when SMART_CAPTURE_ENABLED is set.
// It provides guided document detection, auto-capture, quality scoring, and
// auto-cropping — none of which the stub offers.
//
// The Document SDK is not included in this repository. Obtain the following
// frameworks from your GBG account representative and add them to your project:
//   - Document.xcframework
//
// See the README for setup instructions.

#if SMART_CAPTURE_ENABLED

import Document
import SwiftUI

struct SmartCaptureDocumentView: View {
    let onCaptured: (Data, Int, Int) -> Void
    let onFailed: (String) -> Void

    @StateObject private var sdk: DocumentSDK

    init(
        documentSide: DocumentSide = .front,
        documentType: DocumentType = .unknown,
        onCaptured: @escaping (Data, Int, Int) -> Void,
        onFailed: @escaping (String) -> Void
    ) {
        let config = DocumentScannerConfig(
            autoCaptureToggleConfig: .showDelayed(durationMs: 10_000),
            documentSide: documentSide,
            documentType: documentType
        )
        _sdk = StateObject(wrappedValue: DocumentSDK(documentScannerConfig: config))
        self.onCaptured = onCaptured
        self.onFailed = onFailed
    }

    var body: some View {
        sdk.mainView
            .onReceive(sdk.$documentScannerResult) { newValue in
                guard let scannerResult = newValue else { return }
                switch scannerResult.result {
                case .success(let success):
                    onCaptured(
                        success.image.image,
                        success.image.width,
                        success.image.height
                    )
                case .failure(let failure):
                    onFailed(failure.message)
                }
            }
    }
}

#endif
