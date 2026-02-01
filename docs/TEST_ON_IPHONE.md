# Testing Cogniaware on Your iPhone

## 1. Prerequisites

- **Mac** with Xcode installed (from Mac App Store).
- **Apple ID** (free) — needed to run on a physical device.
- **iPhone** connected with a USB cable (or same Wi‑Fi for wireless debugging).

## 2. One-time setup

### On your Mac

1. **Xcode**
   - Install Xcode from the App Store if you haven’t.
   - Open Xcode once and accept the license.
   - In Terminal (optional): `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

2. **CocoaPods** (for iOS dependencies)
   ```bash
   sudo gem install cocoapods
   ```
   If that fails, try: `brew install cocoapods`

### On your iPhone

1. **Connect** the iPhone with a USB cable and unlock it.
2. If you see **“Trust This Computer?”** on the phone → tap **Trust**.
3. **Developer Mode** (iOS 16+):
   - **Settings → Privacy & Security → Developer Mode** → turn **On**.
   - Restart the phone when asked.

## 3. Run the app on your iPhone

1. **Open Terminal** and go to the project folder:
   ```bash
   cd /Users/krishnakavitha/Downloads/cognify
   ```

2. **Get dependencies** (first time or after pull):
   ```bash
   flutter pub get
   ```

3. **See connected devices** (your iPhone should appear when connected and trusted):
   ```bash
   flutter devices
   ```
   You should see something like: `iPhone (mobile) • <id> • ios • iOS 17.x`

4. **Run on the iPhone** (Flutter will pick the only device if just the phone is connected):
   ```bash
   flutter run
   ```
   Or target the device explicitly:
   ```bash
   flutter run -d <device-id>
   ```
   Use the device id from `flutter devices` (e.g. `00008103-001234567890001E`).

5. **First run on device**
   - On the iPhone you may see: **“Untrusted Developer”**.
   - Go to **Settings → General → VPN & Device Management**.
   - Under **Developer App**, tap your Apple ID and tap **Trust**.

## 4. Testing live sensors on the phone

1. In the app, open **Settings** (gear icon in the bottom bar).
2. Under **Data source**, turn **“Use live sensors”** **On**.
3. Open the **Gait** tab and walk with the phone — step count and gait metrics should update from the device sensors.
4. Use **Voice** and **Typing** tabs for voice/typing exercises.

## 5. Permissions the app uses (iOS)

The app may ask for:

- **Motion & Fitness** — for step count and gait (accelerometer/gyroscope).
- **Microphone** — for voice exercises (on-device only; audio is discarded after processing).
- **Speech Recognition** — for voice exercises (if prompted).

Grant these when the app asks so that live sensor and voice features work.

## 6. Wireless debugging (optional)

After a successful USB run:

1. In Xcode: **Window → Devices and Simulators** → select your iPhone → check **Connect via network**.
2. Unplug the cable; the phone will appear under network. Then you can run:
   ```bash
   flutter run
   ```
   and it will install/run over Wi‑Fi (phone and Mac on same network).

## Fix: “No valid code signing certificates were found”

You must set a **Development Team** in Xcode once (your Apple ID). Do this:

### Step 1: Add your Apple ID in Xcode (if needed)

1. Open **Xcode**.
2. Menu: **Xcode → Settings…** (or **Preferences…** on older Xcode).
3. Go to the **Accounts** tab.
4. Click **+** (bottom left) → **Apple ID** → sign in with your Apple ID (free account is fine).
5. Your **Personal Team** will appear. Close Settings.

### Step 2: Open the project and set the Team

1. In Terminal, from the project folder, run:
   ```bash
   open ios/Runner.xcworkspace
   ```
   (Use **Runner.xcworkspace**, not Runner.xcodeproj.)

2. In Xcode’s **left sidebar**, click the blue **Runner** project (top item).

3. Under **TARGETS**, select **Runner** (not RunnerTests).

4. Open the **Signing & Capabilities** tab at the top.

5. Under **Signing**, check **“Automatically manage signing”**.

6. In the **Team** dropdown, choose your **Personal Team** (your name or Apple ID).  
   - If you see “Add an Account…”, add your Apple ID in Xcode → Settings → Accounts first, then pick that team here.
   - Xcode will create a development certificate and provisioning profile for you.

7. If Xcode shows a **Bundle ID** conflict (e.g. “already in use”), change it:  
   In the same screen, set **Bundle Identifier** to something unique, e.g. `com.yourname.cognify` (replace `yourname` with your own).

8. Save (Cmd+S) and **close Xcode** (or leave it open).

### Step 3: Run on your iPhone again

```bash
flutter run
```

### Step 4: Trust the developer on the iPhone (first time only)

If the app doesn’t open and says “Untrusted Developer”:

- On the iPhone: **Settings → General → VPN & Device Management** (or **Device Management**).
- Under **Developer App**, tap your Apple ID and tap **Trust**.

Then open the Cogniaware app again from the home screen.

---

## Troubleshooting

| Issue | What to do |
|-------|------------|
| iPhone not in `flutter devices` | Reconnect cable, unlock phone, tap Trust; enable Developer Mode and restart. |
| “No valid code signing” | Follow **Fix: “No valid code signing certificates were found”** above. |
| “Developer Mode” not visible | Ensure iOS 16+ and that the device has been used for development at least once (e.g. after Trust). |
| Build fails on `pod install` | In project folder: `cd ios && pod install && cd ..` then `flutter run` again. |
