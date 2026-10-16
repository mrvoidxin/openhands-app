# Project memory

Detail lives in the daily logs (`2026-10-15.md`, `2026-10-16.md`); this file is the
index. The workspace was reused: entries about `ytkit-android` / `dl-service` belong
to an older project and are archived in `2026-10-11-ytkit-archive.md`. Verify paths
before trusting any memory.

## Current project: `openhands-mobile`
OpenHands Agent Canvas React/TS frontend (`@openhands/agent-canvas`) packaged for
Android with Capacitor. The repo tracks `OpenHands-main/` (source + the generated
`android/` project) so CI can build it.

- **Repo was renamed** from `opanhand-mobile-` (typo) to `openhands-mobile`; the
  local folder matches. Old URLs 301-redirect.
- Landing page: https://mrvoidxin.github.io/openhands-mobile/ , served by GitHub
  Pages from `main:/docs` (legacy build) - **pushing to `main` is the deploy**, no
  workflow involved. `docs/.nojekyll` is required or Pages skips `assets/`.
- **Permanent download link (never goes down):**
  https://github.com/mrvoidxin/openhands-mobile/releases/latest/download/app-release.apk
- **IzzyOnDroid is a dead end** (their policy rejects LLM front-ends). Distribute via
  GitHub Releases + an Obtainium badge instead.
- Current release **v1.27.3**: 6,456,583 bytes, SHA-256
  `5640e965f98712bc4967c576e242af250b3f066a80ec693bc346511ce3fcbf62`, signer
  `0D:96:FA:45:...:DA:81:12`. All three verified against the live asset on
  2026-10-16. The landing page quotes these; keep them in sync.
- **The published APK is built by CI, never locally**, and Android CI builds are
  **not byte-reproducible** - same commit gives a different SHA-256. So the
  documented hash must be refreshed after every publish. Release assets change only
  on a `v*` tag push: never re-tag an existing version, bump `versionCode`/`versionName`.

### Signing (do not regress - explicit user requirement)
Every future APK must be signed with the same key so users update in place and never
uninstall. The keystore and password were once committed publicly; both were removed
and the app **re-signed with a new key**, so v1.27.2 does NOT install over older
builds (one-time uninstall for those). `build.gradle` reads
`OPENHANDS_KEYSTORE_PASSWORD` / `_KEY_PASSWORD` / `_KEY_ALIAS` from the environment
and only signs when a keystore file exists. CI restores the keystore from the
`ANDROID_KEYSTORE_BASE64` secret and **gates the publish step on it being present**,
so an unsigned APK can never be released. `SIGNING.md` documents it.

- Pinned signer SHA-256 (public, safe in the repo):
  `0D:96:FA:45:8C:34:42:D2:28:AC:C8:56:97:04:10:4A:4E:83:44:3A:68:0E:DF:81:C6:AE:0D:D1:6D:DA:81:12`
  (self-signed, `CN=OpenHands Mobile`, valid to 2054-03-02).
- CI `Verify the release APK` compares the built APK's signer to that value and fails
  on mismatch. Override only on a deliberate rotation via `SIGNING_CERT_SHA256`.

### Verifying a release (no JDK needed)
The release APK uses **APK Signature Scheme v2** - there is no `META-INF/*.RSA`, so
`keytool`/`apksigner` are unnecessary. Parse the APK Signing Block directly: find
`APK Sig Block 42` before the EOCD, read the `u64` size that precedes the magic, walk
`[u64 len][u32 id][value]` pairs from `magic - size + 16` to `magic - 8`, take pair id
`0x7109871A`, then read length-prefixed signers -> signer -> signedData ->
(digests, certificates) and hash the first cert. (An earlier note blamed a wrong
fingerprint on hand-rolling; the real bug was the offset math.)
`GET /repos/mrvoidxin/openhands-mobile/actions/runs` (needs `$GITHUB_TOKEN`) shows CI
status - a green run on `main` is the proof the APK still builds.

### Credentials / pushes
`GITHUB_TOKEN` here is a **read-only GitHub App token** (`ghu_...`): API reads work, but
`git push`, secret writes and repo-settings writes 403 with "Resource not accessible
by integration". The user's own classic PAT (`ghp_...`, `repo`+`workflow` scope) is
recovered from the conversation event logs under `/workspace/conversations/*/events/`
(`grep -l ghp_`). Never echo it. A **local** credential helper is required or
`git push` hangs on `Username for 'https://github.com':` until timeout:
`git config --local credential.helper '!f() { echo "username=mrvoidxin"; echo "password=$(cat $HOME/.gh_pat)"; }; f'`

### Serving artifacts to the user (self-healing)
Host mapping: `https://work-1-<id>.prod-runtime.all-hands.dev/` -> port 12000,
`work-2-...` -> 12001. A host returns 502 until something listens. `dl/serve.py`
**redirects** to the release asset (it once held a stale copy that drifted); path
`/app-release.apk`; answers **both GET and HEAD** (a HEAD-only 404 broke download
managers). `dl/autostart.sh` (idempotent, wired into `.openhands/hooks.json`
session_start) starts `dl/supervisor.py`, which owns `serve.py` on both ports,
respawns it within 15s, pings the runtime to defeat the 1200s idle sleep, and
`dl/watchdog.sh` restarts the supervisor. Only *bash* activity resets the idle timer.

