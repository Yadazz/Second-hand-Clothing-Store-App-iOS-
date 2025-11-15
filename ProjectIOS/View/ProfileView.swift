import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI
import MapKit

struct ProfileView: View {
    var uid: String

    // MARK: - State Variables
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var address: String = ""
    @State private var phoneNumber: String = "" // ✅ เพิ่มเบอร์โทร
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var oldPassword: String = ""

    @State private var selectedProfileImage: UIImage? = nil
    @State private var promptPayQRImage: UIImage? = nil
    @State private var isPickerPresented = false
    @State private var isQRPickerPresented = false

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var role: String = ""
    @State private var isSaving = false

    @State private var showLogoutConfirmation = false
    @State private var showSaveConfirmation = false

    // MARK: - Theme Colors
    let backgroundColor = Color(red: 130/255, green: 116/255, blue: 70/255)
    let fieldBackgroundColor = Color(red: 190/255, green: 177/255, blue: 134/255)
    let buttonColor = Color(red: 97/255, green: 73/255, blue: 40/255)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .font(.title2)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {
                            // Profile Image Picker
                            Button(action: { isPickerPresented.toggle() }) {
                                if let image = selectedProfileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 200, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(radius: 7)
                                } else {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(fieldBackgroundColor)
                                        .frame(width: 200, height: 200)
                                        .overlay(
                                            Image(systemName: "person.crop.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 100, height: 100)
                                                .foregroundColor(.white.opacity(0.7))
                                        )
                                }
                            }
                            .sheet(isPresented: $isPickerPresented) {
                                ImagePicker(image: $selectedProfileImage)
                            }
                            .padding(.top, 40)

                            Group {
                                labeledTextField(label: "Username", text: $username, placeholder: "Enter your username")
                                labeledTextField(label: "Email", text: $email, placeholder: "Enter your email", keyboard: .emailAddress)
                                labeledTextField(label: "Phone Number", text: $phoneNumber, placeholder: "Enter your phone number", keyboard: .phonePad) // ✅
                            }

                            NavigationLink(destination: ResetPasswordView()) {
                                Text("CHANGE PASSWORD")
                                    .font(.custom("Amiri", size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                                    .underline(true, color: .white.opacity(0.3))  // underline สีจางๆ
                                    .fontWeight(.regular)
                            }


                            VStack(alignment: .leading, spacing: 6) {
                                Text("Address")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                TextEditor(text: $address)
                                    .frame(height: 100)
                                    .padding(10)
                                    .background(fieldBackgroundColor)
                                    .cornerRadius(15)
                                    .foregroundColor(.black)
                                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)

                                NavigationLink {
                                    LocationPickerView(selectedAddress: $address)
                                } label: {
                                    HStack {
                                        Text("📍 Select Address on Map")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "map")
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(buttonColor.opacity(0.8))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)

                            if role.lowercased() == "seller" {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("PromptPay QR Code")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)

                                    Button(action: { isQRPickerPresented.toggle() }) {
                                        if let qrImage = promptPayQRImage {
                                            Image(uiImage: qrImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(height: 200)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                                .shadow(radius: 7)
                                        } else {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(fieldBackgroundColor)
                                                .frame(height: 200)
                                                .overlay(
                                                    Image(systemName: "qrcode.viewfinder")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 60, height: 60)
                                                        .foregroundColor(.white.opacity(0.7))
                                                )
                                        }
                                    }
                                    .sheet(isPresented: $isQRPickerPresented) {
                                        ImagePicker(image: $promptPayQRImage)
                                    }
                                }
                                .padding(.horizontal)
                            }

                            VStack(spacing: 15) {
                                Button {
                                    showSaveConfirmation = true
                                } label: {
                                    if isSaving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(buttonColor)
                                            .cornerRadius(15)
                                    } else {
                                        Text("Save Changes")
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(buttonColor)
                                            .cornerRadius(15)
                                            .shadow(radius: 5)
                                    }
                                }
                                .disabled(isSaving)

                                Button {
                                    showLogoutConfirmation = true
                                } label: {
                                    Text("Log Out")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                        .frame(maxWidth: .infinity)
                                        .padding(10)
                                        .background(Color.clear)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert("Are you sure you want to log out?", isPresented: $showLogoutConfirmation) {
                Button("Log Out", role: .destructive) {
                    do {
                        try Auth.auth().signOut()
                        goToLoginScreen()
                    } catch {
                        alertMessage = "❌ Failed to log out: \(error.localizedDescription)"
                        showingAlert = true
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Save changes?", isPresented: $showSaveConfirmation) {
                Button("Save", role: .none) {
                    saveChanges()
                }
                Button("Cancel", role: .cancel) { }
            }
            .onAppear {
                fetchUserData()
            }
        }
    }

    // MARK: - UI Components
    @ViewBuilder
    func labeledTextField(label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .padding()
                .background(fieldBackgroundColor)
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                .foregroundColor(.black)
        }
        .padding(.horizontal)
    }

    // MARK: - Load Data
    func fetchUserData() {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                self.alertMessage = "Failed to load data: \(error.localizedDescription)"
                self.showingAlert = true
                self.isLoading = false
                return
            }

            guard let doc = document, doc.exists, let data = doc.data() else {
                self.alertMessage = "User data not found"
                self.showingAlert = true
                self.isLoading = false
                return
            }

            self.username = data["username"] as? String ?? ""
            self.email = data["email"] as? String ?? ""
            self.password = data["password"] as? String ?? ""
            self.address = data["address"] as? String ?? ""
            self.phoneNumber = data["phoneNumber"] as? String ?? "" // ✅ โหลดเบอร์โทร
            self.role = data["role"] as? String ?? ""

            if let imageUrl = data["profileImageURL"] as? String, let url = URL(string: imageUrl) {
                loadImage(from: url) { img in
                    self.selectedProfileImage = img
                }
            }

            if self.role.lowercased() == "seller",
               let qrUrl = data["promptPayQRURL"] as? String,
               let url = URL(string: qrUrl) {
                loadImage(from: url) { img in
                    self.promptPayQRImage = img
                }
            }

            self.isLoading = false
        }
    }

    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Image loading error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }

    // MARK: - Save Changes
    func saveChanges() {
        guard !isSaving else { return }
        isSaving = true

        guard let user = Auth.auth().currentUser else {
            self.alertMessage = "No user is logged in"
            self.showingAlert = true
            isSaving = false
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        let group = DispatchGroup()

        var dataToUpdate: [String: Any] = [
            "username": username,
            "email": email,
            "address": address,
            "phoneNumber": phoneNumber // ✅ อัปเดตเบอร์โทร
        ]

        if let selectedImage = selectedProfileImage {
            group.enter()
            uploadProfileImage(image: selectedImage) { imageURL in
                if !imageURL.isEmpty {
                    dataToUpdate["profileImageURL"] = imageURL
                }
                group.leave()
            }
        }

        if role.lowercased() == "seller", let qrImage = promptPayQRImage {
            group.enter()
            uploadQRCodeImage(image: qrImage) { qrURL in
                if !qrURL.isEmpty {
                    dataToUpdate["promptPayQRURL"] = qrURL
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            userRef.updateData(dataToUpdate) { error in
                isSaving = false
                if let error = error {
                    self.alertMessage = "Failed: \(error.localizedDescription)"
                } else {
                    self.alertMessage = "✅ Saved successfully"
                }
                self.showingAlert = true
            }
        }
    }

    func uploadProfileImage(image: UIImage, completion: @escaping (String) -> Void) {
        let storageRef = Storage.storage().reference()
        let uniqueID = UUID().uuidString
        let imageRef = storageRef.child("profileImages/\(uniqueID).jpg")

        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            self.alertMessage = "Unable to convert image data"
            self.showingAlert = true
            completion("")
            return
        }

        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                self.alertMessage = "Upload failed: \(error.localizedDescription)"
                self.showingAlert = true
                completion("")
                return
            }

            imageRef.downloadURL { url, _ in
                completion(url?.absoluteString ?? "")
            }
        }
    }

    func uploadQRCodeImage(image: UIImage, completion: @escaping (String) -> Void) {
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("promptPayQR/\(uid).jpg")

        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            self.alertMessage = "Unable to convert QR image"
            self.showingAlert = true
            completion("")
            return
        }

        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                self.alertMessage = "QR upload failed: \(error.localizedDescription)"
                self.showingAlert = true
                completion("")
                return
            }

            imageRef.downloadURL { url, _ in
                completion(url?.absoluteString ?? "")
            }
        }
    }

    // MARK: - Navigation
    func goToLoginScreen() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: Login())
            window.makeKeyAndVisible()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ProfileView(uid: "qe7bsnfUnDeQI0gXMMGiNNocAVh1")
    }
}
