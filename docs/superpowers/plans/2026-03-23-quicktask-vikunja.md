# QuickTask for Vikunja Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Android share-target app that quickly adds tasks to a self-hosted Vikunja instance.

**Architecture:** Single-module Kotlin + Jetpack Compose app with two activities (MainActivity for setup/history, ShareActivity for share intent). Retrofit for API, EncryptedSharedPreferences for credentials, Jsoup for HTML title parsing.

**Tech Stack:** Kotlin, Jetpack Compose (Material 3), Retrofit + OkHttp, kotlinx.serialization, Hilt, Jsoup, EncryptedSharedPreferences

---

## File Structure

```
app/
├── build.gradle.kts
├── src/main/
│   ├── AndroidManifest.xml
│   ├── java/ch/freaxnx01/quicktask/vikunja/
│   │   ├── QuickTaskApp.kt                    # Hilt Application class
│   │   ├── di/
│   │   │   └── AppModule.kt                   # Hilt module (Retrofit, OkHttp, SharedPrefs)
│   │   ├── data/
│   │   │   ├── VikunjaApi.kt                   # Retrofit interface
│   │   │   ├── VikunjaRepository.kt            # Repository over API
│   │   │   ├── SecureStorage.kt                # EncryptedSharedPreferences wrapper
│   │   │   ├── TaskHistory.kt                  # Local task history (SharedPrefs)
│   │   │   ├── ProjectUsageTracker.kt          # Recent project tracking
│   │   │   └── TitleFetcher.kt                 # URL → page title via Jsoup
│   │   ├── model/
│   │   │   ├── Project.kt                      # Project data class
│   │   │   └── VikunjaTask.kt                  # Task data classes (request/response)
│   │   ├── ui/
│   │   │   ├── theme/
│   │   │   │   └── Theme.kt                    # Material 3 theme
│   │   │   ├── setup/
│   │   │   │   ├── SetupScreen.kt              # Setup UI
│   │   │   │   └── SetupViewModel.kt           # Setup logic
│   │   │   ├── history/
│   │   │   │   ├── RecentTasksScreen.kt        # Recent tasks UI
│   │   │   │   └── RecentTasksViewModel.kt     # Recent tasks logic
│   │   │   └── share/
│   │   │       ├── ProjectPickerScreen.kt      # Project picker UI
│   │   │       └── ShareViewModel.kt           # Share flow logic
│   │   ├── MainActivity.kt                     # Launcher activity
│   │   └── ShareActivity.kt                    # Share target activity
│   └── res/
│       ├── values/
│       │   ├── strings.xml
│       │   ├── colors.xml
│       │   └── themes.xml
│       └── mipmap-*/                           # Launcher icons
├── src/test/java/ch/freaxnx01/quicktask/vikunja/
│   ├── data/
│   │   ├── TitleFetcherTest.kt
│   │   ├── ProjectUsageTrackerTest.kt
│   │   └── TaskHistoryTest.kt
│   └── ui/share/
│       └── ShareViewModelTest.kt
build.gradle.kts                                # Project-level
settings.gradle.kts
gradle.properties
```

---

### Task 1: Project Scaffolding

**Files:**
- Create: `settings.gradle.kts`, `build.gradle.kts` (project), `app/build.gradle.kts`, `gradle.properties`
- Create: `app/src/main/AndroidManifest.xml`
- Create: `app/src/main/java/ch/freaxnx01/quicktask/vikunja/QuickTaskApp.kt`

- [ ] **Step 1: Create project-level Gradle files**

`settings.gradle.kts`:
```kotlin
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "QuickTask"
include(":app")
```

`build.gradle.kts` (project):
```kotlin
plugins {
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.0" apply false
    id("org.jetbrains.kotlin.plugin.serialization") version "2.1.0" apply false
    id("com.google.dagger.hilt.android") version "2.54" apply false
    id("com.google.devtools.ksp") version "2.1.0-1.0.29" apply false
}
```

`gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
```

- [ ] **Step 2: Create app-level build.gradle.kts**

`app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("com.google.dagger.hilt.android")
    id("com.google.devtools.ksp")
}

android {
    namespace = "ch.freaxnx01.quicktask.vikunja"
    compileSdk = 35

    defaultConfig {
        applicationId = "ch.freaxnx01.quicktask.vikunja"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    // Compose BOM
    val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
    implementation(composeBom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.54")
    ksp("com.google.dagger:hilt-android-compiler:2.54")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // Networking
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
    implementation("com.jakewharton.retrofit:retrofit2-kotlinx-serialization-converter:1.0.0")

    // HTML title parsing
    implementation("org.jsoup:jsoup:1.18.3")

    // Encrypted SharedPreferences
    implementation("androidx.security:security-crypto:1.1.0-alpha06")

    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.9.0")
    testImplementation("io.mockk:mockk:1.13.13")
}
```

