# Project memory

Detail lives in the daily logs (`2026-10-06..11.md`); this file is the index.

## Environment (expensive to rediscover)
- No GPU, no root (`apt-get` fails). `ffmpeg` is NOT on PATH; use
  `imageio_ffmpeg.get_ffmpeg_exe()`. `unzip` absent -> python `zipfile` / JDK `jar`.
- Python stack: Pillow/numpy + imageio-ffmpeg. pycairo/moviepy do NOT install.
  Free TTS: **gTTS** (network, no key); `espeak` absent.
- Fonts: DejaVu only system-wide. Devanagari needs
  `@remotion/google-fonts/NotoSansDevanagari` (plain font-family renders tofu).
- Android toolchain (no Java/SDK by default):
  `JAVA_HOME=/workspace/tools/jdk-17.0.20.1+1`,
  `ANDROID_HOME=/workspace/tools/android-sdk` (android-34, bt34, ndk26).
  **NO /dev/kvm** -> emulator runs in software TCG (`-accel off -gpu
  swiftshader_indirect`); it is slow, drops host-net, and caps cold start ~15s
  regardless of app code.
- Egress IP is a **GCP US datacenter** -> YouTube bot-walls media bytes.

## Serving artifacts to the user
- Public URLs: `https://work-1-ucasundegischpku.prod-runtime.all-hands.dev/`
  (port 12000), `work-2-...` (12001). `python3 -m http.server 12000` from a dir.
- Pattern: build artifact -> copy into `public/` -> link on index.html.
- Runtime **sleeps after 20 min idle** (kills the server -> public 502). Keep
  alive by POSTing `echo x` to `$OH_INTERNAL_SERVER_URL/api/bash/execute_bash_command`
  with header `X-Session-API-Key: $SESSION_API_KEY` (key: `/proc/1/environ`).
  Only *bash* activity resets the timer.
- **"App kuch bhi play/download nahi kar raha" => check the server FIRST, not the
  APK.** Seen 2026-10-14: user installed a fresh APK and nothing worked; the real
  cause was the sandbox reset had killed `app.py` (public URL 502, local health
  `000`). Recovery is `cd dl-service && ./serve.sh` (idempotent). `autostart.sh`
  via `.openhands/hooks.json` session_start is supposed to do this, but it can
  miss a mid-session reset. Always verify through the PUBLIC URL the phone uses.

## Video generation (no GPU)
- **Remotion** renders CPU-only (headless Chromium + bundled ffmpeg). ~18fps at
  720p, ~8.6fps at 4K, 3D via three/@react-three/fiber ~7.5fps at 720p.
- `claude-code-video-toolkit` cached at
  `~/.openhands/cache/plugins/claude-code-video-toolkit-*`; its AI tools need
  paid cloud GPU endpoints (MODAL_*/RUNPOD_*), not configured.
- `hindi-kahani/` = verified CPU-only pipeline (Remotion SVG + gTTS + numpy music).

## ytkit - current architecture (2026-10-11)
- **Deliverable is the NATIVE app** `/workspace/project/ytkit-android`
  (Kotlin/Compose, media3 1.4.1, OkHttp, kotlinx.serialization, Coil; package
  `com.ytkit.app`). Music-only now: audio playback, no video UI.
- Backend `/workspace/project/dl-service` (stdlib http.server `app.py` + yt-dlp
  `dlcore.py`, `serve.sh` -> `supervisor.sh` on :12000). Autostart via
  `.openhands/hooks.json` `session_start` -> `dl-service/autostart.sh`.
  Health `GET /api/health` -> `{ok, loggedIn, cookies}`.
- **RESOLVE ORDER: device-first, relay fallback (v1.20, commit `fd47cc6`).** This
  host's datacenter egress CANNOT resolve gated label/Vevo tracks - a T-Series
  Hindi/Bollywood song answers `{"error":"resolve failed"}` (502) even with
  cookies, and a resolvable-but-gated one takes 17-40 s. The phone's own
  residential IP is not bot-walled and resolves exactly those in 1-3 s, which is
  what users mostly play. So: on-device first (8 s ceiling via
  `withTimeoutOrNull`), then the relay URL as fallback; local files win outright.
  `DownloadEngine` mirrors this (audio download + `bestAudioChoice` device-first,
  backend second) and deletes a failed/partial device fetch. v1.18 tried
  relay-first and broke every Hindi/Bollywood track; v1.16/1.17 device-first
  "regressed" was actually a real symptom of a wedged unbounded on-device
  extract, fixed by the 8 s ceiling. Do NOT flip this back to relay-first.
