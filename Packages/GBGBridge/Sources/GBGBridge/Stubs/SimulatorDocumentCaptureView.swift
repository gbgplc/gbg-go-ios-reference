import SwiftUI
import UIKit

// Simulator-only document capture stub used internally by StubDocumentCameraView.
// Displays a static placeholder document image with a shutter-style capture button.
struct SimulatorDocumentCaptureView: View {
    private let onCaptured: (DocumentCaptureResult) -> Void
    private let onCancelled: () -> Void

    init(
        onCaptured: @escaping (DocumentCaptureResult) -> Void,
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

                Text("Stub Document Capture")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text("Simulator Mode")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                // Static placeholder image standing in for the camera viewfinder.
                PlaceholderDocumentImage()
                    .frame(maxWidth: 340, maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
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
        let image = PlaceholderDocumentImage.render(size: CGSize(width: 680, height: 440))
        guard let pngData = image.pngData() else {
            onCancelled()
            return
        }
        let result = DocumentCaptureResult(
            imageData: pngData,
            width: Int(image.size.width * image.scale),
            height: Int(image.size.height * image.scale),
            mimeType: "image/png"
        )
        onCaptured(result)
    }
}

// MARK: - Placeholder Document Image

/// Renders a synthetic document image that looks like a passport / ID card photo.
/// Drawn programmatically so no bundled assets are needed.
private struct PlaceholderDocumentImage: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                Self.draw(in: context, size: size)
            }
        }
        .background(Color(white: 0.95))
    }

    static func render(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cgContext = ctx.cgContext
            // Background
            UIColor(white: 0.95, alpha: 1).setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            drawUIKit(in: cgContext, size: size)
        }
    }

    private static func draw(in context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let inset = rect.insetBy(dx: 16, dy: 16)

        // Card background
        let cardPath = Path(roundedRect: inset, cornerRadius: 8)
        context.fill(cardPath, with: .color(.white))
        context.stroke(cardPath, with: .color(Color(white: 0.8)), lineWidth: 1)

        // "Photo" placeholder (small rect on the left)
        let photoRect = CGRect(
            x: inset.minX + 16,
            y: inset.minY + 20,
            width: size.width * 0.22,
            height: size.height * 0.55
        )
        let photoPath = Path(roundedRect: photoRect, cornerRadius: 4)
        context.fill(photoPath, with: .color(Color(white: 0.85)))

        // Head silhouette circle
        let headSize: CGFloat = min(photoRect.width, photoRect.height) * 0.35
        let headCenter = CGPoint(x: photoRect.midX, y: photoRect.midY - headSize * 0.3)
        let headPath = Path(ellipseIn: CGRect(
            x: headCenter.x - headSize / 2,
            y: headCenter.y - headSize / 2,
            width: headSize,
            height: headSize
        ))
        context.fill(headPath, with: .color(Color(white: 0.7)))

        // Shoulder arc
        let shoulderWidth = headSize * 1.6
        let shoulderTop = headCenter.y + headSize * 0.55
        let shoulderPath = Path(ellipseIn: CGRect(
            x: headCenter.x - shoulderWidth / 2,
            y: shoulderTop,
            width: shoulderWidth,
            height: headSize * 0.8
        ))
        context.fill(shoulderPath, with: .color(Color(white: 0.7)))

        // Text lines placeholder (right side)
        let textX = photoRect.maxX + 16
        let textWidth = inset.maxX - textX - 16
        let lineHeight: CGFloat = 10
        let lineSpacing: CGFloat = 8
        var y = inset.minY + 28

        let lineLengths: [CGFloat] = [0.7, 1.0, 0.85, 0.6, 0.9, 0.5]
        for fraction in lineLengths {
            let lineRect = CGRect(x: textX, y: y, width: textWidth * fraction, height: lineHeight)
            let linePath = Path(roundedRect: lineRect, cornerRadius: 2)
            context.fill(linePath, with: .color(Color(white: 0.82)))
            y += lineHeight + lineSpacing
        }

        // MRZ-style lines at the bottom
        let mrzY = inset.maxY - 36
        for i in 0..<2 {
            let mrzRect = CGRect(
                x: inset.minX + 16,
                y: mrzY + CGFloat(i) * 14,
                width: inset.width - 32,
                height: 8
            )
            let mrzPath = Path(roundedRect: mrzRect, cornerRadius: 1)
            context.fill(mrzPath, with: .color(Color(white: 0.78)))
        }
    }

    private static func drawUIKit(in cgContext: CGContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        let inset = rect.insetBy(dx: 16, dy: 16)

        // Card
        UIColor.white.setFill()
        UIBezierPath(roundedRect: inset, cornerRadius: 8).fill()
        UIColor(white: 0.8, alpha: 1).setStroke()
        UIBezierPath(roundedRect: inset, cornerRadius: 8).stroke()

        // Photo placeholder
        let photoRect = CGRect(
            x: inset.minX + 16,
            y: inset.minY + 20,
            width: size.width * 0.22,
            height: size.height * 0.55
        )
        UIColor(white: 0.85, alpha: 1).setFill()
        UIBezierPath(roundedRect: photoRect, cornerRadius: 4).fill()

        // Head
        let headSize = min(photoRect.width, photoRect.height) * 0.35
        let headCenter = CGPoint(x: photoRect.midX, y: photoRect.midY - headSize * 0.3)
        UIColor(white: 0.7, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(
            x: headCenter.x - headSize / 2,
            y: headCenter.y - headSize / 2,
            width: headSize, height: headSize
        )).fill()

        // Shoulders
        let sw = headSize * 1.6
        UIBezierPath(ovalIn: CGRect(
            x: headCenter.x - sw / 2,
            y: headCenter.y + headSize * 0.55,
            width: sw, height: headSize * 0.8
        )).fill()

        // Text lines
        let textX = photoRect.maxX + 16
        let textWidth = inset.maxX - textX - 16
        var y = inset.minY + 28
        UIColor(white: 0.82, alpha: 1).setFill()
        for fraction in [0.7, 1.0, 0.85, 0.6, 0.9, 0.5] as [CGFloat] {
            UIBezierPath(roundedRect: CGRect(x: textX, y: y, width: textWidth * fraction, height: 10), cornerRadius: 2).fill()
            y += 18
        }

        // MRZ
        UIColor(white: 0.78, alpha: 1).setFill()
        let mrzY = inset.maxY - 36
        for i in 0..<2 {
            UIBezierPath(roundedRect: CGRect(
                x: inset.minX + 16,
                y: mrzY + CGFloat(i) * 14,
                width: inset.width - 32,
                height: 8
            ), cornerRadius: 1).fill()
        }
    }
}
