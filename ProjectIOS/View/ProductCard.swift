import SwiftUI

/// **ProductCard** - ใช้แสดงข้อมูลสินค้าในรูปแบบการ์ดแนวตั้ง พร้อมสถานะสินค้า
struct ProductCard: View {
    let product: ProductItemm

    var body: some View {
        VStack(spacing: 0) {
            // รูปสินค้า
            if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .clipped()
                    } else if phase.error != nil {
                        Color.red.frame(height: 120)
                    } else {
                        Color.gray.opacity(0.3).frame(height: 120)
                    }
                }
            } else {
                Color.gray.opacity(0.3).frame(height: 120)
            }

            // ชื่อสินค้า ราคา และสถานะ
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text(product.status.capitalized)
                        .font(.caption2)
                        .foregroundColor(product.status.lowercased() == "available" ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)

                    Spacer()
                    Text("\(Double(product.price) ?? 0, specifier: "%.2f") ฿")
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }
            .padding(8)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Preview
#Preview {
    ProductCard(product: ProductItemm(
        id: "1",
        name: "Sample Product",
        price: "99.99",
        detail: "Example detail",
        imageURL: "https://via.placeholder.com/150",
        sellerName: "Sample Seller",
        sellerId: "seller123",
        status: "available"
    ))
}
