import SwiftUI
import Firebase
import FirebaseFirestore

struct NotificationBuyerView: View {
    let notification: NotificationItem
    
    @State private var orderData: [String: Any]?
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showImageViewer = false
    @State private var imageToShow: UIImage?
    @State private var productImageURL: String?
    
    // MARK: - Theme Colors (เดียวกับ NotificationDetailView)
    let backgroundColor = Color(red: 130/255, green: 116/255, blue: 70/255)
    let fieldBackgroundColor = Color(red: 190/255, green: 177/255, blue: 134/255)
    let buttonColor = Color(red: 97/255, green: 73/255, blue: 40/255)
    let cardBackgroundColor = Color(red: 160/255, green: 147/255, blue: 104/255)
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                if isLoading {
                    loadingView
                } else if let data = orderData {
                    orderSummaryView(data: data)
                } else {
                    errorStateView
                }
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(backgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            fetchOrderData()
        }
        .alert("Info", isPresented: $showAlert) {
            Button("OK") { }
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
    
    // MARK: - Order Summary View
    @ViewBuilder
    func orderSummaryView(data: [String: Any]) -> some View {
        LazyVStack(spacing: 20) {
            // Order Status Header
            orderStatusCard(data: data)
            
            // Product Information Card
            productInfoCard(data: data)
            
            // Shipping Information Card
            shippingInfoCard(data: data)
            
            // Payment Information Card
            paymentInfoCard(data: data)
        }
        .padding()
    }

    // MARK: - Order Status Card
    @ViewBuilder
    func orderStatusCard(data: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: getStatusIcon(for: data))
                    .foregroundColor(.white)
                Text(getStatusText(for: data))
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
                        Text(formatDate(date))
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
                if let imageUrlString = data["productImageURL"] as? String,
                   let url = URL(string: imageUrlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
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

                BuyerInfoRow(label: "Product:", value: data["productName"] as? String ?? "N/A")
                
                HStack {
                    Text("Price:")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(String(format: "%.2f", data["productPrice"] as? Double ?? 0)) ฿")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                BuyerInfoRow(label: "Shop:", value: data["shopName"] as? String ?? "N/A")
                
                if let date = (data["orderDate"] as? Timestamp)?.dateValue() {
                    BuyerInfoRow(label: "Order Date:", value: formatDate(date))
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Shipping Information Card
    @ViewBuilder
    func shippingInfoCard(data: [String: Any]) -> some View {
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
            
            VStack(spacing: 10) {
                BuyerInfoRow(label: "Delivery Address:",
                       value: data["buyerAddress"] as? String ?? "N/A")
                
                // Tracking Number with enhanced UI
                HStack(alignment: .top) {
                    Text("Tracking Number:")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    
                    if let trackingNumber = data["trackingNumber"] as? String, !trackingNumber.isEmpty {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(trackingNumber)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .textSelection(.enabled)
                            
                            Button(action: {
                                UIPasteboard.general.string = trackingNumber
                                alertMessage = "Tracking number copied to clipboard!"
                                showAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(buttonColor.opacity(0.8))
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Not Available")
                                .foregroundColor(.white.opacity(0.7))
                            Text("Waiting for seller")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
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
                VStack(alignment: .leading, spacing: 8) {
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
    
    
    // MARK: - Helper Functions
    func fetchOrderData() {
        let db = Firestore.firestore()
        let orderId = notification.orderId
        
        db.collection("orders").document(orderId).getDocument { document, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    print("Error fetching order: \(error)")
                    return
                }
                
                if let document = document, document.exists {
                    orderData = document.data()
                    print("Fetched order data: \(orderData!)")
                    self.productImageURL = document.data()?["productImageURL"] as? String
                    print("Fetched product image URL: \(self.productImageURL ?? "No image URL")")
                    self.isLoading = false
                } else {
                    print("No matching order found.")
                }
            }
        }
    }
    
    func downloadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    alertMessage = "Failed to download image."
                    showAlert = true
                }
                return
            }
            
            if let image = UIImage(data: data) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                DispatchQueue.main.async {
                    alertMessage = "Image saved to your Photos."
                    showAlert = true
                }
            }
        }.resume()
    }
    
    func downloadAndShowImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    alertMessage = "Failed to load image."
                    showAlert = true
                }
                return
            }
            
            DispatchQueue.main.async {
                imageToShow = image
                showImageViewer = true
            }
        }.resume()
    }
    
    func getStatusIcon(for data: [String: Any]) -> String {
        if let _ = data["trackingNumber"] as? String {
            return "shippingbox.fill"
        } else {
            return "clock.fill"
        }
    }
    
    func getStatusColor(for data: [String: Any]) -> Color {
        if let _ = data["trackingNumber"] as? String {
            return .green
        } else {
            return .orange
        }
    }
    
    func getStatusText(for data: [String: Any]) -> String {
        if let _ = data["trackingNumber"] as? String {
            return "Order Shipped"
        } else {
            return "Processing Order"
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Info Row Component for Buyer View
struct BuyerInfoRow: View {
    var label: String
    var value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Timeline Item Component
struct TimelineItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isCompleted ? .white : .white.opacity(0.5))
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isCompleted ? .white : .white.opacity(0.7))
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

// MARK: - Image Viewer Sheet
struct ImageViewerSheet: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZoomableImageView(image: image)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        }
                    }
                }
        }
    }
}

// MARK: - Zoomable Image View
struct ZoomableImageView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale *= delta
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1.0 {
                                scale = 1.0
                                offset = .zero
                            } else if scale > 5.0 {
                                scale = 5.0
                            }
                        }
                        .simultaneously(with:
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        if scale == 1.0 {
                            scale = 2.0
                        } else {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
                }
        }
    }
}
