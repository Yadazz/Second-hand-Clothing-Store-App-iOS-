import SwiftUI
import Firebase
import FirebaseAuth

struct ProductDetailView: View {
    let product: ProductItemm
    @Environment(\.presentationMode) var presentationMode
    @State private var sellerUsername: String = ""
    @State private var isLoadingUsername: Bool = true

    // New states for alert
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Product image
                if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .clipped()
                            .cornerRadius(12)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .cornerRadius(12)
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .cornerRadius(12)
                }

                // Product name and price
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("\(product.price) ฿")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .padding(.bottom, 8)

                    Divider()

                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)

                        Text("Seller:")
                            .font(.headline)
                            .foregroundColor(.white)

                        Spacer()

                        if isLoadingUsername {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            NavigationLink(destination: SellerProfileView(sellerId: product.sellerId, sellerName: sellerUsername)) {
                                Text(sellerUsername)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .underline()
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    Divider()

                    Text("Product Details")
                        .font(.headline)
                        .padding(.top, 8)

                    Text(product.detail)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)

                    Spacer()

                    Button(action: {
                        addToCart()
                    }) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                            Text("Add to Cart")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 20)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hue: 0.13, saturation: 0.4, brightness: 0.5).ignoresSafeArea())

        .onAppear {
            fetchSellerUsername()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func fetchSellerUsername() {
        guard !product.sellerId.isEmpty else {
            sellerUsername = "Unknown Seller"
            isLoadingUsername = false
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(product.sellerId).getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    sellerUsername = product.sellerName
                } else if let document = document, document.exists {
                    sellerUsername = document.data()?["username"] as? String ?? product.sellerName
                } else {
                    sellerUsername = product.sellerName
                }
                isLoadingUsername = false
            }
        }
    }

    private func addToCart() {
        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "You must be logged in to add items to cart."
            showAlert = true
            return
        }

        let db = Firestore.firestore()

        let cartItemData: [String: Any] = [
            "productId": product.id,
            "name": product.name,
            "price": product.price,
            "detail": product.detail,
            "imageURL": product.imageURL ?? "",
            "sellerName": product.sellerName,
            "sellerId": product.sellerId
        ]

        db.collection("users").document(userId).collection("cart").document(product.id).setData(cartItemData) { error in
            if let error = error {
                alertMessage = "Failed to add product to cart: \(error.localizedDescription)"
                showAlert = true
            } else {
                alertMessage = "Product added to cart successfully!"
                showAlert = true
                // Optionally dismiss after alert confirmation, you can do so in alert's dismissButton handler if needed
                // presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
