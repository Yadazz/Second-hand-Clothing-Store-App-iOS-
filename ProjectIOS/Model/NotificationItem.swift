import Foundation
import FirebaseFirestore

struct NotificationItem: Identifiable {
    var id: String
    var title: String
    var message: String
    var type: String
    var sellerId: String
    var buyerId: String
    var orderId: String
    var timestamp: Timestamp
    var isRead: Bool
    var productId: String
    var trackingStatus: String?
    var trackingNumber: String?// ฟิลด์สำหรับสถานะการกรอกหมายเลขพัสดุ
}