## Landing page (docs/index.html)
One hand-written, self-contained file (~95 KB, inline CSS/JS, inline SVG). Sections:
nav > hero > overview > features > screens > install > verify > requirements > faq >
support > footer, plus a mobile sticky download bar. Rebuilt 2026-10-16.

- **Animation lessons (expensive):** staged entrances must use CSS keyframes +
  `animation-delay` + `fill-mode: backwards`, NOT transitions driven by a class
  toggle (collapses into a jump depending on paint timing). Every animated pre-state
  must be scoped to a class the script adds (`html.anim`, `.intro`), or a JS failure
  leaves content permanently hidden. Hover lifts on stagger children must use the
  `translate` property, because `.stagger.is-in>*{transform:none}` overrides `transform`.
- **Do not expect headless Chromium to verify scroll/motion** - rAF advances one frame
  and smooth scrolling never animates under `--virtual-time-budget`. Layout and
  image-loading checks do work.
- Verify section quotes the release facts above. Note the brief once specified
  v1.27.2 numbers; the page now carries the live v1.27.3 ones.

### Screens section (added 2026-10-16)
- `#screens` sits between `#features` and `#install`; nav link `data-nav="screens"`;
  later sections renumbered. Assets: `docs/assets/screens/*.webp` (742x1484).
  Replaced 2026-10-16 with clean captures (the first set overlapped).
- `.shots` is a CSS grid: a horizontal snap-scroll rail below 980px
  (`grid-auto-flow:column; grid-auto-columns:78%` + `scroll-snap-type:x mandatory`,
  scrollbar hidden) and `repeat(4,1fr)` at/above 980px.
- **Trap:** `repeat(auto-fit,minmax(190px,1fr))` looks fine at 1440px but collapses to
  ~165px per phone at 768px. Measure 768 and 1024, not just phone and desktop. Also,
  reusing `.caps` (2-col grid + sticky head) squeezed the shots into 620px - wide
  content sections need a plain full-width `.container` + `.sec-head`.

## Capturing real app screens without an emulator
**The built Capacitor web bundle is committed** at
`OpenHands-main/android/app/src/main/assets/public/`. Serve that directory and drive it
with headless Chromium (Playwright) to render the real first-run UI. This is the only
way to shoot the app here.

- The onboarding wizard is a **transform carousel**: all four slides are in the DOM at
  `x=50/362/675/988` and the slider carries inline `transform: translateX(...)`; only
  the active slide is painted. To shoot a given step, **set every sibling's inline
  transform to `translateX((j-idx)*100%)`** (instant jump, no animation) - then ordinary
  `element.screenshot()` on the slide container is correct. Cloning into an overlay
  also works but the transform shift is simpler and was the final method.
- **The telemetry consent card silently overlays the wizard** and is the cause of the
  "word over word" overlap. It shows while `user_consents_to_analytics === null` from
  **`/api/settings`**. Setting the mock to `true` did NOT dismiss it before capture;
  remove the `[data-testid=telemetry-consent-form]` element (walk up to nearest
  `role=dialog`) instead. Shoot each step after dismissal.
- The mock `/api/settings` backend **does** advance the wizard once `/api/agent-profiles`
  returns `{profiles:[...]}` (not a bare array) and `/api/settings/agent-schema` returns
  `{sections:[{key,label,fields:[{key,label,value_type,choices}]}]}`.
- Route-intercept a fake hostname in Playwright and proxy to the mock so shots show a
  real-looking URL, not `127.0.0.1:13240`.
- Pad short frames to a uniform height with the card's own bg (`rgb(32,32,32)`) rather
  than stretching. **Confirm frames with tesseract OCR** - crisp OCR means no overlap.
- Promo kit `docs/promo/instagram-*-screens-*.png` embeds the same captures; swap the
  frames in place (detected box coords are in the 2026-10-16 daily log).

## Environment (reusable, expensive to rediscover)
- **Sandbox restarts wipe `/tmp` but keep `/workspace`.** A PAT parked in `/tmp` is gone
  after a wake, and so is an apt-installed JDK. Prefer `/workspace` for anything durable.
- **No `/dev/kvm`** -> the Android emulator never boots; `screencap` gives black frames
  even when it does. Verify by build + the web-bundle capture method above.
- **No JDK in this sandbox**, so `gradle assembleRelease` cannot run locally - never
  claim a local APK build. Android SDK is at `/workspace/tools/android-sdk`
  (build-tools 34/35). No `unzip` (use python `zipfile`); no ImageMagick (use Pillow).
- **The `apksigner` PATH trap (cost a whole release cycle):** apksigner is a shell
  wrapper that `exec java`, so a CI step must `export PATH="$JAVA_HOME/bin:$PATH"`
  before calling it, or it dies silently and a signed release gets labelled "NOT signed".
- Egress works to dl.google.com, services.gradle.org, maven, npm.
- `.openhands/memory/` is tracked in git, so switching branches reverts uncommitted
  memory edits.

## Other assets
- Branding: every launcher icon and all 11 splash screens derive from
  `public/android-chrome-512x512.png` via `tools/make_android_icons.py`;
  `docs/assets/og-preview.png` (1200x630) via `tools/make_og_image.py`. `cap sync`
  does not overwrite `android/app/src/main/res`, so icons survive CI.
- Promo kit in `docs/promo/` (Instagram carousel + squares + wide banner + captions).
  Instagram crops a post to a centred 810px band for the profile grid, so keep all
  content inside it - `shoot.py` asserts this.
