import SwiftUI

struct SetupView: View {
    @ObservedObject var appState: AppState
    @State private var selected: AIProvider?
    @State private var apiKey = ""
    @State private var ollamaURL = "http://localhost:11434"

    var body: some View {
        ZStack {
            Color(hex: "#06080e").ignoresSafeArea()

            VStack(spacing: 24) {
                Text("4MA")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#00ffcc"))
                    .tracking(4)

                Text("pick your AI — one tap to connect")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "#445566"))

                // Provider buttons
                HStack(spacing: 10) {
                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        Button(action: { selected = provider }) {
                            VStack(spacing: 4) {
                                Text(provider.icon)
                                    .font(.system(size: 28))
                                Text(provider.displayName)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                Text(provider.description)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(Color(hex: "#445566"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(selected == provider ? Color(hex: "#0a1a28") : Color(hex: "#0a1420"))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selected == provider ? Color(hex: "#00ffcc") : Color(hex: "#1a2a3a"), lineWidth: 2)
                            )
                        }
                        .foregroundColor(selected == provider ? Color(hex: "#00ffcc") : Color(hex: "#88aacc"))
                    }
                }

                // API key input
                if let sel = selected, sel != .ollama {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sel == .claude ? "Anthropic API Key" : "OpenAI API Key")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(hex: "#667788"))
                        SecureField("paste your API key", text: $apiKey)
                            .font(.system(size: 14, design: .monospaced))
                            .padding(10)
                            .background(Color(hex: "#0a1018"))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1a2a3a")))
                            .foregroundColor(Color(hex: "#a0ccee"))
                    }
                    .transition(.opacity)
                }

                if selected == .ollama {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ollama URL")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(hex: "#667788"))
                        TextField("http://localhost:11434", text: $ollamaURL)
                            .font(.system(size: 14, design: .monospaced))
                            .padding(10)
                            .background(Color(hex: "#0a1018"))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1a2a3a")))
                            .foregroundColor(Color(hex: "#a0ccee"))
                        Text("runs AI on your machine for free")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Color(hex: "#334455"))
                    }
                    .transition(.opacity)
                }

                // Connect button
                Button(action: connect) {
                    Text("CONNECT")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(canConnect ? Color(hex: "#00aacc") : Color(hex: "#1a2a3a"))
                        .foregroundColor(canConnect ? .black : Color(hex: "#445566"))
                        .cornerRadius(10)
                }
                .disabled(!canConnect)

                Button("skip for now") {
                    appState.completeSetup(provider: .ollama, key: "", serverURL: "")
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color(hex: "#334455"))
            }
            .padding(24)
            .animation(.easeInOut(duration: 0.2), value: selected)
        }
    }

    var canConnect: Bool {
        guard let sel = selected else { return false }
        if sel == .ollama { return true }
        return !apiKey.isEmpty
    }

    func connect() {
        guard let sel = selected else { return }
        appState.completeSetup(
            provider: sel,
            key: sel == .ollama ? "" : apiKey,
            serverURL: sel == .ollama ? ollamaURL : ""
        )
    }
}

// Color(hex:) extension is in FourMA/Extensions/Color+Hex.swift
