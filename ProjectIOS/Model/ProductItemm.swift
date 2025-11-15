import Foundation

struct ProductItemm: Identifiable {
    var id: String
    var name: String
    var price: String
    var detail: String
    var imageURL: String?
    var sellerName: String
    var sellerId: String
    var status: String // เพิ่ม status field ให้ตรงกับ ProductItem ใน ProductListSeller
}