- [ ] **Step 3: Create AndroidManifest.xml**

`app/src/main/AndroidManifest.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:name=".QuickTaskApp"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.QuickTask">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.QuickTask">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity
            android:name=".ShareActivity"
            android:exported="true"
            android:theme="@style/Theme.QuickTask">
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="text/plain" />
            </intent-filter>
        </activity>

    </application>
</manifest>
```

- [ ] **Step 4: Create Application class**

`QuickTaskApp.kt`:
```kotlin
package ch.freaxnx01.quicktask.vikunja

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class QuickTaskApp : Application()
```

- [ ] **Step 5: Create resource files**

`strings.xml`, `colors.xml`, `themes.xml` with app name and Material 3 theme.

- [ ] **Step 6: Add Gradle wrapper**

Run: `gradle wrapper --gradle-version 8.11.1`

- [ ] **Step 7: Verify project compiles**

Run: `./gradlew assembleDebug`

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat: scaffold Android project with Compose, Hilt, Retrofit deps"
```

---

### Task 2: Data Models & API Layer

**Files:**
- Create: `model/Project.kt`, `model/VikunjaTask.kt`
- Create: `data/VikunjaApi.kt`
- Create: `di/AppModule.kt`

- [ ] **Step 1: Create data models**

`model/Project.kt`:
```kotlin
package ch.freaxnx01.quicktask.vikunja.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Project(
    val id: Long,
    val title: String,
    @SerialName("is_archived") val isArchived: Boolean = false,
)
```

`model/VikunjaTask.kt`:
```kotlin
package ch.freaxnx01.quicktask.vikunja.model

import kotlinx.serialization.Serializable

@Serializable
data class CreateTaskRequest(val title: String)

@Serializable
data class TaskResponse(val id: Long, val title: String)
```

- [ ] **Step 2: Create Retrofit API interface**

`data/VikunjaApi.kt`:
```kotlin
package ch.freaxnx01.quicktask.vikunja.data

import ch.freaxnx01.quicktask.vikunja.model.CreateTaskRequest
import ch.freaxnx01.quicktask.vikunja.model.Project
import ch.freaxnx01.quicktask.vikunja.model.TaskResponse
import retrofit2.http.*

interface VikunjaApi {
    @GET("api/v1/projects")
    suspend fun getProjects(
        @Query("per_page") perPage: Int = 100,
        @Query("page") page: Int = 1,
    ): List<Project>

    @PUT("api/v1/projects/{id}/tasks")
    suspend fun createTask(
        @Path("id") projectId: Long,
        @Body task: CreateTaskRequest,
    ): TaskResponse
}
```

- [ ] **Step 3: Create Hilt AppModule**

`di/AppModule.kt` — provides OkHttp (with auth interceptor reading token from SecureStorage), Retrofit (with dynamic base URL from SecureStorage), and kotlinx.serialization converter.

- [ ] **Step 4: Verify it compiles**

Run: `./gradlew assembleDebug`

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add Vikunja API models and Retrofit interface"
```

---

### Task 3: SecureStorage & TitleFetcher

**Files:**
- Create: `data/SecureStorage.kt`, `data/TitleFetcher.kt`
- Test: `data/TitleFetcherTest.kt`

- [ ] **Step 1: Write TitleFetcher test**

`TitleFetcherTest.kt` — test URL detection regex, title extraction from HTML string (unit test Jsoup parsing with sample HTML, not network calls).

- [ ] **Step 2: Run test — verify it fails**

Run: `./gradlew test --tests '*TitleFetcherTest*'`

- [ ] **Step 3: Implement SecureStorage**

`data/SecureStorage.kt`:
```kotlin
package ch.freaxnx01.quicktask.vikunja.data

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SecureStorage @Inject constructor(@ApplicationContext context: Context) {
    private val prefs = EncryptedSharedPreferences.create(
        context,
        "quicktask_secure_prefs",
        MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )

    var instanceUrl: String?
        get() = prefs.getString("instance_url", null)
        set(value) = prefs.edit().putString("instance_url", normalizeUrl(value)).apply()

    var apiToken: String?
        get() = prefs.getString("api_token", null)
        set(value) = prefs.edit().putString("api_token", value).apply()

    val isConfigured: Boolean get() = !instanceUrl.isNullOrBlank() && !apiToken.isNullOrBlank()

    private fun normalizeUrl(url: String?): String? {
        if (url.isNullOrBlank()) return null
        val trimmed = url.trim().trimEnd('/')
        return if (trimmed.contains("://")) trimmed else "https://$trimmed"
    }
}
```

