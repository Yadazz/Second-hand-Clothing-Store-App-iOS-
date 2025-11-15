import SwiftUI

struct TabMenuBuyer: View {
    var uid: String

    init(uid: String) {
        self.uid = uid
        UITabBar.appearance().backgroundColor = UIColor.black
        UITabBar.appearance().barTintColor = UIColor.black
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }
    
    var body: some View {
        TabView {
            ProductListBuyer()
                .tabItem {
                    Label("HOME", systemImage: "house")
                }
            
            ProductCart()
                .tabItem {
                    Label("CARTS", systemImage: "cart")
                }
            
            NotificationsView()
                .tabItem {
                    Label("NOTIFICATIONS", systemImage: "bell")
                }
            
            ProfileView(uid: uid)
                .tabItem {
                    Label("PROFILE", systemImage: "person.crop.circle")
                }
        }
        .accentColor(.yellow) // ไอคอนและตัวหนังสือของ item ที่ถูกเลือกเป็นสีเหลือง
        .navigationBarHidden(true)
    }
}

#Preview {
    TabMenuBuyer(uid: "EyncxZ6Fu8gh4sqTyF6Ed5Vp6OD3")
}
