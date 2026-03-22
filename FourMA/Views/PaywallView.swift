import SwiftUI

struct PaywallView: View {
    @ObservedObject var appState: AppState
    @State private var licenseKey = ""
    @State private var error = ""

    var body: some View {
        ZStack {
            Color(hex: "#06080e").ignoresSafeArea()

            VStack(spacing: 24) {
                Text("4MA")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#00ffcc"))
                    .tracking(4)

                Text("your trial has ended")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(Color(hex: "#667788"))

                Text("buy 4MA to keep using it.\none payment, yours forever.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "#556677"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Button(action: {
                    if let url = URL(string: "https://senderpa.github.io/4ma/support") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("BUY 4MA")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color(hex: "#00aacc"))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }

                Text("— or enter your license key —")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(hex: "#334455"))

                TextField("4MA-XXXX-XXXX-XXXX", text: $licenseKey)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(10)
                    .background(Color(hex: "#0a1018"))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1a2a3a")))
                    .foregroundColor(Color(hex: "#a0ccee"))
                    .multilineTextAlignment(.center)

                Button(action: activate) {
                    Text("ACTIVATE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color(hex: "#1a3050"))
                        .foregroundColor(Color(hex: "#88aacc"))
                        .cornerRadius(10)
                }

                if !error.isEmpty {
                    Text(error)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: "#ff6666"))
                }
            }
            .padding(30)
        }
    }

    func activate() {
        if appState.activateLicense(licenseKey) {
            error = ""
        } else {
            error = "invalid license key"
        }
    }
}
