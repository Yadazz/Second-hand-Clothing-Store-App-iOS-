import SwiftUI
import PhotosUI

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    // สร้าง PHPickerViewController
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1  // เลือกได้แค่ 1 ภาพ
        config.filter = .images   // กรองให้เลือกได้เฉพาะภาพ

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator  // ใช้ coordinator เพื่อจัดการเหตุการณ์
        return picker
    }
    
    // ฟังก์ชันนี้จะไม่ถูกใช้งานในที่นี้ เพราะเราไม่ต้องการอัพเดต UI
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    // สร้าง Coordinator ที่เป็นตัวกลางในการจัดการการเลือกภาพ
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    // Coordinator class สำหรับจัดการการเลือกภาพ
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            // ตรวจสอบว่าเลือกภาพได้หรือไม่
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage  // ส่งค่าภาพที่เลือกกลับไป
                }
            }
        }
    }
}
