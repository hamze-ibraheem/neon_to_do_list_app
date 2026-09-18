# Neon To-Do List App

A modern, responsive To-Do application built using the Neon Custom Mobile Framework with native Android Kotlin rendering.

## Features
- **Task Management**: Create, toggle completion, and filter tasks.
- **Categorization & Filtering**: Filter chips for All, Active, and Completed tasks.
- **Native Android UI**: Custom Kotlin-rendered views for high performance and smooth interaction.
- **Interactive Actions**: Action dispatch and reactive updates between Dart logic and native Android components.

## Backend & Host Endpoint
The app connects to the hosted Neon Framework backend:
- **Host**: `https://custom-frameworks-neon-framework.iix8qf.easypanel.host/`
- **Endpoints**: `/api/tree` (UI tree serialization) and `/action` (event dispatch)

## Tech Stack
- **Framework**: Neon Framework
- **Language**: Dart & Kotlin
- **Platform**: Android (Targeting Android 14 / API 34, Min API 21, Java 17)

## Building and Running

### Run on Connected Device / Emulator
```bash
neon run -t android
```

### Build APK
- **Debug APK**:
  ```bash
  cd android && ./gradlew assembleDebug
  ```
- **Release APK**:
  ```bash
  cd android && ./gradlew assembleRelease
  ```
