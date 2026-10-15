# Android APK

Ye document batata hai ki OpenHands Mobile ka Android APK kaise build hota hai
aur kaise release hota hai.

## Normal users ke liye (build ki zaroorat nahi)

Seedha signed APK download karein:

**<https://github.com/mrvoidxin/openhands-mobile/releases/latest/download/app-release.apk>**

Install steps aur checksums ke liye repo ka [README](../../README.md) ya
landing page <https://mrvoidxin.github.io/openhands-mobile/> dekhein.

> Note: Ye ek **signed release APK** hai, debug build nahi. App khud kuch
> download nahi karta — ye sirf ek client hai jo aapke apne OpenHands agent
> server se baat karta hai.

## Khud build karna ho (maintainers)

1. **Backend URL set karein.** Repo mein **Settings → Secrets and variables →
   Actions → Variables** open karein aur `BACKEND_BASE_URL` add karein
   (e.g. `https://your-agent-server.example.com`). Ye URL phone se reachable
   hona chahiye — `localhost` kaam nahi karega, kyunki phone alag device hai.
2. **Signing secrets** add karein (Settings → Secrets and variables → Actions →
   Secrets). Inke bina workflow unsigned APK banayega aur **release publish
   nahi karega**:
   - `ANDROID_KEYSTORE_BASE64` — release keystore ka base64
   - `ANDROID_KEYSTORE_PASSWORD` — store password
   - `ANDROID_KEY_PASSWORD` — key password
   - `ANDROID_KEY_ALIAS` — key alias (default `openhands`)
3. **Actions → Build Android APK → Run workflow** chalayein.
4. Run complete hone par **Artifacts** se `openhands-release-apk` (signed) ya
   `openhands-debug-apk` (debug) download kar sakte hain.

## Release publish karna

Release sirf `v*` tag push karne par publish hota hai:

```bash
git tag v1.27.3
git push origin v1.27.3
```

Workflow APK build karta hai, verify karta hai, aur usko GitHub Release par
attach kar deta hai — jo permanent download URL deta hai. Debug APK release par
**publish nahi** hota; wo sirf CI artifact hota hai.

Details ke liye repo ke root wale workflow
(`.github/workflows/build-android-apk.yml`) aur [README](../../README.md) ka
"Continuous integration" section dekhein.
