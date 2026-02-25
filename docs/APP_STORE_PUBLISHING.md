# App Store publishing checklist — The 5-Minute Rule

Use this after TestFlight is working and you’re ready to submit for public release.

---

## What the app does (for listing & privacy)

- **Function:** Timer app — 5‑minute countdown, then count-up; user can name the task and view history. All data stays on device (Hive + SharedPreferences). No account, no server, no analytics.
- **Privacy:** No data collected for tracking or advertising. Session history and task names are stored only on the user’s device.

---

## 1. App Store Connect — App Information

**Path:** My Apps → The 5-Minute Rule → **App Information** (left sidebar).

| Field | What to use |
|-------|---------------------|
| **Name** | The 5-Minute Rule |
| **Subtitle** | Short line under the name (e.g. “Start in five minutes.”) — max 30 chars |
| **Category** | Primary: e.g. **Productivity** or **Lifestyle** |
| **Secondary Category** | Optional |
| **Content Rights** | Check if you have rights to the content (you do for your app) |
| **Age Rating** | Fill the questionnaire (no violence, no mature content → likely **4+**) |

---

## 2. App Store Connect — Pricing and Availability

- **Price:** Free (or choose a price).
- **Availability:** Select the countries/regions where the app will be available.

---

## 3. App Store Connect — Prepare for Submission (version 1.0.0)

**Path:** My Apps → The 5-Minute Rule → select the **iOS app** → under the version (e.g. **1.0.0**) click **Prepare for Submission** (or add a new version first).

### Screenshots (required)

Apple requires screenshots for several device sizes. You must provide at least:

- **6.7"** (e.g. iPhone 15 Pro Max): 1290 × 2796 px
- **6.5"** (e.g. iPhone 14 Plus): 1284 × 2778 px  
- **5.5"** (e.g. iPhone 8 Plus): 1242 × 2208 px  

You can use the same image for multiple sizes if it fits (e.g. 1290 × 2796 for 6.7" and 6.5"). Up to 10 screenshots per size; 3–5 is typical.

**How to capture:** Run the app in the simulator (e.g. iPhone 15 Pro Max), go through onboarding and main screens (home, timer, completion, history), then **Cmd+S** in Simulator to save screenshots. Resize/crop to exact pixels if needed.

### Promotional Text (optional)

- Short line at the top of the listing (editable without a new version). E.g. “A simple 5‑minute ritual to get started.”

### Description (required)

- Explain what the app does and why it’s useful. Example:

  **The 5-Minute Rule** is a minimal timer to beat procrastination: you commit to five minutes. Press Start, do the thing. When the countdown hits zero, the timer counts up — you can stop anytime. Name the task when you’re done and see your history. No accounts, no clutter. Data stays on your device.

### Keywords (required)

- Comma‑separated, no spaces after commas (e.g. `timer,productivity,focus,5 minute,procrastination,habit`). Max 100 characters total.

### Support URL (required)

- A URL where users can get help (e.g. a simple webpage, your site, or a GitHub “Support” or “Contact” page). Must be a valid URL.

### Marketing URL (optional)

- E.g. your product or personal site.

### Privacy Policy URL

- **Required** if the app collects data. Your app only stores data on device; Apple still often expects a privacy policy. Use a short page that says: no account, no server, data stays on device, no tracking. Host it anywhere (e.g. GitHub Pages, your site, Notion public page).

### Build (required)

- Click **+** and select the **build** you already uploaded (the one that’s in TestFlight). Only builds that have been processed and that meet the version number for this release will appear. If you don’t see it, upload a new build with the same version (e.g. 1.0.0) and a new build number (e.g. `1.0.0+2`), then wait for processing.

### Version (required)

- Must match the build (e.g. **1.0.0**). You set this in `pubspec.yaml` as the first part of `version: 1.0.0+1`.

### Copyright (required)

- E.g. `2025 Your Name` or `2025 Your Company`.

### App Review contact

- Phone and email Apple can use to reach you if they have questions.

### Sign-in (if your app has no sign-in)

- Choose “Sign-in required” = **No** (your app has no account).

---

## 4. App Privacy (App Store Connect)

**Path:** My Apps → The 5-Minute Rule → **App Privacy** (left sidebar).

- Answer the questions. For this app:
  - No data used for tracking.
  - No data linked to identity (no account).
  - Data stored on device only (session history, task names) can be declared as **“Data Not Collected”** for categories like Contact Info, Identifiers, etc., or you can declare **“Other Data”** used for app functionality, stored on device only, not collected from the user in the “identity” sense. Choose the option that best matches Apple’s wording (they update the flow; “Data Not Collected” for tracking/analytics is correct; for local history, follow the current questionnaire).
- Save. This section is required before submission.

---

## 5. App icon (1024×1024)

- App Store requires a **1024×1024** icon (no transparency, no rounded corners — Apple applies the mask).
- Your Xcode project references **AppIcon~ios-marketing.png** (1024×1024) in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`. Ensure that file exists and is 1024×1024. If you use an icon generator, it usually outputs this as “ios-marketing” or “App Store”.
- In App Store Connect, the icon is taken from the build; you don’t upload it separately for the store listing. So the build you select for 1.0.0 must include the correct app icon set.

---

## 6. Version and build (code)

- **Version** (e.g. 1.0.0): set in `pubspec.yaml` as `version: 1.0.0+1` (first number).
- **Build number** (e.g. 1): second number in `version: 1.0.0+1`. Increase for each upload (e.g. 1.0.0+2 for the next build).
- For the **first App Store release**, the build you already have in TestFlight (e.g. 1.0.0 (1)) can usually be used as the release build. If you had to fix something (e.g. iPad orientations), upload a new build with a higher build number and select that in “Prepare for Submission”.

---

## 7. Export compliance & other legal

- **Export compliance:** You already addressed this (no custom encryption). If the build asks again in App Store Connect, answer “No” for encryption beyond standard HTTPS.
- **Advertising Identifier (IDFA):** Your app doesn’t use it; answer “No” if asked.
- **Content rights / third-party content:** Confirm you have rights to all content (you do for this app).

---

## 8. Submit for review

- In **Prepare for Submission**, fill every required field (no red warnings).
- Click **Add for Review**, then **Submit to App Review**.
- Apple typically reviews within 24–48 hours (sometimes faster). You’ll get an email with the result.

---

## Quick checklist (before you submit)

- [ ] App Information: name, subtitle, category, age rating
- [ ] Pricing: free (or chosen price) and availability
- [ ] Version 1.0.0: screenshots (6.7", 6.5", 5.5"), description, keywords
- [ ] Support URL and Privacy Policy URL
- [ ] Build selected (the one from TestFlight or a new one with same version)
- [ ] Copyright and App Review contact
- [ ] App Privacy questionnaire completed
- [ ] 1024×1024 app icon in the build
- [ ] Export compliance / encryption answered
- [ ] Submit to App Review

Once you’ve done the above, you’re ready for public App Store release.
