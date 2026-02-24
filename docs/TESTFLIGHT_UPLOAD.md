# Upload "The 5-Minute Rule" to TestFlight

This guide walks you through uploading the iOS app to TestFlight for beta testing.

---

## Prerequisites

- **Apple Developer Program** membership ($99/year). Sign up at [developer.apple.com](https://developer.apple.com/programs/).
- **Xcode** installed (from Mac App Store).
- **Flutter** installed and working (`flutter doctor` passes for iOS).

---

## 1. Create the app in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com) and sign in.
2. Click **My Apps** → **+** → **New App**.
3. Fill in:
   - **Platform:** iOS
   - **Name:** The 5-Minute Rule
   - **Primary Language:** your choice (e.g. English)
   - **Bundle ID:** select **com.fiveminuterule.theFiveMinuteRule** (you must have this registered in the Developer account).
   - **SKU:** e.g. `the-5-minute-rule-001`
4. Click **Create**. You don’t need to fill “App Information” or “Pricing” for TestFlight.

If the bundle ID isn’t listed, create it first:

- Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) → **Identifiers** → **+** → **App IDs** → **App** → enter **com.fiveminuterule.theFiveMinuteRule** and a description → **Register**.

---

## 2. Set version and build number

Your `pubspec.yaml` already has:

```yaml
version: 1.0.0+1
```

- **1.0.0** = CFBundleShortVersionString (user-facing version).
- **1** = CFBundleVersion (build number).

For each new upload to TestFlight, **increase the build number** (e.g. `1.0.0+2`, then `1.0.0+3`). You can leave the version as 1.0.0 until you’re ready for a new marketing version.

---

## 3. Open the iOS project in Xcode and set signing

1. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
   (Use the `.xcworkspace`, not the `.xcodeproj`.)

2. In the left sidebar, select the **Runner** project (blue icon), then the **Runner** target.

3. Open the **Signing & Capabilities** tab.

4. Check **Automatically manage signing**.

5. Choose your **Team** (your Apple Developer account). If you don’t see it, add your Apple ID under **Xcode → Settings → Accounts**.

6. Ensure **Bundle Identifier** is **com.fiveminuterule.theFiveMinuteRule** (it should already be).

7. Pick a **Run** destination (e.g. “Any iOS Device (arm64)”). You don’t need a physical device plugged in for archiving.

---

## 4. Build an iOS release (archive)

From the project root in Terminal:

```bash
flutter clean
flutter pub get
flutter build ipa
```

This produces a release build and an `.ipa`. The path is printed at the end, e.g.:

`build/ios/ipa/the_five_minute_rule.ipa`

If you prefer to archive in Xcode:

1. In Xcode, choose **Product → Destination → Any iOS Device (arm64)**.
2. **Product → Archive**.
3. When the Organizer opens, your archive is listed there.

---

## 5. Upload to App Store Connect

### Option A: Using the archive from Xcode (if you used Product → Archive)

1. In **Window → Organizer**, open the **Archives** tab.
2. Select the latest archive for **Runner**.
3. Click **Distribute App**.
4. Choose **App Store Connect** → **Next**.
5. Choose **Upload** → **Next**.
6. Leave options as default (e.g. upload symbols, manage version/build) → **Next**.
7. Select your **distribution certificate** and **provisioning profile** (or let Xcode manage them) → **Next**.
8. Review and click **Upload**. Wait until the upload finishes.

### Option B: Using the .ipa from `flutter build ipa`

1. Open **Xcode**.
2. **Window → Organizer** → **Archives**.
3. If you don’t see an archive, use **Distribute App** from the menu: **File** (or **Xcode**) → **Open** isn’t the right path; instead, run `flutter build ipa` and then use **Transporter** (see below), or create an archive in Xcode (step 4, “Build an iOS release”) and use Option A.

   **Easier:** use **Transporter** with the `.ipa`:

4. Open **Transporter** (Mac App Store, or from Xcode: **Xcode → Open Developer Tool → Transporter**).
5. Sign in with your Apple ID (same as App Store Connect).
6. Drag and drop **build/ios/ipa/the_five_minute_rule.ipa** into Transporter.
7. Click **Deliver**. Wait until the upload completes.

---

## 6. Wait for processing and enable TestFlight

1. In **App Store Connect**, open **My Apps** → **The 5-Minute Rule**.
2. Go to the **TestFlight** tab.
3. Under **iOS**, you’ll see the build (e.g. 1.0.0 (1)). Processing can take **5–30 minutes**. Status will change from “Processing” to “Ready to Submit” (or “Missing compliance” — see below).
4. If Apple asks for **Export Compliance**: for this app (no encryption beyond standard HTTPS), you can answer **No** to “Does your app use encryption?” in the build’s compliance section. If you use **flutter build ipa**, Flutter often sets the default in the project; you can also set it in Xcode under **Runner → Info** (add “App Uses Non-Exempt Encryption” = NO) so future builds default to No.

---

## 7. Add testers

**Internal testing (up to 100, same org):**

- **TestFlight** tab → **Internal Testing** → create a group if needed → **+** to add the build → add testers by email (they must be in your App Store Connect users with Admin, App Manager, or Developer role).

**External testing (public link or up to 10,000 testers):**

- **TestFlight** tab → **External Testing** → **+** to create a group → add the build → submit for **Beta App Review** (first time can take ~24–48 hours). After approval, add testers or enable public link.

Testers install **TestFlight** from the App Store, then open your invite link or accept the invite email to install the app.

---

## Quick checklist

- [ ] Apple Developer account and app created in App Store Connect with bundle ID **com.fiveminuterule.theFiveMinuteRule**
- [ ] Xcode: open **ios/Runner.xcworkspace**, set **Signing & Capabilities** (Team, automatic signing)
- [ ] Version/build set in **pubspec.yaml** (e.g. `1.0.0+1`); bump build number for each upload
- [ ] `flutter build ipa` (or Xcode **Product → Archive**)
- [ ] Upload via **Xcode Organizer (Distribute App)** or **Transporter** with the `.ipa`
- [ ] In App Store Connect → **TestFlight**, wait for build to be “Ready”, set export compliance if needed
- [ ] Add internal or external testers and (for external) complete Beta App Review

---

## Troubleshooting

- **“No valid signing identity”**  
  In Xcode **Signing & Capabilities**, select the correct Team and ensure **Automatically manage signing** is on. If needed, in [developer.apple.com](https://developer.apple.com/account/resources/certificates/list) create an **Apple Distribution** certificate and install it.

- **“Bundle ID doesn’t match”**  
  App Store Connect app and Xcode (Runner target) must both use **com.fiveminuterule.theFiveMinuteRule**.

- **Build doesn’t appear in TestFlight**  
  Wait 10–30 minutes. Check **Activity** in App Store Connect for errors. Ensure you uploaded an **iOS** build and that the version/build are higher than any previously uploaded build.

- **“Missing compliance”**  
  Open the build in TestFlight and answer the export compliance question (usually “No” for no custom encryption).
