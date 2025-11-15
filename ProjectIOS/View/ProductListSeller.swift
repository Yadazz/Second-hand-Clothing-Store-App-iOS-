import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProductListSeller: View {
    @State private var products: [ProductItemm] = []
    @State private var filteredProducts: [ProductItemm] = []
    @State private var searchText: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String = ""
    @State private var showAlert = false
    @State private var selectedProduct: ProductItemm? = nil

    let backgroundColor = Color(red: 130/255, green: 116/255, blue: 70/255)
    let fieldBackgroundColor = Color(red: 190/255, green: 177/255, blue: 134/255)
    let buttonColor = Color(red: 97/255, green: 73/255, blue: 40/255)

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading products...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .font(.title2)
                } else {
                    if products.isEmpty {
                        Text("No products available")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        VStack(spacing: 0) {
                            // Search Bar
                            HStack {
                                TextField("Search products...", text: $searchText)
                                    .padding(.horizontal)
                                    .frame(height: 40)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                    .onChange(of: searchText) { _ in
                                        filterProducts()
                                    }

                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color(hue: 0.13, saturation: 0.4, brightness: 0.5))

                            // List
                            List {
                                ForEach(filteredProducts) { product in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(alignment: .top) {
                                            if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                                                AsyncImage(url: url) { image in
                                                    image.resizable()
                                                        .scaledToFill()
                                                        .frame(width: 100, height: 100)
                                                        .cornerRadius(8)
                                                } placeholder: {
                                                    fieldBackgroundColor
                                                        .frame(width: 100, height: 100)
                                                        .cornerRadius(8)
                                                        .overlay(
                                                            ProgressView()
                                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                        )
                                                }
                                            } else {
                                                fieldBackgroundColor
                                                    .frame(width: 100, height: 100)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        Image(systemName: "photo")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 40, height: 40)
                                                            .foregroundColor(.white.opacity(0.6))
                                                    )
                                            }

                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(product.name)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                
                                                Text("Price: \(product.price) ฿")
                                                    .foregroundColor(.white.opacity(0.7))
                                                
                                                HStack {
                                                    Text("Status:")
                                                        .foregroundColor(.white.opacity(0.7))
                                                    
                                                    Text(product.status.capitalized)
                                                        .foregroundColor(.white)
                                                        .fontWeight(.medium)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 2)
                                                        .background(statusColor(for: product.status))
                                                        .cornerRadius(4)
                                                }
                                            }

                                            Spacer()
                                        }

                                        HStack(spacing: 20) {
                                            NavigationLink(destination: EditProductView(product: product)) {
                                                Label("Edit", systemImage: "pencil.circle")
                                                    .foregroundColor(buttonColor)
                                                    .fontWeight(.bold)
                                            }
                                            .buttonStyle(PlainButtonStyle())

                                            Button(action: {
                                                selectedProduct = product
                                                showAlert = true
                                            }) {
                                                Label("Delete", systemImage: "trash.circle")
                                                    .foregroundColor(.black)
                                                    .fontWeight(.bold)
                                            }
                                            .buttonStyle(PlainButtonStyle())

                                            Spacer()
                                        }
                                        .padding(.top, 4)
                                    }
                                    .padding(.vertical, 8)
                                    .listRowBackground(fieldBackgroundColor.opacity(0.6))
                                }
                            }
                            .listStyle(PlainListStyle())
                            .refreshable {
                                await refreshProducts()
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                
                // Error message display
                if !errorMessage.isEmpty {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .padding()
                    }
                }
            }
            .navigationBarTitle("Product List", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Confirm Deletion"),
                    message: Text("Are you sure you want to delete this product?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let productToDelete = selectedProduct {
                            deleteProduct(productToDelete)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                loadProducts()
            }
        }
    }
    
    func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "available":
            return Color.green.opacity(0.7)
        case "sold":
            return Color.red.opacity(0.7)
        case "reserved":
            return Color.orange.opacity(0.7)
        case "no status":
            return Color.gray.opacity(0.5)
        default:
            return Color.gray.opacity(0.7)
        }
    }

    func loadProducts() {
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "You need to be logged in to view products."
            self.isLoading = false
            return
        }

        let db = Firestore.firestore()
        
        // Get current user's data first to get sellerName
        db.collection("users").document(user.uid).getDocument { userDoc, error in
            let sellerName = userDoc?.data()?["username"] as? String ?? "Unknown Seller"
            
            // ใช้ addSnapshotListener เพื่อ real-time updates
            db.collection("users").document(user.uid).collection("products")
                .addSnapshotListener { snapshot, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                            self.isLoading = false
                            return
                        }

                        if let snapshot = snapshot {
                            self.products = snapshot.documents.compactMap { document in
                                let data = document.data()
                                
                                // Debug: พิมพ์ข้อมูลที่ได้จาก Firebase
                                print("Document ID: \(document.documentID)")
                                print("Document data: \(data)")
                                
                                guard let name = data["name"] as? String,
                                      let detail = data["detail"] as? String else {
                                    print("Missing required fields for document: \(document.documentID)")
                                    return nil
                                }
                                
                                let price: String
                                if let priceDouble = data["price"] as? Double {
                                    price = String(format: "%.2f", priceDouble)
                                } else if let priceString = data["price"] as? String {
                                    price = priceString
                                } else {
                                    print("Invalid price for document: \(document.documentID)")
                                    return nil
                                }
                                
                                // อ่าน status จาก Firebase และแสดงข้อความที่เหมาะสมหากไม่มี
                                let status = data["status"] as? String ?? "No Status"
                                
                                // Debug: แสดง status ที่อ่านได้
                                print("Product: \(name), Status from Firebase: '\(status)'")
                                
                                let imageURL = data["imageURL"] as? String

                                return ProductItemm(
                                    id: document.documentID,
                                    name: name,
                                    price: price,
                                    detail: detail,
                                    imageURL: imageURL,
                                    sellerName: sellerName,
                                    sellerId: user.uid,
                                    status: status
                                )
                            }
                            
                            // Sort products by creation date if available
                            self.products.sort { product1, product2 in
                                // สามารถเพิ่มการเรียงลำดับตาม createdAt ได้ถ้าต้องการ
                                return product1.name < product2.name
                            }
                            
                            self.filteredProducts = self.products
                            self.isLoading = false
                            self.errorMessage = ""
                            
                            // Debug: แสดงจำนวนสินค้าที่โหลดได้
                            print("Loaded \(self.products.count) products")
                            for product in self.products {
                                print("- \(product.name): \(product.status)")
                            }
                        }
                    }
                }
        }
    }
    
    // เพิ่มฟังก์ชัน refresh สำหรับ pull-to-refresh
    func refreshProducts() async {
        await withCheckedContinuation { continuation in
            guard let user = Auth.auth().currentUser else {
                continuation.resume()
                return
            }

            let db = Firestore.firestore()
            
            // Get current user's data first to get sellerName
            db.collection("users").document(user.uid).getDocument { userDoc, error in
                let sellerName = userDoc?.data()?["username"] as? String ?? "Unknown Seller"
                
                db.collection("users").document(user.uid).collection("products")
                    .getDocuments { snapshot, error in
                        DispatchQueue.main.async {
                            if let error = error {
                                self.errorMessage = "Failed to refresh products: \(error.localizedDescription)"
                            } else if let snapshot = snapshot {
                                self.products = snapshot.documents.compactMap { document in
                                    let data = document.data()
                                    guard let name = data["name"] as? String,
                                          let detail = data["detail"] as? String else {
                                        return nil
                                    }
                                    
                                    let price: String
                                    if let priceDouble = data["price"] as? Double {
                                        price = String(format: "%.2f", priceDouble)
                                    } else if let priceString = data["price"] as? String {
                                        price = priceString
                                    } else {
                                        return nil
                                    }
                                    
                                    let status = data["status"] as? String ?? "available"
                                    let imageURL = data["imageURL"] as? String

                                    return ProductItemm(
                                        id: document.documentID,
                                        name: name,
                                        price: price,
                                        detail: detail,
                                        imageURL: imageURL,
                                        sellerName: sellerName,
                                        sellerId: user.uid,
                                        status: status
                                    )
                                }
                                self.filteredProducts = self.products
                            }
                            continuation.resume()
                        }
                    }
            }
        }
    }

    func deleteProduct(_ product: ProductItemm) {
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "You need to be logged in to delete products."
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("products").document(product.id).delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to delete product: \(error.localizedDescription)"
                } else {
                    // ไม่จำเป็นต้องลบจาก array เองเพราะ listener จะอัพเดตให้อัตโนมัติ
                    self.errorMessage = ""
                }
            }
        }
    }

    func filterProducts() {
        if searchText.isEmpty {
            filteredProducts = products
        } else {
            filteredProducts = products.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

#Preview {
    ProductListSeller()
}