- [ ] **Step 4: Implement TitleFetcher**

`data/TitleFetcher.kt`:
```kotlin
package ch.freaxnx01.quicktask.vikunja.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jsoup.Jsoup
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TitleFetcher @Inject constructor() {
    companion object {
        private val URL_PATTERN = Regex("^https?://\\S+$", RegexOption.IGNORE_CASE)
        private const val TIMEOUT_MS = 5000
    }

    fun isUrl(text: String): Boolean = URL_PATTERN.matches(text.trim())

    suspend fun resolveTaskName(sharedText: String, extraSubject: String?): String {
        val text = sharedText.trim()
        if (!isUrl(text)) return text

        // Use EXTRA_SUBJECT if provided by the sharing app
        if (!extraSubject.isNullOrBlank()) {
            return "${extraSubject.trim()} - $text"
        }

        return withContext(Dispatchers.IO) {
            try {
                val title = Jsoup.connect(text)
                    .timeout(TIMEOUT_MS)
                    .get()
                    .title()
                if (title.isNullOrBlank()) text else "$title - $text"
            } catch (_: Exception) {
                text
            }
        }
    }
}
```

- [ ] **Step 5: Run test — verify it passes**

Run: `./gradlew test --tests '*TitleFetcherTest*'`

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: add SecureStorage and TitleFetcher with URL detection"
```

---

### Task 4: ProjectUsageTracker & TaskHistory

**Files:**
- Create: `data/ProjectUsageTracker.kt`, `data/TaskHistory.kt`
- Test: `data/ProjectUsageTrackerTest.kt`, `data/TaskHistoryTest.kt`

- [ ] **Step 1: Write ProjectUsageTracker test**

Test: tracking usage timestamps, returning top 5 recent projects, sorting remaining alphabetically.

- [ ] **Step 2: Run test — verify it fails**

- [ ] **Step 3: Implement ProjectUsageTracker**

`data/ProjectUsageTracker.kt` — SharedPreferences-backed map of `projectId → lastUsedTimestamp`. Methods: `recordUsage(projectId)`, `getRecentProjectIds(limit=5): List<Long>`.

- [ ] **Step 4: Write TaskHistory test**

Test: adding entries, retrieving last 20, older entries evicted.

- [ ] **Step 5: Run test — verify it fails**

- [ ] **Step 6: Implement TaskHistory**

`data/TaskHistory.kt` — SharedPreferences-backed list (stored as JSON via kotlinx.serialization). Data class `TaskHistoryEntry(taskName, projectName, timestamp)`. Methods: `addEntry(entry)`, `getEntries(): List<TaskHistoryEntry>`.

- [ ] **Step 7: Run all tests — verify they pass**

Run: `./gradlew test`

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat: add project usage tracker and task history"
```

---

### Task 5: VikunjaRepository

**Files:**
- Create: `data/VikunjaRepository.kt`

- [ ] **Step 1: Implement VikunjaRepository**

`data/VikunjaRepository.kt`:
```kotlin
package ch.freaxnx01.quicktask.vikunja.data

import ch.freaxnx01.quicktask.vikunja.model.CreateTaskRequest
import ch.freaxnx01.quicktask.vikunja.model.Project
import ch.freaxnx01.quicktask.vikunja.model.TaskResponse
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class VikunjaRepository @Inject constructor(
    private val api: VikunjaApi,
) {
    suspend fun validateCredentials(): Boolean {
        return try {
            api.getProjects(perPage = 1)
            true
        } catch (_: Exception) {
            false
        }
    }

    suspend fun getAllProjects(): List<Project> {
        val allProjects = mutableListOf<Project>()
        var page = 1
        while (true) {
            val batch = api.getProjects(perPage = 100, page = page)
            allProjects.addAll(batch)
            if (batch.size < 100) break
            page++
        }
        return allProjects.filter { !it.isArchived }
    }

    suspend fun createTask(projectId: Long, title: String): TaskResponse {
        return api.createTask(projectId, CreateTaskRequest(title))
    }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `./gradlew assembleDebug`

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: add VikunjaRepository with pagination and validation"
```

---

### Task 6: Theme & SetupScreen

