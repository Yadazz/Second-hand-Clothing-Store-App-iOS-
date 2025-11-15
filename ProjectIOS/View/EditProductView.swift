import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit

struct EditProductView: View {
    @State private var productName: String
    @State private var price: String
    @State private var detail: String
    @State private var status: String
    @State private var productImage: UIImage? = nil
    @State private var isProductImagePickerPresented: Bool = false

    // ✅ สำหรับ Alert
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccessAlert = false

    var product: ProductItemm

    // Status options
    let statusOptions = ["available", "sold", "reserved", "no status"]

    init(product: ProductItemm) {
        self.product = product
        _productName = State(initialValue: product.name)
        _price = State(initialValue: product.price)
        _detail = State(initialValue: product.detail)
        _status = State(initialValue: product.status)
    }

    var body: some View {
        ZStack {
            Color(red: 130/255, green: 116/255, blue: 70/255).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Image Display
                    Button(action: {
                        isProductImagePickerPresented = true
                    }) {
                        if let productImage = productImage {
                            Image(uiImage: productImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 250, height: 250)
                                .cornerRadius(15)
                                .clipped()
                                .shadow(radius: 6)
                        } else if let productImageURL = product.imageURL, let url = URL(string: productImageURL) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 250, height: 250)
                                    .cornerRadius(15)
                                    .clipped()
                                    .shadow(radius: 6)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 250, height: 250)
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 250, height: 250)
                                VStack {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                    Text("Upload Product Image")
                                }
                                .foregroundColor(.white.opacity(0.9))
                            }
                            .shadow(radius: 4)
                        }
                    }

                    // Input Fields
                    InputField(title: "Product Name", text: $productName)
                    InputField(title: "Price", text: $price)
                    InputEditor(title: "Detail", text: $detail)
                    
                    // Status Picker
                    StatusPicker(title: "Status", selectedStatus: $status, options: statusOptions)

                    // Confirm Button
                    Button(action: updateProduct) {
                        Text("UPDATE PRODUCT")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)

                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarTitle("Edit Product", displayMode: .inline)
        .sheet(isPresented: $isProductImagePickerPresented) {
            ImagePickerView(isPresented: $isProductImagePickerPresented, image: $productImage)
        }
        // ✅ Alert แสดงผล
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccessAlert ? "Success" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Custom UI Components
    struct InputField: View {
        var title: String
        @Binding var text: String
        let fieldColor = Color(red: 190/255, green: 177/255, blue: 134/255)

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                TextField("Enter \(title.lowercased())", text: $text)
                    .padding()
                    .background(fieldColor)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
        }
    }

    struct InputEditor: View {
        var title: String
        @Binding var text: String
        let borderColor = Color(red: 190/255, green: 177/255, blue: 134/255)

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                TextEditor(text: $text)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: 2)
                    )
                    .cornerRadius(10)
                    .foregroundColor(.black)
            }
        }
    }
    
    struct StatusPicker: View {
        var title: String
        @Binding var selectedStatus: String
        var options: [String]
        let fieldColor = Color(red: 190/255, green: 177/255, blue: 134/255)

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Menu {
                    ForEach(options, id: \.self) { option in
                        Button(option.capitalized) {
                            selectedStatus = option
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedStatus.capitalized)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(fieldColor)
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Functions
    func updateProduct() {
        // Validation
        guard !productName.isEmpty else {
            alertMessage = "Product name cannot be empty"
            isSuccessAlert = false
            showAlert = true
            return
        }
        
        guard !price.isEmpty else {
            alertMessage = "Price cannot be empty"
            isSuccessAlert = false
            showAlert = true
            return
        }
        
        // Validate price format
        if Double(price) == nil {
            alertMessage = "Please enter a valid price"
            isSuccessAlert = false
            showAlert = true
            return
        }
        
        if let selectedProductImage = productImage {
            uploadProductImage(selectedProductImage) { productImageURL in
                updateFirestore(productImageURL: productImageURL)
            }
        } else {
            updateFirestore(productImageURL: product.imageURL)
        }
    }

    func uploadProductImage(_ image: UIImage, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            self.alertMessage = "Failed to get image data."
            self.isSuccessAlert = false
            self.showAlert = true
            return
        }

        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("product_images/\(UUID().uuidString).jpg")

        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                self.alertMessage = "Error uploading image: \(error.localizedDescription)"
                self.isSuccessAlert = false
                self.showAlert = true
                return
            }

            imageRef.downloadURL { url, error in
                if let error = error {
                    self.alertMessage = "Error getting image URL: \(error.localizedDescription)"
                    self.isSuccessAlert = false
                    self.showAlert = true
                    return
                }

                if let downloadURL = url {
                    completion(downloadURL.absoluteString)
                }
            }
        }
    }

    func updateFirestore(productImageURL: String?) {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not authenticated"
            isSuccessAlert = false
            showAlert = true
            return
        }
        
        let db = Firestore.firestore()
        var updatedData: [String: Any] = [
            "name": productName,
            "price": price,
            "detail": detail,
            "status": status // เพิ่ม status ในการอัพเดต
        ]

        if let productImageURL = productImageURL {
            updatedData["imageURL"] = productImageURL
        }

        db.collection("users").document(user.uid).collection("products").document(product.id).updateData(updatedData) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertMessage = "❌ Failed to update product: \(error.localizedDescription)"
                    self.isSuccessAlert = false
                } else {
                    self.alertMessage = "✅ Product updated successfully!"
                    self.isSuccessAlert = true
                }
                self.showAlert = true
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePickerView

        init(parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.image = selectedImage
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}

// MARK: - Preview
struct EditProductView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleProduct = ProductItemm(
            id: "sample-id",
            name: "Sample Product",
            price: "999",
            detail: "This is a sample product detail",
            imageURL: "https://example.com/image.jpg",
            sellerName: "Sample Seller",
            sellerId: "seller-id",
            status: "available"
        )
        NavigationView {
            EditProductView(product: sampleProduct)
        }
    }
}
