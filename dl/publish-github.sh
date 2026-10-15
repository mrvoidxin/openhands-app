#!/usr/bin/env bash
# Publish the APKs as a GitHub Release on mrvoidxin/opanhand-mobile-.
#
# GitHub Release asset URLs are permanent and public, so this is the durable
# "never goes down" host. It needs a token WITH WRITE ACCESS: the default
# GITHUB_TOKEN in this sandbox is a read-only GitHub App token (`ghu_...`) and
# every write returns 403 "Resource not accessible by integration".
#
# Usage:
#   GH_PAT=<token-with-repo-scope> bash publish-github.sh
#   # or: GITHUB_TOKEN=<writable-token> bash publish-github.sh
set -u

REPO="mrvoidxin/opanhand-mobile-"
TAG="v1.27.1"
TITLE="OpenHands Mobile v1.27.1 (Android APK)"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOKEN="${GH_PAT:-${GITHUB_TOKEN:-}}"
if [ -z "$TOKEN" ]; then
  echo "ERROR: no token. Set GH_PAT (a token with 'repo' scope)." >&2
  exit 1
fi

api() { curl -sS -m 120 -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/vnd.github+json" "$@"; }

echo "==> checking token write access on $REPO"
LOGIN=$(api https://api.github.com/user | python3 -c "import json,sys;print(json.load(sys.stdin).get('login','?'))")
echo "    token user: $LOGIN"

# A cheap write probe: create then delete a branch. 403 means read-only.
SHA=$(curl -sS -m 60 -H "Authorization: Bearer $TOKEN" \
      "https://api.github.com/repos/$REPO/commits/main" \
      | python3 -c "import json,sys;print(json.load(sys.stdin)['sha'])")
PROBE=$(api -X POST "https://api.github.com/repos/$REPO/git/refs" \
        -d "{\"ref\":\"refs/heads/openhands-apk-probe\",\"sha\":\"$SHA\"}")
if echo "$PROBE" | grep -q "Resource not accessible"; then
  cat >&2 <<'MSG'
ERROR: this token cannot write to the repository (403 read-only).

The sandbox's default GITHUB_TOKEN is a read-only GitHub App token. To publish
you need one of:
  a) A personal access token with the 'repo' scope (classic) or
     'Contents: Read and write' (fine-grained), then:
        GH_PAT=<that token> bash publish-github.sh
  b) Grant the OpenHands GitHub App 'Read and write' access to this repository
     (GitHub -> Settings -> Applications -> Installed GitHub Apps -> OpenHands
     -> Configure -> Repository access + Permissions), then re-run this script
     with the refreshed GITHUB_TOKEN.
MSG
  exit 2
fi
api -X DELETE "https://api.github.com/repos/$REPO/git/refs/heads/openhands-apk-probe" > /dev/null
echo "    write access OK"

echo "==> creating release $TAG"
EXISTING=$(api "https://api.github.com/repos/$REPO/releases/tags/$TAG")
if echo "$EXISTING" | grep -q '"id"'; then
  echo "    release $TAG already exists, reusing it"
else
  api -X POST "https://api.github.com/repos/$REPO/releases" \
    -d "$(python3 -c '
import json
print(json.dumps({
  "tag_name": "v1.27.1",
  "name": "OpenHands Mobile v1.27.1 (Android APK)",
  "body": (
    "Android build of the OpenHands Agent Canvas UI "
    "(`@openhands/agent-canvas` v1.27.1), packaged with Capacitor 7.\n\n"
    "**Install**\n"
    "1. Allow install from unknown sources for your browser / file manager.\n"
    "2. Open the APK on the phone and install it.\n"
    "3. On first launch, add your agent server host and API key.\n\n"
    "**Details**\n"
    "- Package `dev.openhands.agentcanvas`, versionName 1.27.1 / versionCode 10271\n"
    "- minSdk 23, targetSdk 35, signed with APK Signature Scheme v1 + v2\n\n"
    "This release was produced by an AI agent (OpenHands) on behalf of the "
    "repository owner."
  ),
}))')" > /dev/null
  echo "    created"
fi

echo "==> uploading assets"
for pair in "openhands.apk:app-release.apk" "openhands-debug.apk:app-debug.apk"; do
  src="${pair%%:*}"; name="${pair##*:}"
  echo "    $name <- $src"
  api -X POST \
    -H "Content-Type: application/vnd.android.package-archive" \
    --data-binary "@$DIR/$src" \
    "https://uploads.github.com/repos/$REPO/releases/$(api "https://api.github.com/repos/$REPO/releases/tags/$TAG" | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')/assets?name=$name" \
    > /dev/null
done

echo
echo "Permanent download links:"
echo "  https://github.com/$REPO/releases/latest"
echo "  https://github.com/$REPO/releases/download/$TAG/app-release.apk"
echo "  https://github.com/$REPO/releases/download/$TAG/app-debug.apk"