**Files:**
- Create: `ui/theme/Theme.kt`
- Create: `ui/setup/SetupScreen.kt`, `ui/setup/SetupViewModel.kt`
- Create: `MainActivity.kt`

- [ ] **Step 1: Create Material 3 theme**

`ui/theme/Theme.kt` — dynamic color on Android 12+, fallback purple/teal palette.

- [ ] **Step 2: Implement SetupViewModel**

`ui/setup/SetupViewModel.kt` — state: `instanceUrl`, `apiToken`, `isLoading`, `error`, `isConfigured`. Action: `connect()` calls `repository.validateCredentials()`, stores in `SecureStorage` on success.

- [ ] **Step 3: Implement SetupScreen**

`ui/setup/SetupScreen.kt` — two text fields (URL, token with visibility toggle), Connect button, error text, loading indicator.

- [ ] **Step 4: Implement MainActivity**

`MainActivity.kt` — Hilt activity. If `secureStorage.isConfigured` → show RecentTasksScreen (placeholder for now), else → show SetupScreen.

- [ ] **Step 5: Verify it compiles**

Run: `./gradlew assembleDebug`

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: add setup screen with credential validation"
```

---

### Task 7: RecentTasksScreen

**Files:**
- Create: `ui/history/RecentTasksScreen.kt`, `ui/history/RecentTasksViewModel.kt`
- Modify: `MainActivity.kt`

- [ ] **Step 1: Implement RecentTasksViewModel**

Exposes `taskHistory.getEntries()` as state flow.

- [ ] **Step 2: Implement RecentTasksScreen**

List of `TaskHistoryEntry` items showing task name, project name, relative timestamp. Empty state text. Settings gear icon in top bar navigates to SetupScreen.

- [ ] **Step 3: Wire into MainActivity**

Navigate between SetupScreen and RecentTasksScreen based on `secureStorage.isConfigured`.

- [ ] **Step 4: Verify it compiles**

Run: `./gradlew assembleDebug`

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add recent tasks screen with empty state"
```

---

### Task 8: ShareActivity & ProjectPickerScreen

**Files:**
- Create: `ui/share/ShareViewModel.kt`, `ui/share/ProjectPickerScreen.kt`
- Create: `ShareActivity.kt`
- Test: `ui/share/ShareViewModelTest.kt`

- [ ] **Step 1: Write ShareViewModel test**

Test: `sortProjects()` — given a list of projects and recent IDs, returns recent first then rest A-Z. Test: `filterProjects()` — filters by query string. Test: content resolution (URL vs plain text).

- [ ] **Step 2: Run test — verify it fails**

- [ ] **Step 3: Implement ShareViewModel**

`ui/share/ShareViewModel.kt`:
- State: `projects` (sorted/filtered), `searchQuery`, `isLoading`, `taskName`, `error`, `isDone`
- On init: receive shared text + extra subject, resolve task name via `TitleFetcher`, fetch projects via `VikunjaRepository`
- `onProjectSelected(project)`: create task, record usage, add to history, set `isDone`
- `onSearchQueryChanged(query)`: filter projects

- [ ] **Step 4: Run test — verify it passes**

- [ ] **Step 5: Implement ProjectPickerScreen**

`ui/share/ProjectPickerScreen.kt`:
- Search text field (auto-focused)
- "Recent" section header + items
- "All Projects" section header + items
- Loading/error states
- Tapping item calls `viewModel.onProjectSelected()`

- [ ] **Step 6: Implement ShareActivity**

`ShareActivity.kt`:
- Hilt activity
- Read `Intent.EXTRA_TEXT` and `Intent.EXTRA_SUBJECT`
- If not configured → launch MainActivity, finish
- Pass shared data to `ShareViewModel` via SavedStateHandle
- Show `ProjectPickerScreen`
- Observe `isDone` → show snackbar, delay 1.5s, `finish()`

- [ ] **Step 7: Verify it compiles**

Run: `./gradlew assembleDebug`

- [ ] **Step 8: Run all tests**

Run: `./gradlew test`

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "feat: add share activity with project picker and task creation"
```

---

### Task 9: Polish & Final Verification

**Files:**
- Modify: `res/values/strings.xml` (ensure all strings extracted)
- Create: `proguard-rules.pro` (keep serialization classes)

- [ ] **Step 1: Add ProGuard rules**

Keep kotlinx.serialization classes, Retrofit interfaces, Jsoup.

- [ ] **Step 2: Run full test suite**

Run: `./gradlew test`

- [ ] **Step 3: Build release APK**

Run: `./gradlew assembleRelease`

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "chore: add ProGuard rules and finalize for release"
```
