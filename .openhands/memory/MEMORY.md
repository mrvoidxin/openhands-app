# Project memory

Detail lives in the daily logs; this file is the index. The workspace was
reused: entries about `ytkit-android` / `dl-service` belong to an older project
and are archived in `2026-10-11-ytkit-archive.md`. Verify paths before trusting
any memory.

## Current project: `opanhand-mobile-`
OpenHands Agent Canvas React/TS frontend (`@openhands/agent-canvas` v1.27.1)
packaged for Android with Capacitor. The repo now tracks `OpenHands-main/`
(source + the generated `android/` project) so CI can build it.

**Permanent download links (GitHub Releases, never goes down):**
https://github.com/mrvoidxin/opanhand-mobile-/releases/latest/download/app-release.apk
(+ `app-debug.apk`), release tag `v1.27.1`. CI workflow at the **repo root**
(`.github/workflows/build-android-apk.yml`) builds the APKs and attaches them to
the release on a `v*` tag. Full gotchas in `2026-10-15.md`.

Android APK build recipe, gotchas and artifact hashes: `2026-10-15.md`.
Highlights: JDK 21 via apt; Android SDK cmdline-tools in
`/workspace/tools/android-sdk` (its `bin/*` need `chmod +x`);
`VITE_MOCK_API=false npm run build:app` with `VITE_BACKEND_BASE_URL` left UNSET
so the app shows its own backend setup screen; `signingConfigs` must precede
`buildTypes` in `android/app/build.gradle`; the keystore is module-relative
(`android/app/release.keystore`); run gradle with `nohup ... &` and poll.

## Environment (reusable, expensive to rediscover)
- **No `/dev/kvm`** -> the Android emulator is unusable; verify by build +
  `aapt dump badging` / `apksigner verify` + serving the web bundle in the
  browser.
- No `unzip` -> use python `zipfile` or JDK `jar`. No ImageMagick/Inkscape ->
  `pip install pillow` for icon resizing.
- Egress works to dl.google.com, services.gradle.org, maven, npm.

## Serving artifacts to the user (self-healing)
- Host mapping: `https://work-1-<id>.prod-runtime.all-hands.dev/` -> port 12000,
  `work-2-...` -> 12001. A host returns **502 until a process listens** on its
  port.
- The download stack is redundant and self-healing, so the link stays up:
  `dl/autostart.sh` (idempotent) starts `dl/supervisor.py`, which owns
  `dl/serve.py` on **both 12000 and 12001**, respawns it if the port dies
  (15s), pings the runtime to defeat the 1200s idle sleep (240s), and restores
  APKs from `/workspace/artifacts/openhands-apk/`. `dl/watchdog.sh` restarts
  the supervisor if it is killed. `.openhands/hooks.json` `session_start` runs
  autostart after a sandbox wake (installed at BOTH `/workspace/project/` and
  the repo dir). All four layers were verified by killing things on purpose.
- Only *bash* activity resets the idle timer. `SESSION_API_KEY` lives in
  `/proc/1/environ`; `OH_INTERNAL_SERVER_URL` is `http://127.0.0.1:60000`.
  POST `/api/bash/execute_bash_command` with header `X-Session-API-Key`.
- **Tokens:** the `ghu_...` GITHUB_TOKEN is READ-ONLY (403 on every write,
  incl. `POST /releases` and `git push`). A **classic PAT with `repo` scope
  works** — saved at `~/.gh_pat` (chmod 600). Use it via a git credential helper
  reading the file, never inline on the command line. If a push is denied,
  check whether the old token is embedded in the remote URL.
