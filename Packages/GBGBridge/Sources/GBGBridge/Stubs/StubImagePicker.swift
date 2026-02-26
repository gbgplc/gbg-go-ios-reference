import SwiftUI
import UIKit

/// Internal UIImagePickerController wrapper shared by the stub camera views.
///
/// This is not part of the public API — use ``StubDocumentCameraView`` or
/// ``StubSelfieCameraView`` instead.
struct StubImagePicker: UIViewControllerRepresentable {
  let sourceType: UIImagePickerController.SourceType
  let cameraDevice: UIImagePickerController.CameraDevice
  let onPicked: (UIImage) -> Void
  let onCancelled: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    picker.sourceType = sourceType
    picker.allowsEditing = false

    if sourceType == .camera {
      picker.cameraDevice = cameraDevice
    }

    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let parent: StubImagePicker

    init(parent: StubImagePicker) {
      self.parent = parent
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true)
      parent.onCancelled()
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      picker.dismiss(animated: true)

      if let image = info[.originalImage] as? UIImage {
        parent.onPicked(image)
      } else {
        parent.onCancelled()
      }
    }
  }
}
