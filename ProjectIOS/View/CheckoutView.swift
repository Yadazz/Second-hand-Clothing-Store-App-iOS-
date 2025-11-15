import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct CheckoutView: View {
    var productId: String
    var productName: String
    var productPrice: Double
    var userName: String
    var userAddress: String
    var phoneNumber: String
    var shopName: String
    var sellerId: String
    var productImageURL: String?

    @State private var qrCodeImage: UIImage? = nil
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var isShowingImagePicker = false
    @State private var selectedSlipImage: UIImage? = nil
    @State private var showSavedAlert = false
    @State private var isProcessingOrder = false
    @State private var showOrderConfirmation = false
    @State private var orderSuccessMessage = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Order Summary Header
                orderSummaryHeader
                
                // Customer Information Card
                customerInfoCard
                
                // Product Information Card
                productInfoCard
                
                // Payment QR Code Card
                paymentQRCard
                
                // Payment Slip Upload Card
                paymentSlipCard
                
                // Checkout Button
                checkoutButton
            }
            .padding()
        }
        .background(Color(hue: 0.13, saturation: 0.4, brightness: 0.5))
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadQRCode()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if orderSuccessMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: $selectedSlipImage)
        }
    }
    
    // MARK: - Order Summary Header
    private var orderSummaryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "cart.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order Summary")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Review your order details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(red: 190/255, green: 177/255, blue: 134/255))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Customer Information Card
    private var customerInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.green)
                Text("Customer Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 10) {
                InfoRowView(icon: "person.circle", label: "Name", value: userName)
                InfoRowView(icon: "location.fill", label: "Address", value: userAddress, isMultiline: true)
                InfoRowView(icon: "phone.fill", label: "Phone", value: phoneNumber)
            }
        }
        .padding()
        .background(Color(red: 190/255, green: 177/255, blue: 134/255))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Product Information Card
    private var productInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundColor(.yellow)
                Text("Product Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 12) {
                // Product Image
                if let imageURL = productImageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                            )
                    }
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white)
                        )
                }
                
                // Product Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(shopName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(productName)
                        .font(.body)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(productPrice, specifier: "%.2f") ฿")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(red: 190/255, green: 177/255, blue: 134/255))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Payment QR Code Card
    private var paymentQRCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "qrcode")
                    .foregroundColor(.purple)
                Text("Payment QR Code")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 12) {
                if let qrCodeImage = qrCodeImage {
                    Image(uiImage: qrCodeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .onTapGesture {
                            saveQRCode()
                        }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .overlay(
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading QR Code...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                        )
                }
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Tap QR code to save to Photos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(red: 190/255, green: 177/255, blue: 134/255))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Payment Slip Upload Card
    private var paymentSlipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.richtext.fill")
                    .foregroundColor(.red)
                Text("Payment Slip")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 12) {
                Text("Please upload your payment slip")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: selectSlipImage) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Select Payment Slip")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 97/255, green: 73/255, blue: 40/255))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                if let slip = selectedSlipImage {
                    VStack(spacing: 8) {
                        Image(uiImage: slip)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Payment slip selected")
                                .font(.caption)
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                }
                
                if isUploading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Uploading payment slip...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = uploadError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(red: 190/255, green: 177/255, blue: 134/255))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Checkout Button
    private var checkoutButton: some View {
        Button(action: checkout) {
            HStack {
                if isProcessingOrder {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Processing Order...")
                        .fontWeight(.semibold)
                } else {
                    Image(systemName: "creditcard.fill")
                    Text("Complete Purchase")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                (selectedSlipImage != nil && !isProcessingOrder) ?
                Color.black : Color.gray.opacity(0.5)
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .disabled(selectedSlipImage == nil || isProcessingOrder)
        .animation(.easeInOut(duration: 0.2), value: selectedSlipImage == nil)
    }

    // MARK: - Functions
    func loadQRCode() {
        let db = Firestore.firestore()

        db.collection("users").document(sellerId).getDocument { document, error in
            if let error = error {
                print("Error fetching seller QR code: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                if let qrURL = document.data()?["promptPayQRURL"] as? String, let url = URL(string: qrURL) {
                    loadImage(from: url) { image in
                        self.qrCodeImage = image
                    }
                }
            }
        }
    }

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Image loading error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                print("Failed to convert data to image")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }

    func saveQRCode() {
        guard let image = qrCodeImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        alertTitle = "Success"
        alertMessage = "QR Code has been saved to your Photos."
        showAlert = true
    }

    func selectSlipImage() {
        isShowingImagePicker = true
    }

    func uploadSlipImage(completion: @escaping (String?) -> Void) {
        guard let image = selectedSlipImage,
              let imageData = image.jpegData(compressionQuality: 0.8),
              let buyerId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }

        isUploading = true
        uploadError = nil
        
        let storageRef = Storage.storage().reference()
        let fileName = "slips/\(buyerId)_\(UUID().uuidString).jpg"
        let slipRef = storageRef.child("paymentSlipImage/\(fileName)")

        slipRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isUploading = false
                    self.uploadError = "Upload failed: \(error.localizedDescription)"
                }
                completion(nil)
                return
            }

            slipRef.downloadURL { url, error in
                DispatchQueue.main.async {
                    self.isUploading = false
                    
                    if let error = error {
                        self.uploadError = "Get URL failed: \(error.localizedDescription)"
                        completion(nil)
                    } else {
                        completion(url?.absoluteString)
                    }
                }
            }
        }
    }

    func checkout() {
        guard selectedSlipImage != nil else {
            alertTitle = "Missing Payment Slip"
            alertMessage = "Please select your payment slip before proceeding."
            showAlert = true
            return
        }
        
        isProcessingOrder = true
        print("Processing order: \(productName)")

        uploadSlipImage { slipURL in
            guard let slipURL = slipURL else {
                DispatchQueue.main.async {
                    self.isProcessingOrder = false
                    self.alertTitle = "Upload Failed"
                    self.alertMessage = "Failed to upload payment slip. Please try again."
                    self.showAlert = true
                }
                return
            }

            self.processOrder(paymentSlipURL: slipURL)
        }
    }

    func processOrder(paymentSlipURL: String) {
        guard let buyerId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.isProcessingOrder = false
            }
            return
        }
        
        let db = Firestore.firestore()
        let batch = db.batch()

        // 1. Create order document
        let orderRef = db.collection("orders").document()
        let orderData: [String: Any] = [
            "orderId": orderRef.documentID,
            "productId": productId,
            "productName": productName,
            "productPrice": productPrice,
            "productImageURL": productImageURL ?? "",
            "buyerName": userName,
            "buyerAddress": userAddress,
            "buyerPhoneNumber": phoneNumber,
            "shopName": shopName,
            "sellerId": sellerId,
            "buyerId": buyerId,
            "orderDate": Timestamp(date: Date()),
            "notificationSent": false,
            "paymentSlipURL": paymentSlipURL,
            "trackingNumber": NSNull(),
            "status": "Pending"
        ]
        batch.setData(orderData, forDocument: orderRef)

        // 2. Create notification for seller
        let notificationRef = db.collection("notifications").document()
        let notificationData: [String: Any] = [
            "type": "order",
            "title": "New Order Received",
            "message": "\(userName) placed an order for \(productName)",
            "timestamp": Timestamp(date: Date()),
            "sellerId": sellerId,
            "buyerId": buyerId,
            "orderId": orderRef.documentID,
            "productId": productId,
            "isRead": false
        ]
        batch.setData(notificationData, forDocument: notificationRef)

        // 3. Update product status to sold
        let productRef = db.collection("users").document(sellerId)
                          .collection("products").document(productId)
        batch.updateData([
            "status": "sold",
            "soldDate": Timestamp(date: Date()),
            "buyerId": buyerId
        ], forDocument: productRef)

        // 4. Remove product from buyer's cart
        let cartRef = db.collection("users").document(buyerId)
                       .collection("cart").document(productId)
        batch.deleteDocument(cartRef)

        // Execute batch operation
        batch.commit { error in
            DispatchQueue.main.async {
                self.isProcessingOrder = false
                
                if let error = error {
                    self.alertTitle = "Order Failed"
                    self.alertMessage = "Failed to process order: \(error.localizedDescription)"
                    self.showAlert = true
                    print("Batch operation failed: \(error.localizedDescription)")
                } else {
                    self.orderSuccessMessage = "Order placed successfully!"
                    self.alertTitle = "Order Confirmed"
                    self.alertMessage = "Your order has been placed successfully! The seller will be notified and you'll receive updates on your order status."
                    self.showAlert = true
                    print("Order processed successfully")
                }
            }
        }
    }
}

// MARK: - Info Row Component
struct InfoRowView: View {
    let icon: String
    let label: String
    let value: String
    let isMultiline: Bool
    
    init(icon: String, label: String, value: String, isMultiline: Bool = false) {
        self.icon = icon
        self.label = label
        self.value = value
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        HStack(alignment: isMultiline ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
            }
            
            if !isMultiline {
                Spacer()
            }
        }
    }
}
