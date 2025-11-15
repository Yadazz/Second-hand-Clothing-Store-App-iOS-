import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct PostProductView: View {
    // States
    @State private var selectedImage: UIImage? = nil
    @State private var isPickerPresented = false
    @State private var productName: String = ""
    @State private var price: String = ""
    @State private var detail: String = ""
    @State private var status: String = "available"
    @State private var errorMessage: String = ""
    @State private var showSuccessMessage = false
    @State private var showAlert = false
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color(red: 130/255, green: 116/255, blue: 70/255).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    
                    // Product Image
                    Button(action: {
                        isPickerPresented.toggle()
                    }) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 250, height: 250)
                                .cornerRadius(15)
                                .clipped()
                                .shadow(radius: 6)
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
                    .sheet(isPresented: $isPickerPresented) {
                        ImagePicker(image: $selectedImage)
                    }

                    // Input Fields
                    Group {
                        InputField(title: "Product Name", text: $productName)
                        InputField(title: "Price", text: $price, keyboardType: .decimalPad)
                        InputEditor(title: "Details", text: $detail)
                    }

                    // Confirm Button
                    if isLoading {
                        ProgressView("Uploading...")
                            .foregroundColor(.white)
                    } else {
                        Button(action: addProduct) {
                            Text("CONFIRM")
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
                    }

                    Spacer()
                }
                .padding(.vertical)
                .padding(.horizontal, 20)
            }
        }
        // Alert Display
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(showSuccessMessage ? "Success !" : "Failed !"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Input UI Components
    struct InputField: View {
        var title: String
        @Binding var text: String
        var keyboardType: UIKeyboardType = .default

        let fieldColor = Color(red: 190/255, green: 177/255, blue: 134/255)

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                TextField("Enter \(title.lowercased())", text: $text)
                    .padding()
                    .keyboardType(keyboardType)
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

    // MARK: - Functions
    func addProduct() {
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "Please log in to add products."
            self.showSuccessMessage = false
            self.showAlert = true
            return
        }

        guard let selectedImage = selectedImage else {
            self.errorMessage = "Please select a product image."
            self.showSuccessMessage = false
            self.showAlert = true
            return
        }

        guard !productName.isEmpty, !price.isEmpty, !detail.isEmpty else {
            self.errorMessage = "Please complete all fields."
            self.showSuccessMessage = false
            self.showAlert = true
            return
        }

        guard let priceValue = Double(price) else {
            self.errorMessage = "Please enter a valid price."
            self.showSuccessMessage = false
            self.showAlert = true
            return
        }

        self.isLoading = true

        updateUserRole(userId: user.uid) {
            uploadImage(image: selectedImage) { productImageURL in
                saveProductData(userID: user.uid, productImageURL: productImageURL, priceValue: priceValue)
            }
        }
    }

    func updateUserRole(userId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                let userData = document.data()
                if userData?["role"] as? String != "Seller" {
                    userRef.updateData(["role": "Seller"]) { _ in completion() }
                } else {
                    completion()
                }
            } else {
                userRef.setData([
                    "role": "Seller",
                    "name": Auth.auth().currentUser?.displayName ?? "Unknown Seller",
                    "email": Auth.auth().currentUser?.email ?? ""
                ]) { _ in completion() }
            }
        }
    }

    func uploadImage(image: UIImage, completion: @escaping (String?) -> Void) {
        let imageRef = Storage.storage().reference().child("productImages/\(UUID().uuidString).jpg")
        if let imageData = image.jpegData(compressionQuality: 0.75) {
            imageRef.putData(imageData, metadata: nil) { _, error in
                if error != nil {
                    self.errorMessage = "Image upload failed."
                    self.showSuccessMessage = false
                    self.showAlert = true
                    self.isLoading = false
                    return
                }
                imageRef.downloadURL { url, _ in
                    completion(url?.absoluteString)
                }
            }
        }
    }

    func saveProductData(userID: String, productImageURL: String?, priceValue: Double) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)

        userRef.getDocument { userDoc, _ in
            let sellerName = userDoc?.data()?["username"] as? String ?? "Unknown Seller"
            let productRef = db.collection("users").document(userID).collection("products").document()
            var productData: [String: Any] = [
                "name": productName,
                "price": priceValue,
                "detail": detail,
                "status": status,
                "createdAt": Timestamp(date: Date()),
                "sellerId": userID,
                "sellerName": sellerName,
                "productId": productRef.documentID
            ]
            if let url = productImageURL {
                productData["imageURL"] = url
            }
            productRef.setData(productData) { error in
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Failed to add product: \(error.localizedDescription)"
                    self.showSuccessMessage = false
                } else {
                    self.errorMessage = "✅ Product added successfully"
                    self.showSuccessMessage = true
                    self.productName = ""
                    self.price = ""
                    self.detail = ""
                    self.selectedImage = nil
                }
                self.showAlert = true
            }
        }
    }
}

#Preview {
    PostProductView()
}
