# Study Voice AI 🎙️
> **Transforming Study PDFs into Smart Audio Learning**

Study Voice AI is a modern, premium, educational Android application built with Flutter and Firebase. It allows students to upload their heavy textbook PDFs and instantly convert them into natural AI-generated audio streams for smart, mobile learning.

---

## 🌟 Key Features

* **High-Fidelity Material 3 UI/UX**: Frosted glassmorphic cards, harmonized linear gradients (Violet-to-Magenta and Indigo-to-Cyan), smooth entry scale animations, and complete Light/Dark theme toggling.
* **Dual-Mode Sync Engine**: 
  - **Firebase Mode**: Real-time authentication via Firebase Auth + Google Sign-In, syncs document text, statistics, bookmarks, and notes to Cloud Firestore and uploads binaries to Firebase Storage.
  - **Local Sync Fallback**: Runs **100% operational out of the box**! If Firebase is not initialized, a robust JSON database adapter catches the exceptions and caches all textbook texts, streaks, and bookmarks to device local preferences (`SharedPreferences`).
* **Memory-Safe PDF Parsing**: Iteratively extracts text page-by-page from raw PDF byte streams using `syncfusion_flutter_pdf` to avoid mobile heap memory crashes, even on 500-page books.
* **Word-by-Word Active Highlights**: Listens to native text-to-speech character boundaries from `flutter_tts` to visually paint a glowing overlay on the word actively being read, boosting retention.
* **Voice Customization Panel**: Allows students to alter speech pitch, adjust speeds (0.5x to 2x), change accents (US English, Indian English, UK English, Hindi, Tamil, Telugu), and select voice models.
* **Dynamic AI Study Assistant**: Implements a client-side NLP processor that:
  - Generates key executive summary bulletins.
  - Detects textbook domain subjects (Science, Technology, History, Literature, Business) automatically.
  - Extracts key study concept keywords.
  - **Generates playable MCQ quizzes** dynamically from *any* PDF text, presenting correct flags and detailed academic rationales!
* **Bookmarks & Study Tracker**: Saves audio bookmarks, logs written page notes, tracks study streaks, increments active minutes, and plots vertical analytics graphs.

---

## 📁 Project Directory Structure

```
lib/
├── main.dart                      # App entry, configures MultiProvider & routes
├── core/
│   ├── theme/
│   │   ├── app_theme.dart         # Material 3 typography & gradient themes
│   │   └── text_styles.dart       # Styles using Google Fonts Outfit
│   ├── constants/
│   │   └── app_constants.dart     # String and route assets
│   ├── utils/
│   │   └── pdf_helper.dart        # Page-by-page Syncfusion text extraction
│   └── widgets/
│       ├── custom_button.dart     # Multi-state glowing gradient button
│       ├── custom_textfield.dart  # Focus-glowing validation field
│       └── glass_card.dart        # Semi-transparent backdrop blurred container
├── models/
│   ├── user_model.dart            # Tracks uid, display name, streaks, hours
│   ├── pdf_model.dart             # PDF text, file size, pages, subject tags
│   ├── note_model.dart            # Custom student page notes
│   └── bookmark_model.dart        # Precise audio bookmarks
├── services/
│   ├── auth_service.dart          # Firebase Auth with local credentials fallback
│   ├── database_service.dart      # Firestore CRUD + local SharedPreferences adapter
│   ├── storage_service.dart       # Firebase Storage file binary uploads
│   ├── tts_service.dart           # Speaks text and exposes character progress streams
│   ├── ai_service.dart            # Client-side NLP (summaries, tags, dynamic quizzes)
│   └── notification_service.dart  # Handles reminder states and banners
├── viewmodels/
│   ├── auth_viewmodel.dart        # Controls login state and validations
│   ├── library_viewmodel.dart     # Manages PDF pickers, uploads, and search lists
│   ├── player_viewmodel.dart      # TTS playback controls, speeds, notes, bookmarks
│   └── stats_viewmodel.dart       # Logs streaks, increments listening minutes
└── views/
    ├── auth/
    │   ├── splash_screen.dart     # Scaling logo intro and session checker
    │   ├── login_screen.dart      # Form validator and Google access buttons
    │   ├── signup_screen.dart     # Registration fields
    │   └── forgot_pw_screen.dart  # Recover credentials linkage
    ├── dashboard/
    │   ├── main_layout.dart       # Nav orchestrator with custom glass bottom bar
    │   ├── home_tab.dart          # Welcoming stats, categories, and resume plays
    │   ├── library_tab.dart       # Sortable search lists and delete confirmers
    │   ├── bookmarks_tab.dart     # Segmented tabs for bookmarks and notes
    │   └── profile_tab.dart       # Custom vertical study bar charts & badges
    ├── player/
    │   └── tts_player_screen.dart # Interactive playback panel and voice customized sheets
    ├── quiz/
    │   └── quiz_screen.dart       # MCQs visual cards, correct flags, and rationales
    └── settings/
        └── settings_screen.dart   # Light/dark toggles and privacy drawers
```

