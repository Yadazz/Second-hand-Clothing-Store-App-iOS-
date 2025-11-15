import SwiftUI
import Firebase
import FirebaseAuth

struct CartItemView: View {
    let item: ProductItemm
    let onRemove: () -> Void

    @State private var sellerUsername: String = ""
    @State private var isLoadingUsername: Bool = true
    @State private var userName: String = ""
    @State private var userAddress: String = ""
    @State private var phoneNumber: String = ""

    // New state for alert and navigation
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToCheckout = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Seller Header with theme styling
            HStack {
                Text("Mall")
                    .font(.subheadline)
                    .foregroundColor(.yellow)
                    .fontWeight(.bold)
                Text(sellerUsername)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.4))

            // Main content area
            HStack(spacing: 12) {
                // Product Image
                if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.title2)
                            )
                    }
                }

                // Product Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Text(item.sellerName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack {
                        Text("\(item.price) ฿")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                        
                        Spacer()
                    }
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 8) {
                    // Remove Button
                    Button(action: onRemove) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.8))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }

                    // Purchase Button
                    Button(action: {
                        checkIfProductAlreadyOrdered()
                    }) {
                        Text("Purchase")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .frame(minWidth: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .disabled(sellerUsername.isEmpty || userName.isEmpty || userAddress.isEmpty)
                    .opacity((sellerUsername.isEmpty || userName.isEmpty || userAddress.isEmpty) ? 0.5 : 1.0)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.3))

            // NavigationLink triggered programmatically
            NavigationLink(
                destination: CheckoutView(
                    productId: item.id,
                    productName: item.name,
                    productPrice: Double(item.price) ?? 0.0,
                    userName: userName,
                    userAddress: userAddress,
                    phoneNumber: phoneNumber,
                    shopName: item.sellerName,
                    sellerId: item.sellerId,
                    productImageURL: item.imageURL
                ),
                isActive: $navigateToCheckout
            ) {
                EmptyView()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onAppear {
            fetchSellerUsername()
            fetchCurrentUserDetails()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Alert")
                    .foregroundColor(.white),
                message: Text(alertMessage)
                    .foregroundColor(.white),
                dismissButton: .default(Text("OK").foregroundColor(.blue))
            )
        }
    }

    func fetchSellerUsername() {
        guard !item.sellerId.isEmpty else {
            sellerUsername = "Unknown Seller"
            isLoadingUsername = false
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(item.sellerId).getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching seller username: \(error.localizedDescription)")
                    sellerUsername = item.sellerName
                } else if let document = document, document.exists {
                    sellerUsername = document.data()?["username"] as? String ?? item.sellerName
                } else {
                    sellerUsername = item.sellerName
                }
                isLoadingUsername = false
            }
        }
    }

    func fetchCurrentUserDetails() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let data = document?.data() {
                userName = data["username"] as? String ?? ""
                userAddress = data["address"] as? String ?? ""
                phoneNumber = data["phoneNumber"] as? String ?? ""
            }
        }
    }

    func checkIfProductAlreadyOrdered() {
        let db = Firestore.firestore()
        db.collection("orders")
            .whereField("productId", isEqualTo: item.id)
            .getDocuments { snapshot, error in
                if let error = error {
                    alertMessage = "An error occurred while verifying the order.: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                if let documents = snapshot?.documents, !documents.isEmpty {
                    alertMessage = "This product has been ordered."
                    showAlert = true
                } else {
                    navigateToCheckout = true
                }
            }
    }
}