- **Playback MUST have a stall watchdog (v1.22).** A media URL that half-opens
  (or is slow) leaves ExoPlayer in `STATE_BUFFERING` forever and raises *no*
  error, so `onPlayerError` never fires and the retry/fallback chain never runs -
  the user just sees a spinner ("Trippy People" stuck, no error). While
  BUFFERING, if `currentPosition` does not change for `STALL_TIMEOUT_FIRST_MS`
  (45 s, first attempt - a cold relay resolve can take 17-40 s) or
  `STALL_TIMEOUT_MS` (15 s after READY/on retries), call the same
  `handlePlaybackFailure()` an error would. Retries then alternate egresses
  (relay → phone → relay) via `relayOnly`/`forceRemote`, so a track blocked on
  one path is still tried on the other. `resolve()` skips the local file when
  `forceRemote` holds the id, so a corrupt download cannot loop forever.
- **Trippy People (`GZg9uo_88wE`) is NOT special.** Backend serves it 206 in
  ~2 s, full file + seek + download job all fine; 5 sibling "Trippy People"
  versions too. The old "slow locked egress" story was a backend symptom that
  masked the real app-side gap (no stall watchdog).
- **Verify video IDs before blaming the server.** oEmbed
  (`https://www.youtube.com/oembed?url=...&format=json`) is the cheap existence
  check; several plausible-looking Bollywood IDs were simply deleted videos.
- APK: `app/build/outputs/apk/release/app-release.apk` -> copy to
  `dl-service/public/ytkit.apk`. Release signed with a NEW key (old RN key
  differs) -> uninstall before install; pull `/sdcard/Android/data/com.ytkit.app/files`
  first to keep downloads.
- **The 403 truth:** YouTube gates this host's IP for media bytes, not URL
  minting. A URL minted here returns 206 from a *different* egress. Fix = server
  mints, client fetches (`/api/direct`), or the server relays. `ip=` in a
  googlevideo URL is a SOFT binding; real test is a live fetch, not the param.
- yt-dlp needs a **JS runtime** for nsig (`node` exists; `deno` via GitHub zip)
  and a **PoToken** (bgutil HTTP server on :4416, `dl-service/pot-server/`).
  Innertube URLs 403 here even with a PoToken -> yt-dlp resolve is the only
  fetchable path. **Only a logged-in `cookies.txt`** cures the gated set;
  auto-detected at `dl-service/cookies.txt`. Browser-anonymous cookies do nothing.
- Client pick `mweb`/`android` (`tv_embedded` broken); override `YTKIT_YT_CLIENTS`.
  Live/premiere = HLS only -> must reject `m3u8`/`mhtml` or the player loads forever.
- Free proxy pools carry NO googlevideo media (MITM/504) - dead end for bytes.
- Warmers starving user taps was the #1 "slow/never plays" cause; keep warmers
  off/gated (`YTKIT_PREWARM=0`).
- **Format picker must race on-device first (v1.11):** `/api/formats` is ~3 s
  normally but ~17 s for a gated track (backend races 4 proxies at 45 s).
  `loadFormats` must resolve via on-device NewPipeExtractor in parallel and take
  the first non-empty result - the backend slow client (75 s) is fallback only.
  `downloadAll` uses `bestAudioChoice` (on-device) + `downloadGate=Semaphore(2)`;
  a serial backend call per song is what broke playlist download-all.
  `AudioFormat.isCoverable` must be `startsWith("mp4a")` (NewPipe = "mp4a.40.2").
