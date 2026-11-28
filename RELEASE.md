# Release Build

Android release builds are signed with the project's own release keystore.
The keystore and its password are **not** in this repository.

- Keystore: `../keystore/panipuri-release.keystore` (PKCS12, alias `panipuri`)
- Credentials: `../keystore/CREDENTIALS.txt` (keep private, back it up)

Godot reads the signing credentials from environment variables, so nothing
secret is stored in `export_presets.cfg`:

```powershell
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH     = "C:\Users\AKHILBOSS\OneDrive\Desktop\PaniPuri\keystore\panipuri-release.keystore"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER     = "panipuri"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = "<see CREDENTIALS.txt>"

$godot = "C:\Users\AKHILBOSS\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe"
& $godot --headless --path . --export-release "Android - PaniPuri" `
  "build/android/PaniPuriSimulator-release.apk"
```

## Verify the signature

```powershell
$env:JAVA_HOME = "C:\Users\AKHILBOSS\android\jdk17\jdk-17.0.21+9"
& "C:\Users\AKHILBOSS\android\sdk\build-tools\34.0.0\apksigner.bat" `
  verify --verbose --print-certs build/android/PaniPuriSimulator-release.apk
```

Expected: `Verifies`, v2 and v3 schemes true, one signer.

## App identity

| Field | Value |
| --- | --- |
| Package | `com.panipurisimulator.game` |
| Version | `1.6.0` (versionCode `9`) |
| Min SDK | 24 (Android 7.0) |
| Target SDK | 36 |
| ABI | `arm64-v8a` |
| Output | `build/android/PaniPuriSimulator-release.apk` |

# Play Store: build an Android App Bundle (.aab) instead of APK in a Gradle
# Android build configuration, keeping the same package/keystore settings.
# This repo ships a verified signed APK preset; AAB is a Play Store step.
# Kit: docs/play_store/ (listing, privacy, data safety, ratings, feature graphic)

Bump `version/code` and `version/name` in `export_presets.cfg` before every
store upload. The version code must always increase.

## Install

```powershell
adb install -r build/android/PaniPuriSimulator-release.apk
```

If a debug build of the same package is already installed, uninstall it first
(debug and release signatures differ):

```powershell
adb uninstall com.panipurisimulator.game
```

## Play Store bundle (optional)

Set `gradle_build/use_gradle_build=true` and
`gradle_build/export_format=1` (AAB) in the Android preset, then run the same
`--export-release` command. Gradle builds also let you set the target SDK
explicitly instead of inheriting the template's.
