import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct NotificationsView: View {
    @State private var notifications: [NotificationItem] = []
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Same background color as Login/SignUp
                Color(hue: 0.13, saturation: 0.4, brightness: 0.5)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    VStack {
                        Text("NOTIFICATIONS")
                            .foregroundColor(.white)
                            .font(.system(size: 24, weight: .bold))
                            .padding(.top, 20)
                            .padding(.bottom, 15)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.3))
                    
                    // Content Area
                    Group {
                        if isLoading && notifications.isEmpty {
                            loadingView
                        } else if notifications.isEmpty && !isLoading {
                            emptyStateView
                        } else {
                            notificationsList
                        }
                    }
                    .background(Color(hue: 0.13, saturation: 0.4, brightness: 0.5))
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await refreshNotifications()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            fetchNotifications()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("Loading notifications...")
                .foregroundColor(.white)
                .font(.custom("Amiri", size: 14))
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.circle")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.6))
            
            Text("NO NOTIFICATIONS")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("You'll see order updates and delivery notifications here")
                .font(.custom("Amiri", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("REFRESH") {
                fetchNotifications()
            }
            .foregroundColor(.white)
            .frame(width: 150, height: 20)
            .font(.system(size: 16))
            .padding()
            .background(Color.black)
            .cornerRadius(10)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Notifications List
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach($notifications) { $notification in
                    NavigationLink(destination: destinationView(for: notification)) {
                        NotificationRow(notification: notification)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded {
                                // Mark as read when tapped
                                markNotificationAsRead(notification: $notification)
                            }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .overlay(
            Group {
                if isRefreshing {
                    VStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Refreshing...")
                            .font(.custom("Amiri", size: 12))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                }
            }
        )
    }

    @ViewBuilder
    func destinationView(for notification: NotificationItem) -> some View {
        if notification.type == "order" {
            NotificationDetailView(notification: notification)
        } else if notification.type == "delivery" {
            NotificationBuyerView(notification: notification)
        } else {
            ZStack {
                Color(hue: 0.13, saturation: 0.4, brightness: 0.5)
                    .ignoresSafeArea()
                
                VStack {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                    Text("Unknown notification type")
                        .foregroundColor(.white)
                        .font(.custom("Amiri", size: 14))
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Mark Notification as Read
    private func markNotificationAsRead(notification: Binding<NotificationItem>) {
        if !notification.wrappedValue.isRead {
            // Update local state immediately
            notification.wrappedValue.isRead = true
            
            // Update Firestore
            let db = Firestore.firestore()
            db.collection("notifications").document(notification.wrappedValue.id).updateData([
                "isRead": true
            ]) { error in
                if let error = error {
                    print("Error updating notification: \(error.localizedDescription)")
                    // Revert local state if update fails
                    DispatchQueue.main.async {
                        notification.wrappedValue.isRead = false
                    }
                } else {
                    print("Notification marked as read")
                }
            }
        }
    }

    // MARK: - Refresh Function
    @MainActor
    func refreshNotifications() async {
        isRefreshing = true
        fetchNotifications()
        // Simulate network delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000)
        isRefreshing = false
    }

    func fetchNotifications() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            handleError("User is not logged in")
            return
        }

        let db = Firestore.firestore()
        var tempNotifications: [NotificationItem] = []
        let dispatchGroup = DispatchGroup()
        
        // Fetch seller notifications
        dispatchGroup.enter()
        let sellerNotificationsQuery = db.collection("notifications")
            .whereField("sellerId", isEqualTo: currentUserId)
            .whereField("type", isEqualTo: "order")

        sellerNotificationsQuery.getDocuments { snapshot, error in
            defer { dispatchGroup.leave() }
            
            if let error = error {
                print("Error fetching seller notifications: \(error.localizedDescription)")
            } else if let snapshot = snapshot {
                let items = snapshot.documents.compactMap { doc in
                    parseNotification(from: doc)
                }
                tempNotifications.append(contentsOf: items)
            }
        }
        
        // Fetch buyer notifications
        dispatchGroup.enter()
        let buyerNotificationsQuery = db.collection("notifications")
            .whereField("buyerId", isEqualTo: currentUserId)
            .whereField("type", isEqualTo: "delivery")

        buyerNotificationsQuery.getDocuments { snapshot, error in
            defer { dispatchGroup.leave() }
            
            if let error = error {
                print("Error fetching buyer notifications: \(error.localizedDescription)")
            } else if let snapshot = snapshot {
                let items = snapshot.documents.compactMap { doc in
                    parseNotification(from: doc)
                }
                tempNotifications.append(contentsOf: items)
            }
        }
        
        // Wait for both queries to complete
        dispatchGroup.notify(queue: .main) {
            self.notifications = tempNotifications.sorted {
                $0.timestamp.dateValue() > $1.timestamp.dateValue()
            }
            self.isLoading = false
        }
    }
    
    func parseNotification(from doc: QueryDocumentSnapshot) -> NotificationItem {
        let data = doc.data()
        var trackingStatus: String = "Not entered"
        
        if let number = data["trackingNumber"] as? String, !number.isEmpty {
            trackingStatus = "Entered"
        }

        return NotificationItem(
            id: doc.documentID,
            title: data["title"] as? String ?? "No Title",
            message: data["message"] as? String ?? "No Message",
            type: data["type"] as? String ?? "Unknown",
            sellerId: data["sellerId"] as? String ?? "",
            buyerId: data["buyerId"] as? String ?? "",
            orderId: data["orderId"] as? String ?? "",
            timestamp: data["timestamp"] as? Timestamp ?? Timestamp(),
            isRead: data["isRead"] as? Bool ?? false,
            productId: data["productId"] as? String ?? "",
            trackingStatus: trackingStatus,
            trackingNumber: data["trackingNumber"] as? String
        )
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        showError = true
        isLoading = false
    }
}

// MARK: - Notification Row Component
struct NotificationRow: View {
    let notification: NotificationItem

    var body: some View {
        HStack(spacing: 12) {
            notificationIcon
                .frame(width: 40, height: 40)
                .background(iconBackgroundColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 16, weight: notification.isRead ? .medium : .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if !notification.isRead {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(notification.message)
                    .font(.custom("Amiri", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                HStack {
                    Text(timeAgoString(from: notification.timestamp.dateValue()))
                        .font(.custom("Amiri", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    TrackingStatusBadge(status: notification.trackingStatus)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(notification.isRead ? Color.black.opacity(0.3) : Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(notification.isRead ? Color.white.opacity(0.2) : Color.yellow.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    private var notificationIcon: some View {
        Group {
            switch notification.type {
            case "order":
                Image(systemName: "cart.fill")
                    .foregroundColor(.white)
            case "delivery":
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.white)
            default:
                Image(systemName: "bell.fill")
                    .foregroundColor(.white)
            }
        }
        .font(.system(size: 16))
    }
    
    private var iconBackgroundColor: Color {
        switch notification.type {
        case "order":
            return Color.blue.opacity(0.3)
        case "delivery":
            return Color.green.opacity(0.3)
        default:
            return Color.gray.opacity(0.3)
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Tracking Status Badge
struct TrackingStatusBadge: View {
    let status: String?
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(displayText)
                .font(.custom("Amiri", size: 10))
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case "Entered":
            return .yellow
        default:
            return .orange
        }
    }
    
    private var displayText: String {
        switch status {
        case "Entered":
            return "TRACKING AVAILABLE"
        default:
            return "AWAITING TRACKING"
        }
    }
}

#Preview {
    NotificationsView()
}
