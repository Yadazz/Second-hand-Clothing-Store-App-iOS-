import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    @State private var email = ""
    @State private var message = ""
    @State private var showingAlert = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color(hue: 0.13, saturation: 0.4, brightness: 0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("RESET PASSWORD")
                    .foregroundColor(.white)
                    .font(.title2)
                    .bold()
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                Button(action: sendResetEmail) {
                    Text("SEND RESET EMAIL")
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 250)
                        .background(Color(red: 97/255, green: 73/255, blue: 40/255))
                        .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true) // ซ่อนปุ่มย้อนกลับอัตโนมัติ
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.yellow) // ⭐️ สีเหลือง
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Reset Password"),
                message: Text(message),
                dismissButton: .default(Text("OK")) {
                    if message.contains("sent") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }

    func sendResetEmail() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            message = "❌ Please enter your email."
            showingAlert = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: trimmedEmail) { error in
            if let error = error {
                message = "❌ Error: \(error.localizedDescription)"
            } else {
                message = "✅ Password reset email has been sent to \(trimmedEmail)."
            }
            showingAlert = true
        }
    }
}
