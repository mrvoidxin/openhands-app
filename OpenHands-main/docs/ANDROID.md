# Android APK

1. GitHub repo mein **Settings → Secrets and variables → Actions → Variables** open karein aur `BACKEND_BASE_URL` add karein (e.g. `https://your-agent-server.example.com`). Backend phone se reachable hona chahiye, localhost kaam nahi karega.
2. **Actions → Build Android APK → Run workflow** chalayein.
3. Run complete hone par **Artifacts** se `openhands-debug-apk` download karein aur phone par install karein (Unknown sources allow karni hogi).

Note: Ye debug APK hai. Play Store ke liye release signing alag se karni hogi.
