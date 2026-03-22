# 4MA iOS -- Development Guide

## Prerequisites

- **macOS** 14.0 (Sonoma) or later
- **Xcode** 16.0 or later (download from Mac App Store or developer.apple.com)
- **iOS 17.0+** device or simulator
- **Apple Developer account** (free for simulator; paid $99/year for device deployment, TestFlight, and App Store)

## Project Structure

```
4ma-ios/
  FourMA.xcodeproj/        <-- Xcode project (open this)
  FourMA/
    FourMAApp.swift          App entry point (@main)
    Info.plist               Permissions, ATS config, bundle metadata
    Assets.xcassets/         App icon, accent color, launch background color
    Models/
      AppState.swift         Observable app state (trial, license, provider)
    Views/
      MainView.swift         WKWebView loading the 4MA backend
      SetupView.swift        First-run AI provider selection
      PaywallView.swift      Trial expired / license activation screen
    Services/
      KeychainHelper.swift   Secure keychain read/write for API keys
    Extensions/
      Color+Hex.swift        Color(hex:) initializer used throughout
    Resources/               (reserved for future bundled assets)
  Package.swift              SPM manifest (for library use only, not for building the app)
```

## Opening the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/senderpa/4ma-ios.git
   cd 4ma-ios
   ```

2. Open the Xcode project:
   ```bash
   open FourMA.xcodeproj
   ```
   Xcode will open with the FourMA scheme already selected.

3. If Xcode asks about "Autocreate Schemes", choose **Manually Manage Schemes** -- the shared scheme is already included.

## Running on the Simulator

1. In Xcode, select the **FourMA** scheme (top-left toolbar).
2. Choose a simulator from the device dropdown (e.g., "iPhone 15 Pro").
3. Press **Cmd+R** or click the Play button.
4. The app will build and launch in the simulator.

**Note:** The WebView loads your 4MA backend (default `http://localhost:5090`). If the backend is not running on your Mac, the WebView will show a blank screen and retry every 3 seconds. Start your 4MA backend or enter a reachable server URL in the setup screen.

## Running on a Physical Device

1. Connect your iPhone/iPad via USB or select it over the local network.
2. In Xcode, select your device from the device dropdown.
3. Go to **Signing & Capabilities** in the project settings:
   - Set **Team** to your Apple Developer account.
   - Xcode will auto-manage signing and create a provisioning profile.
4. Press **Cmd+R**. Accept the "Trust Developer" prompt on your device if needed (Settings > General > VPN & Device Management).

## Setting Your Development Team

The project ships with `DEVELOPMENT_TEAM = ""` (empty). You must set it to your own team ID:

1. Open FourMA.xcodeproj in Xcode.
2. Select the **FourMA** target in the project navigator.
3. Go to **Signing & Capabilities**.
4. Check **Automatically manage signing**.
5. Select your **Team** from the dropdown.

This is a per-developer setting and should NOT be committed to the repository.

## App Icon

The asset catalog expects a single **1024x1024 PNG** file named `AppIcon-1024.png` in:
```
FourMA/Assets.xcassets/AppIcon.appiconset/
```

Xcode 16+ with iOS 17+ only requires this single size. Xcode auto-generates all smaller sizes at build time. The icon should:
- Be exactly 1024x1024 pixels
- Be a PNG with no transparency (no alpha channel)
- Have no rounded corners (iOS adds them automatically)
- Not contain any padding or borders

