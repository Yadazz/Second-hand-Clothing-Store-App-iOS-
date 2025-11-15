import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct SellerProfileView: View {
    let sellerId: String
    let sellerName: String
    
    @State private var products: [ProductItemm] = []
    @State private var isLoading = true
    @State private var sellerProfile: SellerProfile?
    @State private var errorMessage: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var isLoadingImage = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Profile Header
                VStack(alignment: .center, spacing: 16) {
                    if isLoadingImage {
                        ProgressView()
                            .frame(width: 100, height: 100)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                            .padding(.top, 20)
                    } else if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                            .padding(.top, 20)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.black)
                            .padding(.top, 20)
                    }
                    
                    if isLoading {
                        ProgressView("Loading profile...")
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text(sellerProfile?.username ?? sellerName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let bio = sellerProfile?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Contact Info Section
                        VStack(spacing: 8) {
                            if let contactInfo = sellerProfile?.contactInfo, !contactInfo.isEmpty {
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 20)
                                    Text(contactInfo)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Address Display
                            if let address = sellerProfile?.address, !address.isEmpty {
                                HStack(alignment: .top) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.white)
                                        .frame(width: 20)
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 10)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Products Section
                Text("Products by this Seller")
                    .font(.headline)
                    .padding(.horizontal)
                
                if isLoading {
                    ProgressView("Loading products...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if products.isEmpty {
                    Text("No products available from this seller")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(products) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                ProductCard(product: product)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color(hue: 0.13, saturation: 0.4, brightness: 0.5).ignoresSafeArea())
        .navigationTitle("Seller Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSellerProfile()
            loadSellerProducts()
        }
        .alert(isPresented: .constant(!errorMessage.isEmpty)) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                errorMessage = ""
            })
        }
    }
    
    // Product Card View for displaying products in grid
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
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 150)
                            .cornerRadius(10)
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 150)
                        .cornerRadius(10)
                }
                
                // Product details
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text("\(product.price) ฿")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    // Status indicator
                    HStack {
                        Text("Status:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(product.status.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(statusColor(for: product.status))
                            .cornerRadius(3)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .frame(width: 170, height: 260)
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
    
    // Function to load seller profile information
    private func loadSellerProfile() {
        let db = Firestore.firestore()
        db.collection("users").document(sellerId).getDocument { document, error in
            if let error = error {
                self.errorMessage = "Failed to load seller profile: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                
                self.sellerProfile = SellerProfile(
                    id: document.documentID,
                    username: data["username"] as? String ?? data["name"] as? String ?? sellerName,
                    bio: data["bio"] as? String ?? "",
                    contactInfo: data["contactInfo"] as? String ?? "",
                    address: data["address"] as? String ?? ""
                )
                
                // Load profile image if available
                if let profileImageURL = data["profileImageURL"] as? String, let url = URL(string: profileImageURL) {
                    loadProfileImage(from: url)
                } else {
                    self.isLoadingImage = false
                }
            } else {
                self.sellerProfile = SellerProfile(
                    id: sellerId,
                    username: sellerName,
                    bio: "",
                    contactInfo: "",
                    address: ""
                )
                self.isLoadingImage = false
            }
            
            self.isLoading = false
        }
    }
    
    // Function to load seller's profile image
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    self.profileImage = image
                }
                self.isLoadingImage = false
            }
        }.resume()
    }
    
    // Function to load all products from this seller
    private func loadSellerProducts() {
        let db = Firestore.firestore()
        db.collection("users").document(sellerId).collection("products")
            .whereField("status", isEqualTo: "available") // Only show available products
            .getDocuments { snapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                if let snapshot = snapshot {
                    self.products = snapshot.documents.compactMap { document in
                        let data = document.data()
                        
                        // ✅ Fixed: Added proper guard statement and return statement
                        guard let name = data["name"] as? String,
                              let detail = data["detail"] as? String else {
                            return nil
                        }
                        
                        // Handle price conversion
                        let price: String
                        if let priceDouble = data["price"] as? Double {
                            price = String(format: "%.2f", priceDouble)
                        } else if let priceString = data["price"] as? String {
                            price = priceString
                        } else {
                            return nil
                        }
                        
                        let imageURL = data["imageURL"] as? String
                        let status = data["status"] as? String ?? "available"
                        
                        return ProductItemm(
                            id: document.documentID,
                            name: name,
                            price: price,
                            detail: detail,
                            imageURL: imageURL,
                            sellerName: sellerName,
                            sellerId: sellerId,
                            status: status
                        )
                    }
                    
                    self.isLoading = false
                }
            }
    }
}

// Model for seller profile data - Updated to include address
struct SellerProfile: Identifiable {
    var id: String
    var username: String
    var bio: String
    var contactInfo: String
    var address: String // เพิ่ม address field
}

struct SellerProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SellerProfileView(
                sellerId: "sample-seller-id",
                sellerName: "Sample Seller"
            )
        }
    }
}
