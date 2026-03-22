import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var needsSetup: Bool = true
    @Published var trialExpired: Bool = false
    @Published var trialDaysLeft: Int = 14
    @Published var isLicensed: Bool = false
    @Published var provider: AIProvider = .claude
    @Published var apiKey: String = ""
    @Published var serverURL: String = ""

    init() {
        checkSetup()
        checkTrial()
    }

    func checkSetup() {
        needsSetup = UserDefaults.standard.string(forKey: "ai_provider") == nil
    }

    func completeSetup(provider: AIProvider, key: String, serverURL: String) {
        self.provider = provider
        self.apiKey = key
        self.serverURL = serverURL
        UserDefaults.standard.set(provider.rawValue, forKey: "ai_provider")
        if !key.isEmpty {
            KeychainHelper.save(key: "api_key", value: key)
        }
        if !serverURL.isEmpty {
            UserDefaults.standard.set(serverURL, forKey: "server_url")
        }
        needsSetup = false
    }

    func checkTrial() {
        let key = KeychainHelper.load(key: "license_key") ?? ""
        if key.hasPrefix("4MA-") && key.count >= 16 {
            isLicensed = true
            trialExpired = false
            return
        }

        let firstLaunch = UserDefaults.standard.double(forKey: "first_launch")
        if firstLaunch == 0 {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "first_launch")
            trialDaysLeft = 14
            return
        }

        let elapsed = Date().timeIntervalSince1970 - firstLaunch
        let daysUsed = Int(elapsed / 86400)
        trialDaysLeft = max(0, 14 - daysUsed)
        trialExpired = trialDaysLeft <= 0
    }

    func activateLicense(_ key: String) -> Bool {
        guard key.hasPrefix("4MA-"), key.count >= 16 else { return false }
        KeychainHelper.save(key: "license_key", value: key)
        isLicensed = true
        trialExpired = false
        return true
    }
}

enum AIProvider: String, CaseIterable {
    case claude = "claude"
    case openai = "openai"
    case ollama = "ollama"

    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .openai: return "GPT"
        case .ollama: return "Ollama"
        }
    }

    var description: String {
        switch self {
        case .claude: return "Anthropic"
        case .openai: return "OpenAI"
        case .ollama: return "Local · Free"
        }
    }

    var icon: String {
        switch self {
        case .claude: return "◆"
        case .openai: return "◉"
        case .ollama: return "◎"
        }
    }
}
