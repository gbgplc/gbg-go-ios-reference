import SwiftUI
import UIKit

// Simulator-only selfie capture stub used internally by StubSelfieCameraView.
// Displays a static face silhouette with a shutter-style capture button.
struct SimulatorSelfieCaptureView: View {
    private let onCaptured: (SelfieCaptureResult) -> Void
    private let onCancelled: () -> Void

    init(
        onCaptured: @escaping (SelfieCaptureResult) -> Void,
        onCancelled: @escaping () -> Void
    ) {
        self.onCaptured = onCaptured
        self.onCancelled = onCancelled
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Stub Selfie Capture")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Simulator Mode")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                // Static face silhouette standing in for the front camera viewfinder.
                PlaceholderSelfieImage()
                    .frame(width: 240, height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        // Oval guide overlay like a typical selfie capture screen.
                        Ellipse()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            .frame(width: 180, height: 240)
                    )
                    .padding(.horizontal, 24)

                Spacer()

                // Capture button styled like the native camera shutter.
                Button(action: capture) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.bottom, 8)

                Button("Cancel", action: onCancelled)
                    .foregroundColor(.white)
                    .padding(.bottom, 32)
            }
        }
    }

    private func capture() {
        let image = PlaceholderSelfieImage.render(size: CGSize(width: 480, height: 640))
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            onCancelled()
            return
        }
        let result = SelfieCaptureResult(
            previewImageData: jpegData,
            width: Int(image.size.width * image.scale),
            height: Int(image.size.height * image.scale),
            mimeType: "image/jpeg",
            encryptedBlob: jpegData,
            unencryptedBlob: jpegData
        )
        onCaptured(result)
    }
}

// MARK: - Placeholder Selfie Image

/// Renders a synthetic face silhouette. Drawn programmatically — no bundled assets needed.
private struct PlaceholderSelfieImage: View {
    var body: some View {
        Canvas { context, size in
            Self.draw(in: context, size: size)
        }
        .background(Color(white: 0.25))
    }

    static func render(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cgContext = ctx.cgContext
            UIColor(white: 0.25, alpha: 1).setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            drawUIKit(in: cgContext, size: size)
        }
    }

    private static func draw(in context: GraphicsContext, size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height * 0.38

        // Head
        let headW = size.width * 0.38
        let headH = size.height * 0.28
        let headPath = Path(ellipseIn: CGRect(
            x: centerX - headW / 2,
            y: centerY - headH / 2,
            width: headW,
            height: headH
        ))
        context.fill(headPath, with: .color(Color(white: 0.55)))

        // Neck
        let neckW = headW * 0.35
        let neckH = headH * 0.25
        let neckRect = CGRect(
            x: centerX - neckW / 2,
            y: centerY + headH / 2 - 4,
            width: neckW,
            height: neckH
        )
        context.fill(Path(neckRect), with: .color(Color(white: 0.55)))

        // Shoulders
        let shoulderW = size.width * 0.75
        let shoulderH = size.height * 0.3
        let shoulderY = centerY + headH / 2 + neckH - 8
        let shoulderPath = Path(ellipseIn: CGRect(
            x: centerX - shoulderW / 2,
            y: shoulderY,
            width: shoulderW,
            height: shoulderH
        ))
        context.fill(shoulderPath, with: .color(Color(white: 0.55)))

        // Eyes (simple dots)
        let eyeY = centerY - headH * 0.05
        let eyeSpacing = headW * 0.22
        let eyeSize: CGFloat = 6
        for dx in [-eyeSpacing, eyeSpacing] {
            let eyePath = Path(ellipseIn: CGRect(
                x: centerX + dx - eyeSize / 2,
                y: eyeY - eyeSize / 2,
                width: eyeSize,
                height: eyeSize
            ))
            context.fill(eyePath, with: .color(Color(white: 0.4)))
        }

        // Mouth (small line)
        let mouthY = centerY + headH * 0.15
        let mouthW: CGFloat = headW * 0.2
        var mouthPath = Path()
        mouthPath.move(to: CGPoint(x: centerX - mouthW / 2, y: mouthY))
        mouthPath.addLine(to: CGPoint(x: centerX + mouthW / 2, y: mouthY))
        context.stroke(mouthPath, with: .color(Color(white: 0.4)), lineWidth: 2)
    }

    private static func drawUIKit(in cgContext: CGContext, size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height * 0.38

        UIColor(white: 0.55, alpha: 1).setFill()

        // Head
        let headW = size.width * 0.38
        let headH = size.height * 0.28
        UIBezierPath(ovalIn: CGRect(
            x: centerX - headW / 2,
            y: centerY - headH / 2,
            width: headW, height: headH
        )).fill()

        // Neck
        let neckW = headW * 0.35
        let neckH = headH * 0.25
        UIBezierPath(rect: CGRect(
            x: centerX - neckW / 2,
            y: centerY + headH / 2 - 4,
            width: neckW, height: neckH
        )).fill()

        // Shoulders
        let shoulderW = size.width * 0.75
        let shoulderH = size.height * 0.3
        UIBezierPath(ovalIn: CGRect(
            x: centerX - shoulderW / 2,
            y: centerY + headH / 2 + neckH - 8,
            width: shoulderW, height: shoulderH
        )).fill()

        // Eyes
        UIColor(white: 0.4, alpha: 1).setFill()
        let eyeY = centerY - headH * 0.05
        let eyeSpacing = headW * 0.22
        let eyeSize: CGFloat = 6
        for dx in [-eyeSpacing, eyeSpacing] {
            UIBezierPath(ovalIn: CGRect(
                x: centerX + dx - eyeSize / 2,
                y: eyeY - eyeSize / 2,
                width: eyeSize, height: eyeSize
            )).fill()
        }

        // Mouth
        UIColor(white: 0.4, alpha: 1).setStroke()
        let mouthY = centerY + headH * 0.15
        let mouthW = headW * 0.2
        let mouthPath = UIBezierPath()
        mouthPath.move(to: CGPoint(x: centerX - mouthW / 2, y: mouthY))
        mouthPath.addLine(to: CGPoint(x: centerX + mouthW / 2, y: mouthY))
        mouthPath.lineWidth = 2
        mouthPath.stroke()
    }
}
