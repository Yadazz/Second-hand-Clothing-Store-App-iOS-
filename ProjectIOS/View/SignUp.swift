import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct SignUp: View {
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var phoneNumber = ""
    @State private var role = "Buyer" // or "Seller"
    @State private var errorMessage = ""
    @State private var isSuccess = false

    // New States for Profile Image
    @State private var selectedProfileImage: UIImage? = nil
    @State private var isProfilePickerPresented = false

    // New States for Address
    @State private var address: String = ""

    // New States for PromptPay QR (only for Seller)
    @State private var promptPayQRImage: UIImage? = nil
    @State private var isQRPickerPresented = false

    // MARK: - Theme Colors
    let backgroundColor = Color(red: 130/255, green: 116/255, blue: 70/255)
    let fieldBackgroundColor = Color(red: 190/255, green: 177/255, blue: 134/255)
    let buttonColor = Color(red: 97/255, green: 73/255, blue: 40/255)

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea() // Set the background color to match ProfileView

                ScrollView {
                    VStack(spacing: 20) {

                        // Profile Image Picker
                        Button(action: {
                            isProfilePickerPresented.toggle()
                        }) {
                            if let image = selectedProfileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(20)
                                    .shadow(radius: 7)
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(fieldBackgroundColor)
                                    .frame(width: 150, height: 150)
                                    .overlay(
                                        Image(systemName: "person.crop.circle")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .sheet(isPresented: $isProfilePickerPresented) {
                            ImagePicker(image: $selectedProfileImage)
                        }

                        // Labeled text fields (Username, Email, etc.)
                        labeledTextField(label: "Email", text: $email, placeholder: "Enter your email", keyboard: .emailAddress)
                        labeledSecureField(label: "Password", text: $password, placeholder: "Enter your password")
                        labeledTextField(label: "Username", text: $username, placeholder: "Enter your username")
                        labeledTextField(label: "Phone Number", text: $phoneNumber, placeholder: "Enter your phone number", keyboard: .phonePad)

                        // Role Picker (With Enhanced Look)
                        Picker("Role", selection: $role) {
                            Text("Buyer").tag("Buyer")
                            Text("Seller").tag("Seller")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .background(fieldBackgroundColor)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)

                        // Address Input
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Address:")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.bold)

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

                        // PromptPay QR Code (for Seller only)
                        if role == "Seller" {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("PromptPay QR Code:")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Button(action: {
                                    isQRPickerPresented.toggle()
                                }) {
                                    if let qrImage = promptPayQRImage {
                                        Image(uiImage: qrImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 150)
                                            .cornerRadius(15)
                                            .shadow(radius: 7)
                                    } else {
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(fieldBackgroundColor)
                                            .frame(height: 150)
                                            .overlay(
                                                Image(systemName: "qrcode.viewfinder")
                                                    .resizable()
                                                    .frame(width: 50, height: 50)
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                                .sheet(isPresented: $isQRPickerPresented) {
                                    ImagePicker(image: $promptPayQRImage)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Error Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.top, 5)
                        }

                        // Sign Up Button (Styled like ProfileView button)
                        Button(action: {
                            registerUser()
                        }) {
                            if isSuccess {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(buttonColor)
                                    .cornerRadius(15)
                            } else {
                                Text("Sign Up")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(buttonColor)
                                    .cornerRadius(15)
                                    .shadow(radius: 5)
                            }
                        }
                        .disabled(isSuccess)

                        // Go to Login link
                        NavigationLink(destination: Login().navigationBarBackButtonHidden(true)) {
                            Text("Go Back To Login")
                                .foregroundColor(.yellow)
                                .padding(5)
                                .font(.custom("Amiri", size: 12))
                                .underline(true, color: .yellow)
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $isSuccess, actions: {
                Button("OK") { }
            }, message: {
                Text("Your account has been created.")
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Labeled TextField Component
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

    // MARK: - Labeled SecureField Component (ใหม่)
    @ViewBuilder
    func labeledSecureField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            SecureField(placeholder, text: text)
                .padding()
                .background(fieldBackgroundColor)
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                .foregroundColor(.black)
        }
        .padding(.horizontal)
    }

    // MARK: - Register User Function
    func registerUser() {
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }

        errorMessage = ""

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Signup failed: \(error.localizedDescription)"
                return
            }

            guard let user = result?.user else {
                errorMessage = "Unexpected error: No user created."
                return
            }

            let uid = user.uid

            // Upload images if any
            let group = DispatchGroup()
            var profileImageURL: String? = nil
            var qrCodeURL: String? = nil

            if let profileImage = selectedProfileImage {
                group.enter()
                uploadImage(profileImage, path: "profileImages/\(uid).jpg") { url in
                    profileImageURL = url
                    group.leave()
                }
            }

            if role == "Seller", let qrImage = promptPayQRImage {
                group.enter()
                uploadImage(qrImage, path: "promptPayQR/\(uid).jpg") { url in
                    qrCodeURL = url
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                var userData: [String: Any] = [
                    "email": email,
                    "username": username,
                    "role": role,
                    "address": address,
                    "phoneNumber": phoneNumber
                ]

                if let profileURL = profileImageURL {
                    userData["profileImageURL"] = profileURL
                }

                if let qrURL = qrCodeURL {
                    userData["promptPayQRURL"] = qrURL
                }

                Firestore.firestore().collection("users").document(uid).setData(userData) { err in
                    if let err = err {
                        errorMessage = "User created but Firestore save failed: \(err.localizedDescription)"
                    } else {
                        isSuccess = true
                    }
                }
            }
        }
    }

    // MARK: - Image Upload Helper
    func uploadImage(_ image: UIImage, path: String, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child(path)
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Download URL error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(url?.absoluteString)
            }
        }
    }
}

#Preview {
    SignUp()
}