---

## 🚀 Setup & Firebase Cloud Activation

Out of the box, the app runs perfectly in **High-Fidelity Offline Mode**. If you wish to activate full Firebase cloud syncing:

### 1. Register App on Firebase Console
1. Visit [Firebase Console](https://console.firebase.google.com/) and create a new project called **Study Voice AI**.
2. Click **Add Android App** and register with package name: `com.studyvoiceai.study_voice_ai`.
3. Download the generated `google-services.json` file.

### 2. Put Google Services File in Project
Drag-and-drop the downloaded `google-services.json` file into this directory:
```
android/app/google-services.json
```

### 3. Add Firebase Gradle Plugins
The project is already pre-configured to handle plugins dynamically. Simply add the Google Services classpath inside:
* **`android/build.gradle`**:
  ```gradle
  plugins {
      id("com.android.application") version "8.1.0" apply false
      id("com.google.gms.google-services") version "4.3.15" apply false
  }
  ```
* **`android/app/build.gradle.kts`**:
  ```kotlin
  plugins {
      id("com.android.application")
      id("kotlin-android")
      id("com.google.gms.google-services") // Activate Google Services
      id("dev.flutter.flutter-gradle-plugin")
  }
  ```

### 4. Turn on Services in Firebase Console
* **Authentication**: Go to *Build > Authentication > Sign-in Method*. Enable **Email/Password** and **Google**.
* **Firestore Database**: Click *Create Database* in test mode.
* **Storage**: Enable Storage bucket for user file uploads.

---

## 📦 Production Build & APK Generation

To compile the application into a compact, production-ready, release-signed APK:

### 1. Ensure Dependencies are Cached
Run the following in the project root:
```bash
flutter pub get
```

### 2. Execute Production Compile
Run the Gradle compilation pipeline:
```bash
flutter build apk --release
```

* **Output Location**: Upon completion, your optimized, production-ready installable APK file will be saved at:
  ```
  build/app/outputs/flutter-apk/app-release.apk
  ```

### 3. Split APK by ABI (Optional - Reducing Size)
If you want to compile lightweight separate APKs tailored specifically for target architectures (ARM 64-bit, x88, etc.) to minimize download footprints on Google Play:
```bash
flutter build apk --split-per-abi
```

---

## 🛠️ Requirements & Troubleshooting

* **Flutter SDK**: `^3.29.0`
* **Dart SDK**: `^3.7.0`
* **Android targetSdk**: `34`
* **Android minSdk**: `21`

### Background Audio Troubleshooting:
If background audio pauses when the screen locks on certain heavily-customized Android OS models (e.g. Xiaomi MIUI, Samsung OneUI):
1. The `uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"` is fully declared in the project's Manifest to request system exceptions.
2. Ensure you disable "Battery Saver Optimization" for **Study Voice AI** inside the system Settings of the target device to prevent background garbage collection.