To add your icon: drop `AppIcon-1024.png` into the `AppIcon.appiconset/` folder (or drag it onto the AppIcon slot in Xcode's asset catalog editor).

## How the Trial System Works

The app implements a 14-day trial with local license validation:

1. **First launch**: Records `first_launch` timestamp in UserDefaults.
2. **Each launch**: Calculates days elapsed since first launch.
3. **Days 1-14**: Trial banner shows remaining days in `MainView`. App is fully functional.
4. **Day 15+**: `trialExpired` becomes `true`. The app shows `PaywallView` instead of `MainView`.
5. **License activation**: User enters a key matching the pattern `4MA-XXXX-XXXX-XXXX` (16+ characters, starts with `4MA-`). The key is stored in Keychain via `KeychainHelper`. On subsequent launches, if a valid key exists in Keychain, the trial is bypassed.

The trial check runs in `AppState.checkTrial()` on every app launch.

**Important for App Store**: If you distribute through the App Store, you will likely need to replace this custom trial with StoreKit 2 in-app purchases or a subscription. Apple does not allow time-limited trials that bypass their payment system. See the App Store review section below.

## Deploying to TestFlight

1. **Set your Team**: See "Setting Your Development Team" above.
2. **Increment the build number**: In the target's General tab, bump **Build** (e.g., 1 -> 2). The version string can stay the same.
3. **Select "Any iOS Device (arm64)"** as the build destination.
4. **Archive**: Product > Archive (Cmd+Shift+B, then Product > Archive).
5. **Distribute**: In the Organizer window (Window > Organizer):
   - Select the archive and click **Distribute App**.
   - Choose **App Store Connect** > **Upload**.
   - Follow the prompts (Xcode handles signing automatically if configured).
6. **TestFlight**: Go to [App Store Connect](https://appstoreconnect.apple.com):
   - Navigate to your app > TestFlight tab.
   - The build will appear after processing (5-30 minutes).
   - Add internal testers (up to 25) or create a public link for external testing (up to 10,000).

## Submitting to the App Store

1. Complete all TestFlight steps above.
2. In App Store Connect, go to your app > **App Store** tab.
3. Fill in the required metadata:
   - **App name**: 4MA
   - **Subtitle**: your AI assistant
   - **Description**: Describe 4MA's features (animated face, voice commands, multi-AI support).
   - **Keywords**: AI, assistant, voice, Ollama, Claude, GPT
   - **Screenshots**: At minimum, provide screenshots for iPhone 6.7" (iPhone 15 Pro Max) and iPad 12.9". Take them from the simulator with Cmd+S.
   - **App icon**: Automatically pulled from the binary.
   - **Privacy policy URL**: Required. Host a privacy policy at your domain.
   - **Support URL**: e.g., https://senderpa.github.io/4ma/support
4. Select the build you uploaded.
5. Set pricing (paid or free with in-app purchase).
6. Click **Submit for Review**.

Review typically takes 24-48 hours.

## App Store Review Guidelines to Follow

These are the guidelines most relevant to 4MA. Violating any of them will cause rejection.

### 2.1 -- App Completeness
- The app must be fully functional when reviewed. If it requires a backend server, provide a demo server URL or test account in the review notes.
- Do not present a blank WebView. Handle the "server unreachable" state with a visible error or loading indicator.

### 2.3.1 -- Hidden Features
- Do not hide functionality behind the trial/license system during review. Provide a test license key in the review notes so reviewers can access all features.

### 3.1.1 -- In-App Purchase Requirement
- If 4MA is paid, the purchase MUST go through Apple's In-App Purchase (StoreKit). You cannot direct users to an external website for payment and unlock features in the app.
- The current `PaywallView` links to an external site and accepts a license key. This will be **rejected** by Apple. You must either:
  - (a) Make the app fully free with no paywall, OR
  - (b) Implement StoreKit 2 for in-app purchase, OR
  - (c) Sell the app as a paid upfront download (no trial, no paywall screen).

### 3.1.3(b) -- Multiplatform Services
- If the license is also valid on the web version of 4MA, you may qualify for the "reader app" or "multiplatform service" exception. Consult Apple's guidelines carefully.

### 4.2 -- Minimum Functionality
- Apps that are essentially web wrappers may be rejected if they do not provide meaningful native functionality beyond what Safari offers. Consider adding:
  - Native push notifications
  - Haptic feedback
  - Home screen widgets
  - Siri shortcuts
  - Offline mode or native settings

### 5.1 -- Privacy
- The `NSAllowsArbitraryLoads` ATS exception may trigger review questions. Be prepared to explain why it is needed (connecting to user-configured local servers).
- Declare all data collection in App Store Connect's privacy nutrition labels.
- The privacy policy URL must be valid and accessible.

### 5.1.1 -- Data Collection
- API keys are stored in Keychain (good).
- If the app sends any data to your server, disclose it in the privacy policy and nutrition labels.

### 2.5.6 -- Apps That Browse the Web
- Since `MainView` is a WKWebView loading a remote URL, Apple may classify this as a "web browser" or "web wrapper." Mitigate by ensuring the WebView only loads YOUR server (not arbitrary URLs) and by providing native UI elements (the setup screen, trial banner, paywall).

## Troubleshooting

### "No such module" errors
Cmd+Shift+K (Clean Build Folder), then Cmd+B to rebuild.

### WebView shows blank screen
The 4MA backend is not reachable. Check that:
- The server is running and accessible from your device/simulator.
- `NSAllowsLocalNetworking` is `true` in Info.plist (it is).
- If on a physical device, the phone and server must be on the same Wi-Fi network.

### Signing errors
Make sure you have selected a valid Development Team in Signing & Capabilities.

### "Untrusted Developer" on device
Go to Settings > General > VPN & Device Management > tap your developer profile > Trust.
