import SwiftUI
import Firebase
import FirebaseFirestore

// MARK: - NotificationDetailView
struct NotificationDetailView: View {
    let notification: NotificationItem
    
    @State private var orderData: [String: Any]?
    @State private var productImageURL: String?
    @State private var isLoading = true
    @State private var trackingNumber: String = ""
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertType: AlertType = .success
    @State private var showImageViewer = false
    @State private var imageToShow: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Theme Colors (เดียวกับ ProfileView)
    let backgroundColor = Color(red: 130/255, green: 116/255, blue: 70/255)
    let fieldBackgroundColor = Color(red: 190/255, green: 177/255, blue: 134/255)
    let buttonColor = Color(red: 97/255, green: 73/255, blue: 40/255)
    let cardBackgroundColor = Color(red: 160/255, green: 147/255, blue: 104/255) // สีสำหรับ card
    
    enum AlertType {
        case success, error, warning, imageSaved // เพิ่ม imageSaved
        
        var title: String {
            switch self {
            case .success: return "Success"
            case .error: return "Error"
            case .warning: return "Warning"
            case .imageSaved: return "Image Saved" // ใหม่
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .imageSaved: return .blue // ใหม่
            }
        }
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                if isLoading {
                    loadingView
                } else if let data = orderData {
                    orderDetailsView(data: data)
                } else {
                    errorStateView
                }
            }
        }
        .navigationTitle("Order Management")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(backgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            fetchOrderData()
            loadExistingTrackingNumber()
        }
        .alert(alertType.title, isPresented: $showAlert) {
            Button("OK") {
                // เฉพาะ tracking success เท่านั้นที่จะ dismiss
                if alertType == .success {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showImageViewer) {
            if let image = imageToShow {
                ImageViewerSheet(image: image)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("Loading order details...")
                .foregroundColor(.white.opacity(0.8))
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Error State View
    private var errorStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Order Not Found")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("Unable to load order details. Please try again.")
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                isLoading = true
                fetchOrderData()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(buttonColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Order Details View
    @ViewBuilder
    func orderDetailsView(data: [String: Any]) -> some View {
        LazyVStack(spacing: 20) {
            // Order Status Card
            orderStatusCard(data: data)
            
            // Customer Information Card
            customerInfoCard(data: data)
            
            // Product Information Card
            productInfoCard(data: data)
            
            // Payment
            paymentInfoCard(data: data)
            
            // Tracking Number Section
            trackingNumberSection()
            
            // Action Button
            actionButton()
        }
        .padding()
    }
    
    // MARK: - Order Status Card
    @ViewBuilder
    func orderStatusCard(data: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.white)
                Text("Order Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Divider()
                .background(.white.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order ID")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text(notification.orderId)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if let date = (data["orderDate"] as? Timestamp)?.dateValue() {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Order Date")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Customer Information Card
    @ViewBuilder
    func customerInfoCard(data: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                Text("Customer Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Divider()
                .background(.white.opacity(0.3))
            
            VStack(spacing: 10) {
                DetailInfoRow(icon: "person.circle",
                       label: "Name",
                       value: data["buyerName"] as? String ?? "N/A")
                
                DetailInfoRow(icon: "phone.fill",
                       label: "Phone",
                       value: data["buyerPhoneNumber"] as? String ?? "N/A")
                
                DetailInfoRow(icon: "location.fill",
                       label: "Address",
                       value: data["buyerAddress"] as? String ?? "N/A",
                       isMultiline: true)
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Product Information Card
    @ViewBuilder
    func productInfoCard(data: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundColor(.white)
                Text("Product Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }

            Divider()
                .background(.white.opacity(0.3))

            VStack(spacing: 10) {
                // แสดงรูปภาพสินค้า
                if let productImageURL = productImageURL, let url = URL(string: productImageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(fieldBackgroundColor.opacity(0.5))
                            .frame(height: 200)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            )
                    }
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(fieldBackgroundColor.opacity(0.5))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.7))
                                Text("No product image available")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.caption)
                            }
                        )
                }

                DetailInfoRow(icon: "cube.box",
                              label: "Product",
                              value: data["productName"] as? String ?? "N/A")
                
                DetailInfoRow(icon: "banknote",
                              label: "Price",
                              value: "\(String(format: "%.2f", data["productPrice"] as? Double ?? 0)) ฿")
                
                DetailInfoRow(icon: "storefront",
                              label: "Shop",
                              value: data["shopName"] as? String ?? "N/A")
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Payment Information Card
    @ViewBuilder
    func paymentInfoCard(data: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.white)
                Text("Payment Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Divider()
                .background(.white.opacity(0.3))
            
            // Payment Slip Section
            if let slipURL = data["paymentSlipURL"] as? String,
               let url = URL(string: slipURL) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Slip:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 250)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .onTapGesture {
                                downloadAndShowImage(from: url)
                            }
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(fieldBackgroundColor.opacity(0.5))
                            .frame(height: 200)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            )
                    }
                    
                    HStack {
                        Button(action: {
                            downloadImage(from: url)
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save to Photos")
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(buttonColor.opacity(0.8))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            downloadAndShowImage(from: url)
                        }) {
                            HStack {
                                Image(systemName: "eye")
                                Text("View Full Size")
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(buttonColor.opacity(0.8))
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.white.opacity(0.8))
                    Text("No payment slip available")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }

    // MARK: - Tracking Number Section
    @ViewBuilder
    func trackingNumberSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.white)
                Text("Shipping Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Divider()
                .background(.white.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Tracking Number")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Enter tracking number", text: $trackingNumber)
                    .padding()
                    .background(fieldBackgroundColor)
                    .cornerRadius(15)
                    .foregroundColor(.black)
                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .submitLabel(.done)
                
                if !trackingNumber.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                        Text("Tracking number entered")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Action Button
    @ViewBuilder
    func actionButton() -> some View {
        Button(action: saveTrackingNumber) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Save & Send Tracking Info")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                trackingNumber.trimmingCharacters(in: .whitespaces).isEmpty ?
                buttonColor.opacity(0.5) : buttonColor
            )
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .disabled(isSaving || trackingNumber.trimmingCharacters(in: .whitespaces).isEmpty)
        .animation(.easeInOut(duration: 0.2), value: trackingNumber.isEmpty)
    }
    
    // MARK: - Functions
    func fetchOrderData() {
        let db = Firestore.firestore()
        let orderId = notification.orderId
        
        db.collection("orders")
            .document(orderId)
            .getDocument { document, error in
                if let error = error {
                    print("Error fetching order data: \(error)")
                } else if let document = document, document.exists {
                    self.orderData = document.data()
                    self.productImageURL = document.data()?["productImageURL"] as? String
                    print("Fetched product image URL: \(self.productImageURL ?? "No image URL")")
                    self.isLoading = false
                }
            }
    }
    
    func downloadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.alertType = .error
                    self.alertMessage = "Failed to download image."
                    self.showAlert = true
                }
                return
            }
            
            if let image = UIImage(data: data) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                DispatchQueue.main.async {
                    self.alertType = .imageSaved // เปลี่ยนเป็น imageSaved
                    self.alertMessage = "Image saved to your Photos."
                    self.showAlert = true
                }
            }
        }.resume()
    }
    
    func downloadAndShowImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.alertType = .error
                    self.alertMessage = "Failed to load image."
                    self.showAlert = true
                }
                return
            }
            
            DispatchQueue.main.async {
                self.imageToShow = image
                self.showImageViewer = true
            }
        }.resume()
    }
    
    func loadExistingTrackingNumber() {
        if let existingTrackingNumber = notification.trackingNumber {
            trackingNumber = existingTrackingNumber
        }
    }
    
    func saveTrackingNumber() {
        let trimmedTrackingNumber = trackingNumber.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedTrackingNumber.isEmpty else {
            alertType = .warning
            alertMessage = "Please enter a tracking number before saving."
            showAlert = true
            return
        }

        isSaving = true
        let db = Firestore.firestore()
        let orderId = notification.orderId

        // Update the tracking number in orders collection
        db.collection("orders").document(orderId).updateData([
            "trackingNumber": trimmedTrackingNumber,
            "trackingStatus": "Shipped",
            "lastUpdated": Timestamp()
        ]) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.alertType = .error
                    self.alertMessage = "Failed to save tracking number: \(error.localizedDescription)"
                    self.showAlert = true
                }
            } else {
                // Update notification collection
                self.updateNotificationStatus(db: db, orderId: orderId, trackingNumber: trimmedTrackingNumber)
            }
        }
    }
    
    private func updateNotificationStatus(db: Firestore, orderId: String, trackingNumber: String) {
        db.collection("notifications").whereField("orderId", isEqualTo: orderId).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isSaving = false
                
                if let error = error {
                    self.alertType = .error
                    self.alertMessage = "Failed to update notification: \(error.localizedDescription)"
                } else {
                    self.alertType = .success // นี่ยังคงเป็น success เพื่อให้ dismiss
                    self.alertMessage = "Tracking number saved successfully! Customer will be notified."
                    
                    // Update all related notifications
                    snapshot?.documents.forEach { document in
                        db.collection("notifications").document(document.documentID).updateData([
                            "trackingNumber": trackingNumber,
                            "trackingStatus": "Entered",
                            "title": "Your package has been shipped.",
                            "message": "Tracking number: \(trackingNumber)",
                            "type": "delivery",
                            "isRead": false,
                            "lastUpdated": Timestamp()
                        ])
                    }
                }
                
                self.showAlert = true
            }
        }
    }
}

// MARK: - Info Row Component for Detail View
struct DetailInfoRow: View {
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
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
            
            if !isMultiline {
                Spacer()
            }
        }
    }
}
