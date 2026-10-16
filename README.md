<div align="center">

# OpenHands Mobile

**The OpenHands Agent Canvas, packaged as an Android app.**

Run and supervise your AI coding agents from your phone.

[![Download APK](https://img.shields.io/badge/Download-APK-6c5ce7?style=for-the-badge&logo=android&logoColor=white)](https://github.com/mrvoidxin/openhands-mobile/releases/latest/download/app-release.apk)
[![Website](https://img.shields.io/badge/Website-openhands--mobile-FF6A3D?style=for-the-badge&logo=githubpages&logoColor=white)](https://mrvoidxin.github.io/openhands-mobile/)
[![Version](https://img.shields.io/badge/version-1.27.3-blue?style=for-the-badge)](https://github.com/mrvoidxin/openhands-mobile/releases/tag/v1.27.3)
[![Build](https://github.com/mrvoidxin/openhands-mobile/actions/workflows/build-android-apk.yml/badge.svg)](https://github.com/mrvoidxin/openhands-mobile/actions/workflows/build-android-apk.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](https://github.com/mrvoidxin/openhands-mobile/blob/main/LICENSE)
[![Support via UPI](https://img.shields.io/badge/Support-UPI-ff9f1c?style=for-the-badge&logo=buymeacoffee&logoColor=white)](#support-this-project)

</div>

---

## Download

**The download link below never changes.** It always serves the newest release.

| Build | Size | Link |
| --- | --- | --- |
| **Release (signed)** | 6.0 MB | **[app-release.apk](https://github.com/mrvoidxin/openhands-mobile/releases/latest/download/app-release.apk)** |

All builds: [Releases page](https://github.com/mrvoidxin/openhands-mobile/releases)

> **Upgrading from a build older than v1.27.2?** That version was signed with a
> different key, so Android will not install this over the top. Uninstall the old
> app first, then install this APK. Your settings live in the app's data, so
> they are removed with it — note down your agent server URL before you upgrade.

The debug build is a debuggable APK and is not published as a download. It is
available as a CI workflow artifact to signed-in users.

There is also a landing page with install steps and checksums:
**<https://mrvoidxin.github.io/openhands-mobile/>**

### Get automatic updates with Obtainium

This app is not on the Play Store. To get notified about new versions, add it to
[Obtainium](https://github.com/ImranR98/Obtainium) — a free, open-source app that
installs and updates apps straight from their GitHub releases.

[![Get it on Obtainium](docs/assets/badge_obtainium.png)](https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%7B%22id%22%3A%22dev.openhands.agentcanvas%22%2C%22url%22%3A%22https%3A%2F%2Fgithub.com%2Fmrvoidxin%2Fopenhands-mobile%22%2C%22author%22%3A%22mrvoidxin%22%2C%22name%22%3A%22OpenHands%20Mobile%22%7D)

Tap the badge on your phone and Obtainium fills in the details for you. Or add
this URL by hand:

```
https://github.com/mrvoidxin/openhands-mobile
```

### Verify your download

The release APK is signed. You can confirm you have the exact file:

```
File:    app-release.apk
Size:    6,456,583 bytes
MD5:     2047bfcc1cad3b81a1102652fc3d323d
SHA-256: 5640e965f98712bc4967c576e242af250b3f066a80ec693bc346511ce3fcbf62
Package: dev.openhands.agentcanvas
Signer:  SHA-256 0D:96:FA:45:8C:34:42:D2:28:AC:C8:56:97:04:10:4A:4E:83:44:3A:68:0E:DF:81:C6:AE:0D:D1:6D:DA:81:12
```

Check it on your phone or PC:

```bash
sha256sum app-release.apk                  # Linux / macOS
certutil -hashfile app-release.apk SHA256  # Windows
```

To confirm the APK really came from this project, compare the signing
certificate above — `apksigner verify --print-certs app-release.apk`.

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

> **In-place updates.** Every build from v1.27.2 onward is signed with the same
> key, which the release workflow pins and verifies before publishing. You can
> download a new version and install it straight over the old one — no uninstall,
> no lost settings. See [SIGNING.md](SIGNING.md) for the certificate fingerprint.

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

The signing keystore is **not** in the repository. It lives only as an
encrypted GitHub Actions secret, so the private key is never public.

The key is pinned: the release workflow compares the APK's signer against a
recorded fingerprint and **refuses to publish if it ever changes**, so users
always get an in-place update. Full detail, including the fingerprint and the
backup and rotation rules, is in [SIGNING.md](SIGNING.md).

Generate a keystore once, and keep the file backed up somewhere safe — if you
lose it you can no longer publish updates that install over the existing app:

```bash
keytool -genkey -v -keystore release.keystore -alias openhands \
  -keyalg RSA -keysize 2048 -validity 10000
```

Then add four repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 release.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | the store password you chose |
| `ANDROID_KEY_PASSWORD` | the key password you chose |
| `ANDROID_KEY_ALIAS` | the alias, e.g. `openhands` |

CI writes `release.keystore` from the secret, signs, and verifies the result.
A local build reads the same names from the environment:

```bash
export OPENHANDS_KEYSTORE_PASSWORD=...
export OPENHANDS_KEY_PASSWORD=...
export OPENHANDS_KEY_ALIAS=openhands
# drop release.keystore at OpenHands-main/android/app/release.keystore
```

Never commit the keystore. `.gitignore` already excludes `*.keystore` and `*.jks`.

#### Keystore backup and recovery

The private key exists in exactly two places: the GitHub Actions secret, and a
local backup you keep yourself. If both are lost, you can never publish an
update that installs over the existing app — users would have to uninstall
first, and Android would treat the new build as a different app.

Keep the backup **outside** this repository and never serve it from a web
directory. A safe backup bundle contains:

| File | Why |
| --- | --- |
| `release.keystore` | the private key itself |
| `release-cert.pem` | the public certificate, for verification |
| `CREDENTIALS.txt` | the alias and the two passwords |
| `CHECKSUMS.txt` | SHA-256 of the keystore, to detect corruption |

Store that bundle in a password manager, an encrypted archive, or offline
media. To check a backup is still valid and matches the published app:

```bash
keytool -list -keystore release.keystore -storetype PKCS12 \
  -storepass "$STORE_PASSWORD" | grep -i privatekeyentry

# fingerprint must match the certificate the published APK was signed with
keytool -printcert -jarfile app-release.apk | grep SHA256
keytool -printcert -file release-cert.pem | grep SHA256
```

To rebuild a lost GitHub secret from a backup:

```bash
base64 -w0 release.keystore   # paste into ANDROID_KEYSTORE_BASE64
```

If the keystore is genuinely gone, generate a new one, bump the version, and
tell users to uninstall the old app before installing the new build.

---

## Continuous integration

The workflow at
[`.github/workflows/build-android-apk.yml`](.github/workflows/build-android-apk.yml)
builds the APK on every push to `main`, and on every version tag it signs the
release APK with the secret key and attaches it to the GitHub Release.

### Cutting a new release

1. Bump `versionCode` and `versionName` in
   `OpenHands-main/android/app/build.gradle`.
2. Commit, then tag and push:

```bash
git tag v1.28.0
git push origin v1.28.0
```

GitHub Actions builds and publishes the APK. The `releases/latest/download`
links then point at the new version automatically — no documentation to update.
The publish step only runs when the keystore secret is present, so an unsigned
APK can never be released by accident.

### Optional repository settings

| Name | Type | Purpose |
| --- | --- | --- |
| `BACKEND_BASE_URL` | Variable | Bakes the agent server URL into the app. |
| `SIGNING_CERT_SHA256` | Variable | Optional. Overrides the pinned signer fingerprint. Set this only when rotating the key on purpose. |
| `ANDROID_KEYSTORE_BASE64` | Secret | The signing keystore, base64-encoded. Required to publish. |
| `ANDROID_KEYSTORE_PASSWORD` | Secret | Keystore store password. |
| `ANDROID_KEY_PASSWORD` | Secret | Keystore key password. |
| `ANDROID_KEY_ALIAS` | Secret | Keystore key alias. |

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

**All credit for the application belongs to the OpenHands project.**

- The app is [OpenHands Agent Canvas](https://github.com/OpenHands/OpenHands),
  built by **All Hands AI** and its contributors, and released under the MIT
  license. The interface, the agent canvas and everything inside the app are
  their work.
- The launcher icon and logo are the **official OpenHands artwork**, used
  unchanged (the yellow mark on white). No custom branding is applied.
- This repository only adds the Android packaging (Capacitor wrapper, icons,
  splash screen) and the build pipeline. Packaged and maintained by **Sameer**
  ([@mrvoidxin](https://github.com/mrvoidxin)).
- The Android wrapper is released under the MIT license as well.

This project is not affiliated with or endorsed by the OpenHands team or All
Hands AI. If you want the official product, see
<https://github.com/OpenHands/OpenHands>.

---

<div align="center">

**[Download the latest APK](https://github.com/mrvoidxin/openhands-mobile/releases/latest/download/app-release.apk)**

If it helped you, you can [buy me a chai ☕](#support-this-project) — but only if you want to.

</div>
