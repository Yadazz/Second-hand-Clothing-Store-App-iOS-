import SwiftUI
import Firebase
import FirebaseAuth

struct ProductCart: View {
    @State private var cartItems: [ProductItemm] = []
    @State private var isLoading = false
    @State private var totalPrice: Double = 0.0

    var body: some View {
        NavigationView {
            ZStack {
                Color(hue: 0.13, saturation: 0.4, brightness: 0.5)
                    .ignoresSafeArea()

                VStack {
                    if isLoading {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack {
                                ForEach(cartItems) { item in
                                    CartItemView(item: item) {
                                        removeItemFromCart(item: item)
                                    }
                                }
                            }
                        }

                        HStack {
                            Text("Total")
                                .font(.headline)
                                .foregroundColor(.black)
                            Spacer()
                            Text("\(totalPrice, specifier: "%.2f") ฿")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .disabled(cartItems.isEmpty)
                    }
                }
                .onAppear {
                    loadCartItems()
                }
            }
            .navigationTitle("Shopping Cart")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func loadCartItems() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }

        let db = Firestore.firestore()
        isLoading = true
        db.collection("users").document(userId).collection("cart").getDocuments { snapshot, error in
            isLoading = false
            if let error = error {
                print("Error loading cart items: \(error.localizedDescription)")
                return
            }

            if let documents = snapshot?.documents {
                var items: [ProductItemm] = []
                var total: Double = 0.0

                for document in documents {
                    let data = document.data()
                    if let name = data["name"] as? String,
                       let price = data["price"] as? String,
                       let detail = data["detail"] as? String,
                       let sellerName = data["sellerName"] as? String,
                       let sellerId = data["sellerId"] as? String {

                        let imageURL = data["imageURL"] as? String
                        let status = data["status"] as? String ?? "available"

                        let product = ProductItemm(
                            id: document.documentID,
                            name: name,
                            price: price,
                            detail: detail,
                            imageURL: imageURL,
                            sellerName: sellerName,
                            sellerId: sellerId,
                            status: status
                        )

                        if let productPrice = Double(price) {
                            total += productPrice
                        } else if let priceDouble = data["price"] as? Double {
                            total += priceDouble
                            items.append(ProductItemm(
                                id: document.documentID,
                                name: name,
                                price: String(format: "%.2f", priceDouble),
                                detail: detail,
                                imageURL: imageURL,
                                sellerName: sellerName,
                                sellerId: sellerId,
                                status: status
                            ))
                            continue
                        }

                        items.append(product)
                    }
                }
                self.cartItems = items
                self.totalPrice = total
            }
        }
    }

    func removeItemFromCart(item: ProductItemm) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("cart").document(item.id).delete { error in
            if let error = error {
                print("Error removing item from cart: \(error.localizedDescription)")
            } else {
                loadCartItems()
                print("Item successfully removed from cart.")
            }
        }
    }
}

#Preview {
    ProductCart()
}
