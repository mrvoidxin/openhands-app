<div align="center">

# OpenHands Mobile

**The OpenHands Agent Canvas, packaged as an Android app.**

Run and supervise your AI coding agents from your phone.

[![Download APK](https://img.shields.io/badge/Download-APK-6c5ce7?style=for-the-badge&logo=android&logoColor=white)](https://github.com/mrvoidxin/openhands-mobile/releases/latest/download/app-release.apk)
[![Website](https://img.shields.io/badge/Website-openhands--mobile-FF6A3D?style=for-the-badge&logo=githubpages&logoColor=white)](https://mrvoidxin.github.io/openhands-mobile/)
[![Version](https://img.shields.io/badge/version-1.27.1-blue?style=for-the-badge)](https://github.com/mrvoidxin/openhands-mobile/releases/tag/v1.27.1)
[![Build](https://github.com/mrvoidxin/openhands-mobile/actions/workflows/build-android-apk.yml/badge.svg)](https://github.com/mrvoidxin/openhands-mobile/actions/workflows/build-android-apk.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](https://github.com/mrvoidxin/openhands-mobile/blob/main/OpenHands-main/LICENSE)
[![Support via UPI](https://img.shields.io/badge/Support-UPI-ff9f1c?style=for-the-badge&logo=buymeacoffee&logoColor=white)](#support-this-project)

</div>

---

## Download

**The download link below never changes.** It always serves the newest release.

| Build | Size | Link |
| --- | --- | --- |
| **Release (recommended)** | 6.0 MB | **[app-release.apk](https://github.com/mrvoidxin/openhands-mobile/releases/latest/download/app-release.apk)** |
| Debug (verbose logs) | 7.4 MB | [app-debug.apk](https://github.com/mrvoidxin/openhands-mobile/releases/latest/download/app-debug.apk) |

All builds: [Releases page](https://github.com/mrvoidxin/openhands-mobile/releases)

There is also a landing page with install steps and checksums:
**<https://mrvoidxin.github.io/openhands-mobile/>**

### Verify your download

The release APK is signed. You can confirm you have the exact file:

```
File:    app-release.apk
Size:    6,257,650 bytes
MD5:     2365d6465759187c4c5a6716c2219242
SHA-256: bafcfe8551441213f8a22ae99edb77104d0590986eeb258651244a5be9c25a6d
Package: dev.openhands.agentcanvas
```

Check it on your phone or PC:

```bash
md5sum app-release.apk                     # Linux / macOS
certutil -hashfile app-release.apk MD5     # Windows
```

---

## What is this?

[OpenHands Agent Canvas](https://github.com/OpenHands/OpenHands) is a web UI for
running AI coding agents. This project wraps that web app in a native Android
shell using [Capacitor](https://capacitorjs.com/), so you can launch it, watch
runs, and approve actions from a phone.

The app contains **the same UI as the browser version** (`@openhands/agent-canvas`
v1.27.1). It is a client — it talks to an OpenHands agent server that you run
yourself, on your laptop, a server, or in the cloud.

**This is a community packaging, not an official OpenHands release.**

---

## Requirements

| Item | Value |
| --- | --- |
| Android version | 6.0 (Marshmallow, API 23) or newer |
| Architecture | Universal — arm64, armv7, x86_64 (no native code) |
| Permissions | Internet only |
| Backend | A reachable OpenHands agent server (you provide it) |

The app needs network access to your agent server. It does **not** bundle a
backend, and it does not send your data anywhere by itself.

---

## Install

1. On your phone, open the [download link](https://github.com/mrvoidxin/openhands-mobile/releases/latest/download/app-release.apk).
2. If Android asks, allow **install from unknown sources** for your browser or
   file manager. (Settings → Apps → Special access → Install unknown apps.)
3. Open the downloaded APK and tap **Install**.
4. You may see a Play Protect warning because the app is not distributed through
   the Play Store. Tap **Install anyway**.
5. Launch **OpenHands** from your app drawer.

---

## First launch

The app does not know where your agent server lives. On first launch it shows a
setup screen:

1. **Server URL** — the address of your OpenHands agent server, for example
   `https://my-server.example.com` or `http://192.168.1.10:3000` on your home
   network. Use `https://` for anything reachable over the internet.
2. **API key** — the key your agent server expects.
3. Tap **Connect**.

Your settings are stored on the device. To change them later, open
**Settings** inside the app.

> Tip: to bake the server URL into the APK so users skip this step, set the
> repository variable `BACKEND_BASE_URL` before building. See
> [Building from source](#building-from-source).

---

## Features

Everything the Agent Canvas web UI offers, adapted for a touch screen:

- **Conversations** — start a task, watch the agent work, read the diff.
- **Multiple backends** — local, remote, or cloud agent servers.
- **Agent profiles and settings** — pick the model, tools, and prompt.
- **Automations** — schedule recurring agent tasks and review their runs.
- **Skills and extensions** — manage reusable agent capabilities.
- **Files, commits, browser and terminal tabs** — inspect what the agent did.
- **MCP and LLM settings** — configure tool servers and model providers.
- **Secrets management** — store credentials for your agents.

---

## Building from source

You need Node.js 24+, JDK 21, and the Android SDK.

```bash
# 1. Get the code
git clone https://github.com/mrvoidxin/openhands-mobile.git
cd openhands-mobile/OpenHands-main

# 2. Install dependencies
npm ci
npm install --no-save @capacitor/core@7 @capacitor/cli@7 @capacitor/android@7

# 3. Build the web bundle
#    Leave VITE_BACKEND_BASE_URL unset to show the in-app setup screen.
npm run build:app

# 4. Copy the web bundle into the Android project
npx cap sync android

# 5. Build the APK
cd android
./gradlew assembleRelease
```

The APK lands in `android/app/build/outputs/apk/release/app-release.apk`.

To bake in your own server URL, set it before step 3:

```bash
VITE_BACKEND_BASE_URL=https://my-server.example.com npm run build:app
```

### Signing

The repo ships a throwaway keystore at
`OpenHands-main/android/app/release.keystore` so builds are installable by
sideloading. **It is not a Play Store upload key.** For your own distribution,
generate a keystore and keep it private:

```bash
keytool -genkey -v -keystore my-release.keystore -alias mykey \
  -keyalg RSA -keysize 2048 -validity 10000
```

---

## Continuous integration

The workflow at
[`.github/workflows/build-android-apk.yml`](.github/workflows/build-android-apk.yml)
builds a signed APK on every push to `main`, and on every version tag it also
attaches the APKs to the GitHub Release.

### Cutting a new release

```bash
git tag v1.28.0
git push origin v1.28.0
```

GitHub Actions builds the APKs and publishes them. The `releases/latest/download`
links above then point at the new version automatically — no need to update any
documentation.

### Optional repository settings

| Name | Type | Purpose |
| --- | --- | --- |
| `BACKEND_BASE_URL` | Variable | Bakes the agent server URL into the app. |
| `ANDROID_KEYSTORE_BASE64` | Secret | Use your own signing key instead of the bundled one. |

---

## Troubleshooting

| Problem | Fix |
| --- | --- |
| "App not installed" | Uninstall any older copy first, then install again. |
| Play Protect blocks install | Tap **Install anyway**; the APK is not from the Play Store. |
| App opens but cannot connect | Check the server URL and that the phone can reach it. Use `https://` for remote servers. |
| Stuck on the loading screen | Confirm the agent server is running, then reopen the app. |
| Blank screen after an update | Clear app data in Android settings and reconnect. |

---

## Support this project

This app is **free and open source**, and it always will be. You do not have to
pay anything to download it, use it, or modify it.

That said, if this project saved you some time and you feel like saying thanks,
a small contribution is genuinely appreciated. It goes towards keeping the build
pipeline running and putting more time into improvements.

### Pay via UPI (India)

| | |
| --- | --- |
| **UPI ID** | `mrsameer1906@okhdfcbank` |
| **Name** | Sameer |

Scan the QR code with any UPI app — GPay, PhonePe, Paytm, BHIM, or your bank's
app — and the payment details fill in automatically:

<div align="center">

<img src="assets/upi-qr.png" alt="UPI QR code for mrsameer1906@okhdfcbank" width="240">

</div>

**Or copy this UPI ID** into the "Pay to UPI ID" field of your UPI app:

```
mrsameer1906@okhdfcbank
```

No amount is suggested and nothing is expected. Give only if you want to, and
only what you are comfortable with. Thank you either way.

### Other ways to help (free)

Not everyone can or should send money. These help just as much:

- **Star this repository** so more people can find it.
- **Report a bug** or suggest an improvement in
  [Issues](https://github.com/mrvoidxin/openhands-mobile/issues).
- **Tell someone** who would find a mobile OpenHands client useful.
- **Contribute** a fix or a feature through a pull request.

---

## Credits and license

- The UI is [OpenHands Agent Canvas](https://github.com/OpenHands/OpenHands),
  licensed under MIT. All credit for the application belongs to the OpenHands
  project and its contributors.
- This repository only adds the Android packaging (Capacitor) and the build
  pipeline. Packaged and maintained by **Sameer**
  ([@mrvoidxin](https://github.com/mrvoidxin)).
- The Android wrapper is released under the MIT license as well.

This project is not affiliated with or endorsed by the OpenHands team.

---

<div align="center">

**[Download the latest APK](https://github.com/mrvoidxin/openhands-mobile/releases/latest/download/app-release.apk)**

If it helped you, you can [buy me a chai ☕](#support-this-project) — but only if you want to.

</div>
