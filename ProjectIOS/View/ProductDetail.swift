import SwiftUI
import Firebase
import FirebaseAuth
/// **ProductDetail** - แสดงรายละเอียดสินค้า และให้ผู้ใช้สามารถเพิ่มสินค้าลงในตะกร้า
struct ProductDetail: View {
    let product: ProductItemm
    @State private var isAddedToCart = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 20) {
            // โหลดและแสดงภาพสินค้า
            if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    } else if phase.error != nil {
                        Text("Image Error").foregroundColor(.red)
                    } else {
                        ProgressView()
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 200)
            }

            // ข้อมูลสินค้า
            VStack(spacing: 8) {
                Text(product.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // ✅ Fixed price display with proper error handling
                Text("\(formatPrice(product.price)) ฿")
                    .font(.title)
                    .foregroundColor(.red)
                
                // เพิ่มรายละเอียดสินค้า
                Text(product.detail)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // แสดงข้อมูลผู้ขาย
                Text("Seller: \(product.sellerName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // ปุ่มเพิ่มสินค้าลงตะกร้า
            Button(action: {
                addToCart()
            }) {
                HStack {
                    Image(systemName: isAddedToCart ? "checkmark.circle.fill" : "cart.fill")
                    Text(isAddedToCart ? "Added to Cart" : "Add to Cart")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isAddedToCart ? Color.green : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .disabled(isAddedToCart)

            Spacer()
        }
        .padding()
        .navigationTitle("Product Detail")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cart", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    /// ✅ Helper function to safely format price
    private func formatPrice(_ priceString: String) -> String {
        // Try to convert string to double
        if let price = Double(priceString) {
            return String(format: "%.2f", price)
        }
        
        // If conversion fails, try to clean the string and convert again
        let cleanedPrice = priceString.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        if let price = Double(cleanedPrice) {
            return String(format: "%.2f", price)
        }
        
        // If all else fails, return the original string
        return priceString
    }

    /// เพิ่มสินค้าลงตะกร้าใน Firestore
    func addToCart() {
        // ✅ Check if user is authenticated
        guard let currentUser = Auth.auth().currentUser else {
            alertMessage = "Please log in to add items to cart"
            showingAlert = true
            return
        }
        
        // ✅ Use user-specific cart collection
        let cartRef = db.collection("users")
            .document(currentUser.uid)
            .collection("cart")
            .document(product.id)

        let newItem: [String: Any] = [
            "id": product.id,
            "name": product.name,
            "price": product.price,
            "detail": product.detail,
            "imageURL": product.imageURL ?? "",
            "sellerId": product.sellerId,
            "sellerName": product.sellerName,
            "status": product.status,
            "addedAt": FieldValue.serverTimestamp() // ✅ Add timestamp
        ]

        cartRef.setData(newItem) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error adding item to cart: \(error.localizedDescription)")
                    alertMessage = "Failed to add item to cart. Please try again."
                    showingAlert = true
                } else {
                    isAddedToCart = true
                    alertMessage = "Item added to cart successfully!"
                    showingAlert = true
                    
                    // ✅ Reset the button state after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isAddedToCart = false
                    }
                }
            }
        }
    }
}
