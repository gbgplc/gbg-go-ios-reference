// JourneyView.swift
//
// This is the core integration screen — the most important file in the reference app.
// It demonstrates the complete pattern for hosting a GBG Go identity journey:
//
//   1. Create a BridgeHost and declare which capabilities the app supports
//   2. Assign handlers to the document and selfie capture slots
//   3. Display BridgeWebView with the journey URL
//   4. Present camera views when the journey requests a capture
//   5. Return capture results back to the journey via the bridge
//
// The BridgeHost uses a "typed slot" API for the two most common capabilities:
//   - host.documentCapture — for document photo capture
//   - host.selfieCapture — for selfie/liveness capture
//
// Each slot follows a suspension pattern:
//   1. The journey sends a capture request via the bridge
//   2. The slot's handler is called, which sets activeRequest (triggering a sheet)
//   3. The handler suspends via awaitCompletion()
//   4. The user interacts with the camera view
//   5. The camera view calls slot.complete() or slot.cancelIfBusy()
//   6. The handler resumes and the result is sent back to the journey

import GBGBridge
import SwiftUI

struct JourneyView: View {
    let journeyURL: URL

    // TUTORIAL NOTE: BridgeHost is the main entry point for the GBGBridge SDK.
    // The hostVersion parameter identifies your app version in bridge messages.
    // Use init(hostVersion:) for the typed-slot API — it auto-derives capabilities
    // from the handlers you assign to documentCapture and selfieCapture.
    @StateObject private var host = BridgeHost(hostVersion: "1.0.0")

    // Presentation state for camera views, driven by the capture slot's activeRequest.
    @State private var showDocumentCamera = false
    @State private var showSelfieCamera = false

    var body: some View {
        // TUTORIAL NOTE: BridgeWebView wraps WKWebView with the bridge pre-configured.
        // It injects the bootstrap script, registers the message handler, and attaches
        // the host — all automatically. You just provide the URL and host.
        ZStack(alignment: .bottom) {
            BridgeWebView(url: journeyURL, host: host)
                .ignoresSafeArea()

            if let error = host.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red.cornerRadius(8))
                    .padding()
            }
        }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: configureHandlers)
            // Present the document camera when a document capture request arrives.
            .fullScreenCover(isPresented: $showDocumentCamera) {
                documentCameraView
            }
            // Present the selfie camera when a selfie capture request arrives.
            .fullScreenCover(isPresented: $showSelfieCamera) {
                selfieCameraView
            }
            // Drive presentation state from the capture slot's activeRequest.
            // When a request arrives, activeRequest becomes non-nil → show camera.
            // When the request completes, activeRequest becomes nil → dismiss camera.
            .onChange(of: host.documentCapture.activeRequest?.correlationId) { _ in
                showDocumentCamera = host.documentCapture.activeRequest != nil
            }
            .onChange(of: host.selfieCapture.activeRequest?.correlationId) { _ in
                showSelfieCamera = host.selfieCapture.activeRequest != nil
            }
    }

    // MARK: - Handler Configuration

    /// Assigns handlers to the document and selfie capture slots.
    ///
    /// This is where you define what happens when the web journey requests a capture.
    /// Each handler follows the same pattern:
    ///   1. Receive the request
    ///   2. Suspend via awaitCompletion() (this is where the camera UI is shown)
    ///   3. Return the result from complete() / cancelIfBusy()
    private func configureHandlers() {
        // TUTORIAL NOTE: The handler closure is called when the journey requests
        // a document photo. Setting the handler also marks the capability as
        // "supported" in capability.query responses.
        host.documentCapture.handler = { [weak host] _ in
            guard let host else { return .cancelled(reason: "Host deallocated") }
            // Suspend until the camera view calls complete() or cancelIfBusy()
            return await host.documentCapture.awaitCompletion()
        }

        // Same pattern for selfie capture.
        host.selfieCapture.handler = { [weak host] _ in
            guard let host else { return .cancelled(reason: "Host deallocated") }
            return await host.selfieCapture.awaitCompletion()
        }
    }

    // MARK: - Camera Views

    /// The document camera view, presented as a full-screen cover.
    ///
    /// SWAP POINT: Replace StubDocumentCameraView with the SmartCapture document SDK
    /// view for production. The completion callbacks remain the same — only the view changes.
    private var documentCameraView: some View {
        StubDocumentCameraView(
            onCaptured: { result in
                host.documentCapture.complete(.document(result))
            },
            onCancelled: {
                host.documentCapture.cancelIfBusy(reason: "User dismissed camera")
            }
        )
    }

    /// The selfie camera view, presented as a full-screen cover.
    ///
    /// SWAP POINT: Replace StubSelfieCameraView with the SmartCapture face liveness SDK
    /// view for production. The completion callbacks remain the same — only the view changes.
    private var selfieCameraView: some View {
        StubSelfieCameraView(
            onCaptured: { result in
                host.selfieCapture.complete(.selfie(result))
            },
            onCancelled: {
                host.selfieCapture.cancelIfBusy(reason: "User dismissed camera")
            }
        )
    }
}