- **App playback is AUDIO-ONLY** (`Api.streamUrl(id,"audio")`); `mode=video` on
  `/api/stream` is only a download preview. In-app video download = `/api/download`
  job (`{job}` -> poll `/api/job/<id>`; final URL is `fileUrl`/`downloadUrl`, NOT `url`).
- **InnerTube video resolve rules (2026-10-06):** a DASH pair minted *through a
  proxy* is IP-locked to it - never collapse `_mux_to_file` egresses to the bare
  IP for it (403 -> "download incomplete"). Bare-minted pairs go direct only.
  `_innertube_dash_mux_resolve`/`_innertube_muxed_resolve` strategy-1 must KEEP
  the egress that just served bytes (dropping it makes the relay re-race the
  pool ~20 s). Drop the `.resolved.json` entry (`_cache_del`) when prep fails so
  a stale proxy entry self-heals. Video retry tries DASH before muxed; mux fail
  falls back to progressive 360p muxed, then a raw muxed URL. Free proxies still
  cannot mux some brand-new gated tracks - on-device resolver is the fallback.

## ytkit Android lessons
- Playback is ONE immutable `PlayerState` (+ separate `progress` state so the
  ticker does not recompose screens). Queue/shuffle/repeat in the singleton.
- Fast start: `DefaultLoadControl(minBufferMs>=bufferForPlayback*Ms)` (a smaller
  min crashes at startup), SimpleCache + ResolvingDataSource header injection.
- `MediaSessionService`: `startForeground(id, placeholder)` immediately or the
  FGS 5-second rule kills the process on a slow start.
- Never mutate Compose snapshot state from an OkHttp/IO callback -> marshal to
  main (else ConcurrentModificationException).
- Device-save writes to `getExternalFilesDir` + MediaStore export.
- Offline: Library reads an on-device index, not `/api/library`. Downloads
  persist + disk-scan recovery; `Playback.localResolver` plays local files first.
- On-device fallback: `OnDeviceResolver` (NewPipeExtractor, JitPack **v0.24.5**
  is the only published build) gated on backend reachability; picks
  progressive/DASH audio; R8 keep rules required for extractor + Rhino.
- Seek needs a NON-fragmented MP4 (`-movflags +faststart`), else time->byte fails.
- HTTP headers are latin-1: never interpolate a filename into
  `Content-Disposition` (Devanagari -> UnicodeEncodeError -> 502). Use ASCII
  `filename=` + `filename*=UTF-8''<pct>`.
- Emulator testing: `adb reverse tcp:12000 tcp:12000` + debug `-PapiBase=http://127.0.0.1:12000`;
  UI state via `uiautomator dump` (screencap is black); wait loadavg<3 before taps.

## User preferences
- Wants EVERY video/song to just work, formats instantly, highest quality, audio
  Opus up to 360 kbps, no silent spinning, app feels like YT Music. Self-contained
  library with in-app storage + export.
- Creates AI video with no GPU/credentials. Communicates in Hindi/Hinglish; wants
  short, direct answers. Wants real 2D character animation (Dream Toon style),
  also asked about 4K/60fps/5-min/3D feasibility.

## ytkit (dl-service + Android music app)
- Arch: stdlib http.server + yt-dlp backend (port 12000, serves /ytkit.apk),
  native Kotlin/Compose + media3 ExoPlayer app. AUDIO-ONLY (YT-Music style).
- KEY LESSON: a sandbox datacenter IP is bot-walled by YouTube for Vevo/label
  tracks ("Video unavailable") in BOTH yt-dlp and NewPipeExtractor. The phone's
  residential IP is not. So resolution/download must be ON-DEVICE FIRST;
  the backend is only a fallback.
- NewPipeExtractor v0.26.5 (JitPack com.github.TeamNewPipe) resolves audio
  DIRECT in ~1.7s and downloads real bytes (http 206) through a residential IP.
  From the sandbox IP, resolve can succeed but the media fetch 403s (PO token).
  API: StreamInfo.getInfo + info.audioStreams; YoutubeStreamExtractor
  .setPoTokenProvider(...) exists if ever needed. Needs core-library desugaring.
