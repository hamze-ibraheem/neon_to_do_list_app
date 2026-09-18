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

# Standalone To-Do List App Release Walkthrough

## Summary of Changes

### 1. Root Cause Analysis
- **Why the framework itself was running**: The server hosted at `https://custom-frameworks-neon-framework.iix8qf.easypanel.host/` was serving `my_2nd_test_app` (`ShowcaseApp()`, the Neon framework demo app with button showcases, layout tests, etc.) instead of the `TodoApp()` from `neon_to_do_list_app`.
- **Localhost Dependency**: Previously, the mobile shell relied on `http://localhost:8080` or the remote URL via `fetchUiTree()` and `sendAction()`.

### 2. Standalone Offline SDUI Engine in Kotlin
We implemented a local Server-Driven UI (SDUI) state and layout engine directly inside [MainActivity.kt](file:///Volumes/SSDM22TB/Task%20Foundation%20Apps/custom%20frameworks/neon_to_do_list_app/android/app/src/main/kotlin/com/neon/myapp/MainActivity.kt):
- **100% Offline / No Localhost**: `USE_REMOTE_SERVER = false` by default. The app boots immediately into the To-Do List App without network requests, `localhost`, or `127.0.0.1`.
- **Local State Management**: Complete task management with `TodoItemData`, priority chips (Low, Medium, High), category chips (Work, Personal, Urgent, Ideas), filter status tabs (All, Active, Done), and category filters.
- **Persistence**: Tasks and changes are automatically saved to Android `SharedPreferences` (`neon_todo_prefs`), persisting across app launches.
- **Dynamic SDUI Tree Generator**: Generates the exact widget JSON tree (matching `todo_screen.dart`):
  - Gradient header with live task counter (`X / Y completed`)
  - Animated progress bar showing percentage completion
  - Category selector chips with active tinting
  - Task input box with priority selector
  - Interactive task cards with checkbox toggle and trash can delete
  - Batch action buttons ("Check All" / "Reset", "Clear Done")
  - Empty state illustration when zero tasks match the filter
- **Fixed TextField Rendering**: Fixed a bug where `type.contains("Text")` was intercepting `TextField` widgets and rendering them as static `TextView`s. Added keyboard Enter action listener and `TextWatcher` to allow typing and creating new tasks seamlessly.

---

## Verification & Screenshots

The release APK was built and deployed to a live Android device/emulator (`emulator-5554`) and thoroughly tested.

### 1. Initial Load & Standalone UI
The app loads the To-Do list interface with persistent default tasks, stats, and filters:
![To-Do List Live on Device](/Users/hamzaalsarsour/.gemini/antigravity-ide/brain/ea903b3c-3ff6-46c3-b23e-ce6c0e4ba3fd/todo_app_live.png)

### 2. Batch Operations: "Check All"
Tapping "Check All" marks all tasks complete, updates the progress bar to 100% (4/4), and turns the button into "Reset":
![Check All Completed](/Users/hamzaalsarsour/.gemini/antigravity-ide/brain/ea903b3c-3ff6-46c3-b23e-ce6c0e4ba3fd/todo_app_check_all.png)

### 3. Clear Completed & Empty State
Tapping "Clear Done" removes completed tasks, displaying the celebration empty state:
![Empty State](/Users/hamzaalsarsour/.gemini/antigravity-ide/brain/ea903b3c-3ff6-46c3-b23e-ce6c0e4ba3fd/todo_app_cleared.png)

### 4. Adding New Tasks
Typing in the task field and pressing Enter or the Add button creates the new task with the selected category and priority:
![Adding New Task](/Users/hamzaalsarsour/.gemini/antigravity-ide/brain/ea903b3c-3ff6-46c3-b23e-ce6c0e4ba3fd/todo_app_with_new_task.png)

---

## Exported Release APK Details

The release APK has been built and placed in the project's `export` folder for installation:

- **Path**: [export/neon_todo_app-release.apk](file:///Volumes/SSDM22TB/Task%20Foundation%20Apps/custom%20frameworks/neon_to_do_list_app/export/neon_todo_app-release.apk)
- **Size**: ~630 KB
- **Network Requirements**: None (zero localhost links, works 100% offline)




Step-by-Step Apple Developer Account & TestFlight Setup
Because Xcode Cloud handles all certificates, provisioning profiles, and signing identities directly via your Apple Developer Account, follow these 3 quick steps:

Step 1: Register App ID in Apple Developer Portal
Navigate to Apple Developer Identifiers.
Click + (Add Identifier) -> Select App IDs -> Click Continue -> Select App.
Description: Neon To-Do List
Bundle ID: Select Explicit and enter com.neon.todolist.
Click Continue -> Register.
Step 2: Create App in App Store Connect
Go to App Store Connect Apps.
Click + -> New App.
Platforms: Check iOS.
Name: Neon Task Studio (or your preferred App Store name).
Primary Language: English.
Bundle ID: Select com.neon.todolist from the dropdown list.
SKU: NEON-TODO-001.
Click Create.
Step 3: Configure Xcode Cloud Workflow for TestFlight
In App Store Connect, open your newly created app and click the Xcode Cloud tab (or in Xcode on your Mac, open ios/NeonApp.xcodeproj and choose Product > Xcode Cloud > Create Workflow).
Select your repository: hamze-ibraheem/neon_to_do_list_app.
Configure the workflow:
Branch: main
Action: Archive - iOS
Scheme: NeonApp
Post-Action: TestFlight (Internal Testing) -> Select your tester group (e.g., App Store Connect Users).
Save the workflow and click Start Build (or simply push any commit to main).
Xcode Cloud will clone the repo, run ci_scripts/ci_pre_xcodebuild.sh, compile and sign the IPA in Apple's cloud, and automatically deliver the build to TestFlight!