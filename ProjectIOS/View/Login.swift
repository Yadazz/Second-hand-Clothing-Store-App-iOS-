import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Login: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggedIn = false
    @State private var userRole: String = ""
    @State private var userUID = ""
    @State private var isLoggingIn = false


    var body: some View {
        NavigationView {
            ZStack {
                Color(hue: 0.13, saturation: 0.4, brightness: 0.5)
                    .ignoresSafeArea()
                
                VStack {
                    Image("Bag_duotone")
                        .padding()
                    
                    Group {
                        Text("EMAIL:")
                            .padding(5)
                            .foregroundColor(.white)
                            .frame(width: 350, height: 30, alignment: .leading)
                            .font(.custom("Amiri", size: 12))
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 350, height: 30)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        Text("PASSWORD:")
                            .foregroundColor(.white)
                            .padding(5)
                            .frame(width: 350, height: 30, alignment: .leading)
                            .font(.custom("Amiri", size: 12))
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 350, height: 30)
                    }
                    
                    Button(action: loginUser) {
                        Text("LOGIN")
                            .foregroundColor(.white)
                            .frame(width: 200, height: 20)
                            .font(.system(size: 20))
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                            .padding()
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }
                    
                    NavigationLink(destination: ResetPasswordView().tint(.white)) {
                        Text("FORGOT PASSWORD?")
                            .foregroundColor(.yellow)
                            .padding(5)
                            .font(.custom("Amiri", size: 12))
                            .underline(true, color: .yellow)
                    }
                  
                    
                    HStack {
                        Text("DON'T HAVE AN ACCOUNT?")
                            .foregroundColor(.white)
                            .padding(5)
                            .font(.custom("Amiri", size: 12))
                        
                        NavigationLink(destination: SignUp() .navigationBarBackButtonHidden(true)) {
                            Text("SIGN UP")
                                .foregroundColor(.yellow)
                                .padding(5)
                                .font(.custom("Amiri", size: 12))
                                .underline(true, color: .yellow)
                        }
                    }
                }
                .padding()
            }
            
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: Binding(
                get: { isLoggedIn && !userRole.isEmpty },
                set: { isLoggedIn = $0 }
            )) {
                    // แยก Navigation แบบปลอดภัยกว่า
                    switch userRole {
                    case "Seller":
                        TabMenuSeller(uid: userUID)
                    case "Buyer":
                        TabMenuBuyer(uid: userUID)
                    default:
                    VStack(spacing: 20) {
                        Text("❌ Unknown Role:")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        Text("Role ปัจจุบัน: '\(userRole)'")
                            .font(.headline)
                        
                        Text("UID: \(userUID)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Divider()
                        
                        Text("ลองกำหนดค่าโดยตรง:")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            Button("กำหนดเป็น Buyer") {
                                self.userRole = "Buyer"
                                // รอสักครู่ก่อนเปลี่ยนสถานะ
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    print("✅ กำหนดค่า userRole เป็น 'Buyer' และเปิดหน้า Buyer")
                                    self.isLoggedIn = false  // รีเซ็ตก่อน
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        self.isLoggedIn = true
                                    }
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            
                            Button("กำหนดเป็น Seller") {
                                self.userRole = "Seller"
                                // รอสักครู่ก่อนเปลี่ยนสถานะ
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    print("✅ กำหนดค่า userRole เป็น 'Seller' และเปิดหน้า Seller")
                                    self.isLoggedIn = false  // รีเซ็ตก่อน
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        self.isLoggedIn = true
                                    }
                                }
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Divider()
                        
                        Button("ลองเรียกดึงข้อมูลใหม่") {
                            if !userUID.isEmpty {
                                print("🔄 ลองเรียกดึงข้อมูลใหม่สำหรับ UID: \(userUID)")
                                self.userRole = ""  // รีเซ็ต
                                self.isLoggedIn = false  // ปิดหน้าปัจจุบัน
                                self.fetchUserRole(uid: userUID)
                            } else {
                                print("❌ ไม่มี UID ไม่สามารถเรียกดึงข้อมูลได้")
                            }
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Button("กลับไปหน้าล็อกอิน") {
                            self.isLoggedIn = false
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
    }
    
    func loginUser() {
        self.userRole = ""
        self.isLoggedIn = false
        self.errorMessage = ""
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            self.errorMessage = "กรุณากรอกอีเมลและรหัสผ่าน"
            return
        }
        
        guard !isLoggingIn else { return }
        isLoggingIn = true
        
        Auth.auth().signIn(withEmail: trimmedEmail, password: trimmedPassword) { authResult, error in
            self.isLoggingIn = false
            if let error = error {
                self.errorMessage = "❌ ล็อกอินล้มเหลว: \(error.localizedDescription)"
                return
            }
            
            guard let user = authResult?.user else {
                self.errorMessage = "❌ ไม่พบข้อมูลผู้ใช้"
                return
            }
            
            self.userUID = user.uid
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.fetchUserRole(uid: user.uid)
            }
        }
    }


    
    func fetchUserRole(uid: String) {
        print("🔍 กำลังค้นหาข้อมูลผู้ใช้ที่ UID: \(uid)")
        
        // ตรวจสอบการเชื่อมต่อ Firestore
        let db = Firestore.firestore()
        
        // ใช้ source: .server เพื่อบังคับให้ดึงข้อมูลจากเซิร์ฟเวอร์เท่านั้น
        db.collection("users").document(uid).getDocument(source: .server) { document, error in
            if let error = error {
                print("❌ เกิดข้อผิดพลาดในการดึงข้อมูล: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "❌ โหลดข้อมูลผู้ใช้ไม่สำเร็จ: \(error.localizedDescription)"
                }
                return
            }
            
            guard let document = document else {
                print("❌ ไม่พบเอกสาร")
                DispatchQueue.main.async {
                    self.errorMessage = "❌ ไม่พบข้อมูลผู้ใช้"
                }
                return
            }
            
            print("📄 พบเอกสาร ID: \(document.documentID)")
            let data = document.data() ?? [:]
            print("📄 ข้อมูลเอกสารทั้งหมด: \(data)")
            
            // ตรวจสอบทุกคีย์ในเอกสาร
            print("🔑 คีย์ทั้งหมดในเอกสาร:")
            for (key, value) in data {
                print("   - \(key): \(value) (type: \(type(of: value)))")
            }
            
            if let role = data["role"] as? String {
                print("✅ ดึง Role สำเร็จ: '\(role)'")
                print("✅ ดึง Role สำเร็จ (ประเภทข้อมูล): \(type(of: role))")
                
                DispatchQueue.main.async {
                    // แยกการอัพเดทค่าเพื่อดูว่ามีปัญหาตรงไหน
                    self.userRole = role
                    print("✅ กำหนดค่า userRole แล้ว: '\(self.userRole)'")
                    
                    // รอสักครู่ก่อนเปลี่ยนหน้าจอ
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isLoggedIn = true
                        print("✅ เปลี่ยนสถานะการล็อกอินเป็น true")
                    }
                }
            } else {
                print("❌ ไม่พบฟิลด์ 'role' หรือฟิลด์มีค่าไม่ใช่ string")
                
                // ลองค้นหาฟิลด์ที่มีชื่อคล้ายกับ "role"
                let possibleRoleKeys = data.keys.filter { $0.lowercased().contains("role") }
                print("🔍 ฟิลด์ที่อาจเป็น role: \(possibleRoleKeys)")
                
                DispatchQueue.main.async {
                    self.errorMessage = "❌ ไม่พบข้อมูล role"
                }
            }
        }
    }
}

#Preview {
    Login()
}