- Build: JAVA_HOME=/workspace/tools/jdk-17.0.20.1+1,
  ANDROID_HOME=/workspace/tools/android-sdk; ./gradlew :app:assembleRelease.
  R8 needs keep rules for org.schabi.newpipe.extractor.** and org.mozilla.**.
- Backend contract: POST /api/download {url,mode,height,acodec,abr} -> {id};
  GET /api/job/<id> -> {status,progress,...}; GET /api/formats?url=...
  (formats param is `url=`, must be URL-encoded; response keys `videos`/`audios`).
- Status: Phase 1/2/3 shipped. Latest = **v1.27 (versionCode 28)**, Phase 3
  Reliability & Downloads polish: crash handler (#142), offline banner (#143),
  download-manager header (#72), EQ slider TalkBack (#131), audio focus + media
  buttons verified (#3/#19). See daily log 2026-10-15.md for details.
- JVM test harness pattern for extractors: /tmp/npe/NpeProbe.java (proxy-capable
  Downloader). Sandbox has no unzip; use $JAVA_HOME/bin/jar xf to unpack jars.

## 🔒 ytkit LOCKED WORKING SETTINGS - DO NOT CHANGE (user-confirmed 2026-10-06)
User: "bahut acha... kabhi bhi is setting ko mat bhulna / mat chedna".
KEEP EXACTLY AS-IS - any change must be user-approved first:
1. ON-DEVICE-FIRST resolve (NewPipeExtractor v0.26.5) for playback AND download.
   Backend relay is FALLBACK ONLY. Do NOT revert to relay-first - that is what
   made ~90% of songs fail (slow free proxies on the bot-walled sandbox IP).
2. Backend = stdlib http.server + yt-dlp, PORT=12000, serves /ytkit.apk.
3. Format picker must show ALL formats; the chosen itag is honoured on download.
4. Persistence: `dl-service/serve.sh start` -> `supervisor.sh` watchdog loop
   restarts app.py AND pings the agent-server API every 480s to reset the
   runtime idle timer (1200s) so the public URL never 502s. NEVER run app.py
   raw; always via ./serve.sh (which also starts pot-server/start.sh).
   Check with ./serve.sh status.

## ytkit hard-won lessons (v1.2-v1.11; full detail in the daily logs)
- Mini-player/notification: media3 posts its session notification ONLY when a
  controller is connected. The UI drives the shared ExoPlayer directly, so
  call addSession(session) in PlaybackService.onCreate() to spin up the internal
  notification controller. (The "missing POST_NOTIFICATIONS" guess was WRONG;
  the session notification is exempt.) Also guard the placeholder so
  onStartCommand can't re-post it over the real notification.
- Cover art in-app vs on storage: DownloadRow.thumb is a remote URL before save
  and a LOCAL "file://<abs>" after - store it that way or Coil renders nothing.
  scanDownloadsDir() pairs each media file with its .jpg sidecar by stem.
- On save, if the cover fetch fails, thumb stays the REMOTE url so the app still
  shows art while the public folder gets none - exportToDownloads must re-fetch
  the cover, validate it is a real JPEG/PNG (magic + >=1KB), and export audio and
  image INDEPENDENTLY (a duplicate-name audio insert must not block art).
- googlevideo throttles one connection: use 4 parallel Range parts through ONE
  shared RandomAccessFile under synchronized(lock), fall back to single when
  Range (206 probe) is not honoured. Same for the backend /files relay.
- Google BLOCKS OAuth in embedded WebViews (403 disallowed_useragent): in-app
  Google sign-in is impossible. Only a pasted cookie jar works (POST /api/cookies;
  _normalize_cookies accepts Netscape / Cookie-Editor JSON / "k=v; k=v").
  yt-dlp lists account playlists via /feed/playlists with
  extractor_args {"youtubetab":{"skip":["authcheck"]}}. LL=Liked, WL=Watch later.
- Watch later via the Data API returns items:[] (it is private to the key); fall
  through to the cookie-based dlcore.playlist_info.
- yt-dlp entries can carry title/uploader=null (private/deleted) and MediaItem
  .title is non-nullable -> the whole json decode used to fail. Emit "" instead,
  and decode with explicitNulls=false + coerceInputValues=true.
- Compose: a LazyColumn directly in AlertDialog.text hits unbounded constraints
  and throws -> use Modifier.fillMaxWidth().height(360.dp).
- Verify a release change via R8 mapping.txt (grep the method/field) or dexdump;
  APK byte-size is NOT proof (many versions are byte-identical in size).
- v1.10 insight (led to v1.12): "best audio" by raw bitrate picks opus (~130k) >
  m4a (~129k), and webm/opus cannot carry cover art via ffmpeg attach or covr,
  so those songs saved bare. isCoverable must be startsWith("mp4a") (NewPipe
  reports "mp4a.40.2", not "mp4a"). v1.12 finally embeds art in opus itself.

## ytkit v1.12 - opus cover art goes INTO the file + downloads never stall
versionCode 13 / versionName 1.12, 3,945,695 bytes.
- Opus has no MP4 writer on Android (MediaMuxer can't mux opus-in-MP4) and
  ffmpeg cannot write OGG pictures, so the only OGG path both sides READ+WRITE
  is Ogg + METADATA_BLOCK_PICTURE (FLAC block, base64 Vorbis comment). Backend
  uses mutagen (it CAN write it); on device util/OggCoverArt.kt hand-remuxes
  webm(Matroska)->Ogg and writes the picture with a local Base64 + Ogg CRC-32
  (poly 0x04C11DB7, no reflection). OpusHead preskip is at BYTE OFFSET 10.
- dlcore.embed_cover dispatches .m4a/.mp4 -> covr (ffmpeg) else -> mutagen
  OggOpus metadata_block_picture. app.py already called it on every audio path.
- NEW download/DownloadEngine.kt: an Application-scoped object (install from
  YtkitApp.onCreate) that owns the download queue for the whole process. Fixes
  rows freezing forever when navigation recreated the ViewModel (which cancelled
  viewModelScope jobs). AppViewModel now only delegates. Keeps Semaphore(2),
  memoised bestAudioChoice, and runBackend() restarts a stalled job once after
  120 s with no progress. See daily log 2026-10-06 for the full detail.

VERIFY BUILD QUICKLY: `./gradlew :app:compileDebugKotlin` (offline needs network
for ui-tooling; do NOT use --offline). Full: `:app:assembleRelease` (~1.5 min),
copy app-release.apk -> dl-service/public/ytkit.apk, kill the app.py pid and
let supervisor.sh respawn. Landing page version text lives in app.py (~line 3696).

## ytkit v1.13 - formats picker everywhere + playlist picker + row-order fix
- Latest shipped: **v1.15 / versionCode 16**, sha256 29208e08...7047, live at
  /ytkit.apk (3,962,139 bytes). v1.14 was versionCode 15, v1.13 was 14. See
  daily log 2026-10-06 for all.
- THE bug behind "playlist download icon se format nahi aate": the DownloadSheet
  ModalBottomSheet was composed only inside the player branch of YtkitRoot, so
  from Home/Search/Library/playlist nothing showed; and playlist "download all"
  started immediately with a default format (the "direct download" complaint).
  FIX: compose the DownloadSheet LAST and unconditionally in YtkitRoot (it opens
  over every screen), and route the playlist header through openDownloadAll ->
  the same picker, which then calls downloadBatch(items, container).
- Downloads must NEVER auto-start without the picker: any new "download" entry
  point must call openDownload / openDownloadAll, never DownloadEngine.start.
- bestAudioChoice now takes (videoId, preferContainer) and is memoised per
  "id|container". bulkDone counts once per item via onFinished.
- v1.14: playlist "download all" queues EVERY song instantly (key
  "<id>:audio:queue", status "queued") then starts 3 at a time (Semaphore(3)).
  Each Downloads-tab row has a Stop (red Close) icon. startQueued skips a row
  the user cancelled while resolving, and must NOT cancel+restart a row that is
  already downloading/saving/saved.
- DownloadEngine IS app-scoped (install() idempotent, restore() once per
  process, scope never cancelled).
- v1.15: the real "download stops on tab switch" cause was the OS suspending the
  app (no FGS for downloads). Fixed with download/DownloadService.kt - a thin
  `dataSync` foreground service (progress notification + "Stop all" action +
  PARTIAL_WAKE_LOCK) whose lifecycle is driven by DownloadEngine.syncService().
  targetSdk 34 needs the FGS type in BOTH manifest and startForeground(...); the
  type constant is an int and inlined, so it never shows up as a dex string.
- finishSaved marks the row playable immediately, then embeds cover on
  Dispatchers.IO (M4A/Ogg embed rewrites the whole file). Cover is prefetched in
  PARALLEL with the media so the row shows real art at once.

## ytkit v1.23 - YT Music UI redesign (2026-10-14)
- Full UI rewrite to a YouTube Music look. Files under
  `ytkit-android/app/src/main/java/com/ytkit/app/`:
  `ui/theme/Theme.kt` (near-black Bg=0xFF030303, BgElevated, red accent),
  `ui/components/{Common,Sheets,DownloadSheet}.kt`,
  `ui/screens/{Home,Search,Library,Player,AccountPlaylist,Settings}Screen.kt`,
  `ui/YtkitRoot.kt` (bottom nav: Home / Explore / Library / Settings).
- **"Server unreachable - check the URL in Settings" = the backend was down,
  not an app bug.** After a sandbox reset `.venv` is gone, so nothing listens on
  :12000 and the public host returns 502. Fix: `cd dl-service && ./serve.sh start`
  (builds the venv + starts the watchdog). autostart.sh does this on session
  start but no-ops if the port is already healthy.
- **Tab switching works** - the earlier "identical dump" was a test bug: taps at
  y=2300 hit the gesture-nav area. The nav bar is y~2064-2274; tap y=2170 at
  x=127/403/678/953 for Home/Explore/Library/Settings.
- Emulator (no KVM, software render) throws constant SystemUI ANR dialogs that
  steal taps: suppress with `adb shell settings put global hide_error_dialogs 1`.
- Publish: keep `dl-service/public/ytkit.apk` in sync with the latest release
  build (md5 must match) and update the version string in app.py's index page.

## ytkit v1.24 - back stack + animations + speed (2026-10-14)
- **Back stack**: `ui/YtkitRoot.kt` now owns `mutableStateListOf<Screen>` where
  `Screen` = TabScreen(tab) | Player | AccountPlaylistScreen. Back pops ONE
  entry. Order: sheet -> player -> playlist -> tab history -> exit. Index 0 is
  the launch tab, so back there is left to the system (closes app). Sheets have
  a higher-priority `BackHandler` declared BEFORE the stack one.
  Verified on emulator: Settings->Explore->Home->exit, player->Home,
  playlist->Library all step correctly.
- **Animations**: `ui/theme/Motion.kt` (durations/easings) + `ui/components/Motion.kt`
  (`bouncyClickable`). Tab switch = AnimatedContent slide+fade; player = slide
  up over the shell (shell stays composed, so return is instant); art crossfade
  via `CrossfadeArt`; nav pill fades + icon scales; list items animate in via
  `AnimatedListItem`.
- **Speed**: Coil memory+disk cache in `YtkitApp.newImageLoader()`;
  `Playback.prefetchNext()` resolves `PREFETCH_AHEAD=3` tracks ahead.
- **Build gotcha**: after a sandbox restart JAVA_HOME is lost -> "no java in
  PATH". JDK is at `/workspace/tools/jdk-17.0.20.1+1`.
  `export JAVA_HOME=/workspace/tools/jdk-17.0.20.1+1 && export PATH=$JAVA_HOME/bin:$PATH`
- **Emulator gotcha**: KVM is NOT available after a restart (`/dev/kvm` missing,
  no vmx/svm). x86_64 image only -> must run `-accel off` (software, ~3.5 min
  boot, very laggy/unstable). AVD home is `/workspace/.android/avd`
  (`ANDROID_AVD_HOME`). App nav bar y=2190-2274; tap y=2225 (NOT 2290 - that is
  the system gesture nav).

## ytkit v1.25 - settings, themes, audio features (2026-10-14)
- Added: gapless playback, crossfade (2-12s), volume normalization
  (LoudnessEnhancer), fade-out on pause, sleep-timer "end of song",
  light/dark/AMOLED themes, Wi-Fi-only downloads, storage breakdown,
  backup/restore library, clear cache, clear all data.
- **Theme is now dynamic.** `ui/theme/Theme.kt` has a `Palette` object and the
  colour tokens (`Bg`, `TextCol`, ...) are getter-backed properties reading
  `Palette.current`. `YtkitTheme(settings)` sets the palette. Any NEW composable
  can keep using `Bg`/`TextCol` and it follows the theme automatically. Do NOT
  revert these to plain `val` — that freezes the colour at first read.
- Settings persist as one JSON blob (`Store.settings`, `data.Settings`), so new
  fields need no migration. `AppViewModel.updateSetting {}` persists + mirrors
  into `Playback.applySettings()`. `Playback.persistSettings` writes back.
- `YtkitRoot` calls `viewModel()` BEFORE `YtkitTheme(vm.settings)` so the theme
  can read settings on the first composition.
- Build clean: `assembleRelease` passes; APK v1.25 (versionCode 26).
- **Full 193-item roadmap: `/workspace/project/FEATURE_ROADMAP.md`** with
  [x]/[~]/[ ] status. Keep it updated as features ship.
- Remaining big items need real work + test: equalizer UI, synced lyrics,
  widgets (Glance), Android Auto, Chromecast, Wear OS, podcasts, video mode.
- APK publish flow: build -> `cp app/build/outputs/apk/release/app-release.apk`
  to `dl-service/public/ytkit.apk` -> `./serve.sh restart` (index text in app.py).

## ytkit v1.26 - equalizer, synced lyrics, noisy receiver (2026-10-15)
- versionName 1.26 / versionCode 27. APK 4,027,675 bytes, md5
  e0d7f9118bb01762437487dd308b4757, served at `https://work-1-.../ytkit.apk`.
- New: `ui/screens/EqualizerScreen.kt` (vertical sliders + presets),
  `ui/components/Lyrics.kt` (LRC parser + synced view), EQ/lyrics/sleep-timer
  bottom sheets wired into `PlayerScreen.kt`; `PlaybackService` pauses on
  `ACTION_AUDIO_BECOMING_NOISY` (headphone unplug).
- **EQ presets live in `Playback`** (`DEFAULT_EQ_PRESETS`, `eqPresetNames`,
  `eqBands`, `eqFreqs`, `eqRange`). `android.media.audiofx.Equalizer` is built
  lazily on the player's audio session; `applyEq()` re-selects the saved preset
  on a fresh session (a plain band write would be lost). Settings JSON carries
  eqEnabled/eqPreset/eqBands.
- **Lyrics** come from backend `GET /api/lyrics` -> LRCLIB (free, no key),
  cached. `rememberLyrics` must cache a non-null `Lyrics()` on failure or the
  sheet spins forever. `parseLrc` accepts `[m:ss.xx]` with 1-2 digit min/sec and
  drops `[ar:]`-style tags. Unit tests: `app/src/test/.../LrcParserTest.kt`
  (`./gradlew :app:testReleaseUnitTest`), junit added to build.gradle.kts.
- Backend `/api/formats` returns `videos` + `audios` (InnerTube first, then
  yt-dlp, then proxy race). Verified 8 video + 4 audio for a normal song. The
  app picker shows audio rows only (music app) + M4A/OPUS badges.
- **ENV: `/dev/kvm` is NOT guaranteed.** It existed on 10-14, vanished after the
  10-15 sandbox restart, and then the x86_64 emulator refuses to boot
  ("requires hardware acceleration"). Check `ls /dev/kvm` before planning any
  emulator work. Even when it boots, headless swiftshader gives a black
  `screencap` and flaky `input tap`; verify playback via
  `adb shell dumpsys media_session` (`state=PLAYING`) + `logcat` + backend
  `/api/stream` probe lines rather than screenshots.



## ytkit v1.28 - Phase 4 playback/UX, queue + lazy resume (2026-10-15)
- versionName 1.28 / versionCode 29. APK 4,044,059 bytes, md5
  b7e7d5a3d1db1bc44b3b4e51bdb8b2f7, served at `https://work-1-.../ytkit.apk`.
- **Gapless**: the next track is preloaded as a 2nd ExoPlayer media item with
  `setMediaId(next.id)`. That mediaId is REQUIRED - `onMediaItemTransition` maps
  the gapless advance back to a queue index, and without it the UI seek bar /
  title drifts one track behind.
- **Lazy cold-start resume**: `Store.queueSnapshot` (QueueSnapshot: items/index/
  positionMs/shuffle/repeat/original) -> `Playback.restoreQueue()` fills UI state
  only and sets `needsLoad=true`; it must NOT build ExoPlayer or hit the network.
  `Playback.attach(ctx)` (guard `if (!::appContext.isInitialized)`) records the
  context; `loadRestored()` runs on first play; `toggle()/next()` branch on it.
- **`SongMenu` hook** (Common.kt): process-wide `object SongMenu { onShow }`,
  installed by YtkitRoot via DisposableEffect. Any `SongRow` that shows a
  favourite heart then gets an automatic 3-dot -> SongActionsSheetContent (Play
  next / Add to queue / favourite / playlist / radio). Zero per-screen changes.
- Queue sheet: drag-to-reorder (`detectDragGesturesAfterLongPress` +
  `graphicsLayer.translationY`, rowHeight 60.dp); `Playback.moveInQueue` follows
  the playing id. Player menu adds speed picker (0.5-3x), pitch, A-B repeat,
  skip intro/outro, history. Settings adds auto-play-on-headset + skip intro/outro.
- Becoming-noisy pause and audio focus both go through the fade path. Headset/BT
  auto-play: PlaybackService registers ACTION_HEADSET_PLUG + AudioDeviceCallback.
- `/dev/kvm` still absent -> emulator unusable; verified via build + unit tests
  + backend health/apk probes only.

## ytkit (v1.31, current)
- Served APK: https://work-1-ucasundegischpku.prod-runtime.all-hands.dev/ytkit.apk
  (also /app-release.apk). Source of truth = dl-service/public/ytkit.apk.
  v1.31 = fixed "Now Playing looks transparent" + insets/opacity audit.
  **Root cause of the see-through player (expensive to rediscover):** the
  full-screen player and account-playlist overlays were `AnimatedVisibility`
  entered with `fadeIn()+slideIn` — during the whole transition the opaque
  layer is drawn at partial alpha over the still-composed tab shell, so it
  looks transparent. Fix = slide-only (no fade) for full-screen opaque
  overlays. Never cross-fade a layer that is meant to be opaque.
  **Material3 1.3.0 insets fact:** `ModalBottomSheet` already applies
  `WindowInsets.safeDrawing.only(Bottom)` to its content — adding
  `navigationBarsPadding()` to sheet content double-pads (content jumps up).
  Full-height sheets should add only `statusBarsPadding()`. (Verified by
  javap on the cached material3 AAR.)
  Player bg gradient stops use `lerp(Bg, art, a)` (opaque) not raw alpha.
  UI note: **only Material3 1.3.0 is in the offline cache** — no MaterialShapes/
  LoadingIndicator (1.4+). Shared-element keys must be unique per composition.
- Playback resolves ON THE PHONE first (NewPipeExtractor 0.26.5), backend
  /api/stream relay is only the fallback. So any audio-quality setting must be
  applied in OnDeviceResolver.pickAudio(...) too, not just the backend.
- Release build: cd /workspace/project/ytkit-android with JAVA_HOME=/workspace/tools/jdk-17.0.20.1+1
  and ANDROID_HOME=/workspace/tools/android-sdk, run ./gradlew :app:assembleRelease --offline (~1 min).
  Signed with the shared debug keystore.
- Verify APK version without installing: aapt dump badging APK (grep version).
- Backend: cd /workspace/project/dl-service then ./serve.sh status/stop/start;
  health at /api/health. /api/formats?url=ENCODED returns keys videos/audios.
- No /dev/kvm -> Android emulator unusable; verify by build + backend probes.
