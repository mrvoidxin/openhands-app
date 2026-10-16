# Signing

The app is signed with one key, and that key must never change. Android treats
two APKs signed with different keys as two different apps: an update signed with
a new key is refused, and the user has to uninstall first, losing their settings.
Pinning the key is what makes "download and update" work forever.

## The pinned certificate

Every published build is signed with this certificate. Verify any APK against it:

```
subject : CN=OpenHands Mobile, OU=Agent Canvas, O=OpenHands, C=IN
issuer  : CN=OpenHands Mobile, OU=Agent Canvas, O=OpenHands, C=IN
SHA-256 : 0D:96:FA:45:8C:34:42:D2:28:AC:C8:56:97:04:10:4A:4E:83:44:3A:68:0E:DF:81:C6:AE:0D:D1:6D:DA:81:12
SHA-1   : 6D:61:FF:F0:EB:20:4D:08:A4:38:3C:B3:A4:FE:2B:20:89:52:12:6E
```

This is a self-signed certificate. It is **not** a Play Store upload key and it
is not trusted by a certificate authority, which is expected for an app that is
installed by sideloading.

The fingerprint is public — it is inside every copy of the APK — so it is safe
to keep in this repository. The **private key** is not, and must never be
committed.

```bash
# on any published APK
apksigner verify --print-certs app-release.apk | grep SHA-256
keytool -printcert -jarfile app-release.apk | grep SHA256
```

## How it is enforced

The release workflow pins the fingerprint in
[`.github/workflows/build-android-apk.yml`](.github/workflows/build-android-apk.yml).
After building, it reads the signer from the APK and compares:

- match → the fingerprint is printed and the release is published;
- mismatch → `::error::SIGNING KEY CHANGED`, exit 1, **nothing is published**.

Because the release job is gated on this check, a rotated or unexpected key
cannot reach users by accident. It also fails closed: if the fingerprint cannot
be read from the APK at all, the build stops rather than publishing something
unverified.

To rotate on purpose, set the `SIGNING_CERT_SHA256` repository variable
(Settings → Secrets and variables → Actions → Variables) to the new fingerprint.
The variable overrides the value in the workflow, so a deliberate rotation needs
no code change — only this document and a clear warning to users. Setting that
variable is the only correct way to rotate; editing the workflow to skip the
check defeats the guarantee.

## Where the key lives

The keystore is **not** in this repository. It exists in exactly two places:

1. the `ANDROID_KEYSTORE_BASE64` GitHub Actions secret, which CI decodes at
   build time;
2. a backup that you keep outside the repository.

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 release.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | store password |
| `ANDROID_KEY_PASSWORD` | key password |
| `ANDROID_KEY_ALIAS` | alias, e.g. `openhands` |

Keep the backup outside this repository and never serve it from a web directory.
A safe bundle holds the keystore, its public certificate (`release-cert.pem`),
the alias and passwords, and a checksum of the keystore. Store it in a password
manager, an encrypted archive, or offline media.

## If the key is lost

A lost key cannot be recovered, and this is the one scenario the pin cannot
protect against. There is no way to sign an update that installs over an
existing copy, so:

1. generate a new keystore and update the secrets;
2. update the fingerprint here and in `SIGNING_CERT_SHA256`;
3. bump `versionName` and `versionCode`;
4. tell users in the release notes that this update needs a one-time uninstall.

Losing the key is the only reason a user should ever have to uninstall. Any
other forced uninstall is a bug in the release process.

## History

- **v1.27.2** and later use the certificate above. This is the key that future
  updates will keep using, so users on v1.27.2 or newer update in place.
- **v1.27.1** and earlier were signed with an earlier key. Upgrading from those
  builds to v1.27.2 needed a one-time uninstall. That break is already behind
  us and does not repeat.

## Local builds

A local build reads the same names from the environment:

```bash
export OPENHANDS_KEYSTORE_PASSWORD=...
export OPENHANDS_KEY_PASSWORD=...
export OPENHANDS_KEY_ALIAS=openhands
# drop the keystore at OpenHands-main/android/app/release.keystore
```

`OpenHands-main/android/app/build.gradle` signs only when the keystore file is
present, and logs a warning otherwise. A local unsigned build is fine for
testing, but it cannot be published and cannot update an installed copy.

`.gitignore` already excludes `*.keystore` and `*.jks`.
