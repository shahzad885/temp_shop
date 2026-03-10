<div align="center">

# 📸 TempShot

**Give every screenshot an expiry date. Auto-delete when time's up.**

[![Flutter](https://img.shields.io/badge/Flutter-3.42-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android)](https://android.com)


</div>

---

TempShot watches your screenshot folder and shows a **floating overlay** the moment a new screenshot is taken — set a timer, and the file deletes itself automatically, even when the app is closed. No servers. Everything is local.

## Demo

<img width="654" height="473" alt="image" src="https://github.com/user-attachments/assets/c656c9a8-cc2e-479b-97dd-b7245d16d32c" />



## Features

- **Floating time-picker** — appears over any app when a screenshot is detected
- **Background auto-delete** — files deleted from storage when timer expires, app closed or not
- **The Vault** — long-press any screenshot to keep it forever
- **Netflix-style UI** — hero banner, horizontal category lanes, ripple-animated stats
- **100% on-device** — Hive database, zero network requests

## Stack

| | |
|---|---|
| State | Riverpod `StateNotifier` (no code generation) |
| Database | Hive with manual `TypeAdapter` (no build_runner) |
| Background | `flutter_background_service` in separate Dart isolate |
| Overlay | Native Android `WindowManager` via Platform Channel |

## Getting Started

```bash
git clone https://github.com/yourusername/tempshot.git
cd tempshot
flutter pub get
flutter run
```

**Requires `minSdk = 26`** (Android 8.0+). On first launch, grant storage, notification, and *Draw over other apps* permissions.

> ⚠️ **Draw over other apps** must be enabled manually:
> `Settings → Apps → TempShot → Display over other apps → ON`

## Key Gradle Config

```kotlin
// android/app/build.gradle.kts
compileOptions { isCoreLibraryDesugaringEnabled = true }
defaultConfig { minSdk = 26 }
dependencies { coreLibraryDesugaring("com.android.tools.desugar_jdk_libs:1.2.3") }
```

```properties
# gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.13-bin.zip
```

---

<div align="center"><sub>MIT © 2026 — No data ever leaves your device</sub></div>
