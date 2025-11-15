import SwiftUI
import Firebase
import FirebaseAuth

struct ProductListBuyer: View {
    @State private var products: [ProductItemm] = []
    @State private var filteredProducts: [ProductItemm] = []
    @State private var isLoading = true
    @State private var errorMessage: String = ""
    @State private var searchText: String = ""
    @State private var selectedProduct: ProductItemm?
    @State private var navigateToDetail = false
    
    // State to track scroll position
    @State private var scrollPosition: ScrollPosition?
    @State private var rememberedPosition: String?
    
    // ✅ เพิ่ม listeners เพื่อเก็บ Firestore listeners
    @State private var listeners: [ListenerRegistration] = []
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // Background
                Color(hue: 0.13, saturation: 0.4, brightness: 0.5)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar with fixed position at top
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

                    if isLoading {
                        // Loading indicator
                        ProgressView("Loading products...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        if filteredProducts.isEmpty {
                            Text("No products available")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // Product grid with scroll position management
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                                    ForEach(filteredProducts) { product in
                                        ProductCard(product: product)
                                            .id(product.id)
                                            .onTapGesture {
                                                selectedProduct = product
                                                navigateToDetail = true
                                            }
                                    }
                                }
                                .padding()
                            }
                            .scrollPosition(id: $scrollPosition)
                            .onChange(of: scrollPosition) { newValue in
                                if let position = newValue {
                                    rememberedPosition = position.id
                                }
                            }
                        }
                    }
                }
                
                // Navigation link to product detail
                NavigationLink(
                    destination: selectedProduct.map { ProductDetailView(product: $0) },
                    isActive: $navigateToDetail,
                    label: { EmptyView() }
                )
            }
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if listeners.isEmpty {
                    setupRealtimeListeners()
                } else if let savedId = rememberedPosition {
                    // Restore scroll position when view reappears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollPosition = ScrollPosition(id: savedId)
                    }
                }
            }
            .onDisappear {
                // ✅ Clean up listeners เมื่อออกจากหน้า
                removeListeners()
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
        }
    }

    // Extracted product card view for better organization
    struct ProductCard: View {
        let product: ProductItemm
        
        var body: some View {
            VStack {
                // Product image
                if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .cornerRadius(10)
                    } placeholder: {
                        Color.gray.frame(width: 150, height: 150)
                    }
                } else {
                    Color.gray.frame(width: 150, height: 150)
                        .cornerRadius(10)
                }

                // Product details
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(2)
                    
                    Text("\(product.price) ฿")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    
                    // Status indicator
                    HStack {
                        Text("Status:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(product.status.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor(for: product.status))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    }
                    
                    // Seller name
                    Text("Seller: \(product.sellerName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)
        }
        
        // Status color function
        func statusColor(for status: String) -> Color {
            switch status.lowercased() {
            case "available":
                return Color.green.opacity(0.8)
            case "sold":
                return Color.red.opacity(0.8)
            case "reserved":
                return Color.orange.opacity(0.8)
            case "no status":
                return Color.gray.opacity(0.6)
            default:
                return Color.gray.opacity(0.8)
            }
        }
    }

    // ✅ ใหม่: ฟังก์ชันสำหรับตั้งค่า Real-time listeners
    func setupRealtimeListeners() {
        let db = Firestore.firestore()
        
        // Query sellers และตั้งค่า listener
        let sellersListener = db.collection("users")
            .whereField("role", isEqualTo: "Seller")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to load sellers: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }
                
                // Clear existing product listeners
                removeProductListeners()
                
                // If no sellers, mark as done loading
                if documents.isEmpty {
                    DispatchQueue.main.async {
                        self.products = []
                        self.filteredProducts = []
                        self.isLoading = false
                    }
                    return
                }
                
                // Setup product listeners for each seller
                setupProductListeners(for: documents)
            }
        
        listeners.append(sellersListener)
    }
    
    // ✅ ใหม่: ฟังก์ชันสำหรับตั้งค่า product listeners สำหรับแต่ละ seller
    func setupProductListeners(for sellerDocuments: [QueryDocumentSnapshot]) {
        let dispatchGroup = DispatchGroup()
        var allProducts: [ProductItemm] = []
        
        for document in sellerDocuments {
            let userId = document.documentID
            let sellerData = document.data()
            let sellerName = sellerData["username"] as? String ?? "Unknown Seller"
            
            dispatchGroup.enter()
            
            // ตั้งค่า listener สำหรับ products ของแต่ละ seller
            let productListener = Firestore.firestore()
                .collection("users").document(userId).collection("products")
                .whereField("status", isEqualTo: "available")
                .addSnapshotListener { productSnapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Error loading products for seller \(sellerName): \(error.localizedDescription)")
                        return
                    }
                    
                    guard let productDocuments = productSnapshot?.documents else { return }
                    
                    // ลบ products เก่าของ seller นี้
                    allProducts.removeAll { $0.sellerId == userId }
                    
                    // เพิ่ม products ใหม่
                    for productDocument in productDocuments {
                        let productData = productDocument.data()
                        
                        guard let name = productData["name"] as? String,
                              let detail = productData["detail"] as? String else {
                            continue
                        }
                        
                        // Handle price conversion
                        let price: String
                        if let priceDouble = productData["price"] as? Double {
                            price = String(format: "%.2f", priceDouble)
                        } else if let priceString = productData["price"] as? String {
                            price = priceString
                        } else {
                            continue
                        }
                        
                        let status = productData["status"] as? String ?? "available"
                        let imageURL = productData["imageURL"] as? String
                        
                        let product = ProductItemm(
                            id: productDocument.documentID,
                            name: name,
                            price: price,
                            detail: detail,
                            imageURL: imageURL,
                            sellerName: sellerName,
                            sellerId: userId,
                            status: status
                        )
                        
                        allProducts.append(product)
                    }
                    
                    // Update UI
                    DispatchQueue.main.async {
                        self.products = allProducts
                        self.filterProducts()
                        if self.isLoading {
                            self.isLoading = false
                        }
                    }
                }
            
            listeners.append(productListener)
        }
    }
    
    // ✅ ใหม่: ฟังก์ชันสำหรับลบ product listeners
    func removeProductListeners() {
        // Keep only the first listener (sellers listener) and remove product listeners
        if listeners.count > 1 {
            for i in 1..<listeners.count {
                listeners[i].remove()
            }
            listeners = Array(listeners.prefix(1))
        }
    }
    
    // ✅ ใหม่: ฟังก์ชันสำหรับลบ listeners ทั้งหมด
    func removeListeners() {
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }

    func filterProducts() {
        if searchText.isEmpty {
            filteredProducts = products
        } else {
            filteredProducts = products.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

// Define ScrollPosition struct for tracking
struct ScrollPosition: Hashable {
    let id: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ScrollPosition, rhs: ScrollPosition) -> Bool {
        return lhs.id == rhs.id
    }
}

#Preview {
    ProductListBuyer()
}
