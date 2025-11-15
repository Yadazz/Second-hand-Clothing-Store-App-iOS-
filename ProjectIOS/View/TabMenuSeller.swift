import SwiftUI

struct TabMenuSeller: View {
    var uid: String

    init(uid: String) {
        self.uid = uid
        UITabBar.appearance().backgroundColor = UIColor.black
        UITabBar.appearance().barTintColor = UIColor.black
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }

    var body: some View {
        TabView {
            ProductListSeller()
                .tabItem {
                    Label("HOME", systemImage: "house")
                }

            PostProductView()
                .tabItem {
                    Label("ADD", systemImage: "plus")
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
        .accentColor(.yellow)
        .navigationBarHidden(true)
    }
}

#Preview {
    TabMenuSeller(uid: "qe7bsnfUnDeQI0gXMMGiNNocAVh1")
}

