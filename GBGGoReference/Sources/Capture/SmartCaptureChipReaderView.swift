// SmartCaptureChipReaderView.swift
//
// A SwiftUI wrapper around the SmartCapture Ozone passport chip reader, answering
// the GBGBridge `nfcRead` slot.
//
// The slot owns the contract: it checks the request carries the access key (document
// number, date of birth, date of expiry), answers BUSY and UNSUPPORTED itself, and
// builds the response the web journey expects. This view only runs the reader and
// hands back what it read as an `NfcReadResult`.
//
// What the chip holds is the person's identity. Nothing read here is logged or kept:
// it goes to the slot and nowhere else.
//
// The Ozone reader is not included in this repository. Obtain the following from your
// GBG account representative and add them to your project:
//   - OzoneNFC.xcframework
//   - OpenSSL (Swift package, runtime dependency of OzoneNFC)
//
// See the README for setup instructions, including the NFC entitlement and Info.plist keys.

#if SMART_CAPTURE_ENABLED

import GBGBridge
@preconcurrency import OzoneNFC  // its types predate Sendable
import SwiftUI

/// Smart Capture's own chip-reading screen: instructions, where the chip sits on the
/// document, progress and errors. It does not dismiss itself; the slot clearing its
/// request does that (see JourneyView).
struct SmartCaptureChipReaderView: UIViewControllerRepresentable {
    let request: NfcReadRequest
    let onResult: (NfcReadResult) -> Void

    func makeUIViewController(context: Context) -> OzoneNFCViewController {
        OzoneNFCViewController(
            documentKey: OzoneNFCDocumentKey(
                passportNumber: request.documentNumber,
                dateOfBirth: request.dateOfBirth,
                expiryDate: request.dateOfExpiry
            ),
            completion: { result in
                onResult(OzoneChipResult.map(result))
            }
        )
    }

    func updateUIViewController(_ uiViewController: OzoneNFCViewController, context: Context) {}
}

// MARK: - Ozone to GBGBridge mapping

/// The only place Ozone's types meet the SDK's.
enum OzoneChipResult {
    static func map(_ result: Result<OzoneNFCDocument, OzoneNFCError>) -> NfcReadResult {
        switch result {
        case .success(let document):
            return .read(files: files(document), checks: checks(document))
        case .failure(.userCancelled):
            return .cancelled(reason: "User cancelled the chip read")
        case .failure(.invalidNfcKeyFormatting):
            return .failed(
                .missingMrzData,
                message: "The document number or dates are not in a form the chip reader accepts"
            )
        case .failure(let error):
            return .failed(.nfcReadFailed, message: error.localizedDescription)
        }
    }

    /// Every data group the chip returned. The SDK drops DG16 and anything outside the contract.
    private static func files(_ document: OzoneNFCDocument) -> [NfcReadFile] {
        dataGroups.compactMap { group, name in
            document.getRawDataGroup(dgId: group).map { NfcReadFile(name: name, bytes: Data($0)) }
        }
    }

    private static let dataGroups: [(OzoneNFCDataGroup, String)] = [
        (.COM, "COM"), (.SOD, "SOD"),
        (.DG1, "DG1"), (.DG2, "DG2"), (.DG3, "DG3"), (.DG4, "DG4"), (.DG5, "DG5"),
        (.DG6, "DG6"), (.DG7, "DG7"), (.DG8, "DG8"), (.DG9, "DG9"), (.DG10, "DG10"),
        (.DG11, "DG11"), (.DG12, "DG12"), (.DG13, "DG13"), (.DG14, "DG14"), (.DG15, "DG15"),
        (.DG16, "DG16")
    ]

    /// The security protocols the reader attempted. PACE is what Supplemental Access
    /// Control specifies; `passportDataValid` is the SOD check, which is passive authentication.
    private static func checks(_ document: OzoneNFCDocument) -> [NfcAuthCheck] {
        [
            NfcAuthCheck(type: .basicAccessControl, result: map(document.BACStatus)),
            NfcAuthCheck(type: .supplementalAccessControl, result: map(document.PACEStatus)),
            NfcAuthCheck(type: .chipAuthentication, result: map(document.chipAuthenticationStatus)),
            NfcAuthCheck(type: .activeAuthentication, result: map(document.activeAuthenticationStatus)),
            NfcAuthCheck(type: .passiveAuthentication, result: document.passportDataValid ? .success : .failure)
        ]
    }

    private static func map(_ status: AuthStatus) -> NfcAuthResult {
        switch status {
        case .success: return .success
        case .failure: return .failure
        case .skipped: return .skipped
        @unknown default: return .skipped
        }
    }
}

#endif
