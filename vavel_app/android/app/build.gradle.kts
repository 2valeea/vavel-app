import java.util.Base64
import java.util.Properties
import java.io.StringReader

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// WalletConnect / Reown: optional `WC_PROJECT_ID=…` in android/local.properties
// (gitignored). Merged with `--dart-define` from `flutter build` as base64
// `KEY=value` entries (Flutter convention).
val localPropertiesFile = rootProject.file("local.properties")
val localForDartDefines = Properties()
if (localPropertiesFile.exists()) {
    localForDartDefines.load(localPropertiesFile.inputStream())
}
val wcProjectId = localForDartDefines.getProperty("WC_PROJECT_ID")?.trim().orEmpty()
if (wcProjectId.isNotEmpty()) {
    val entry = Base64.getEncoder()
        .encodeToString("WC_PROJECT_ID=$wcProjectId".toByteArray(Charsets.UTF_8))
    val existing = (findProperty("dart-defines") as String?)?.trim().orEmpty()
    val merged =
        if (existing.isEmpty()) entry else "$existing,$entry"
    extra.set("dart-defines", merged)
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
val hasReleaseKeystore = keyPropertiesFile.exists()
if (hasReleaseKeystore) {
    val raw = keyPropertiesFile.readText(Charsets.UTF_8).removePrefix("\uFEFF")
    keyProperties.load(StringReader(raw))
}

// Firebase Android config: add android/app/google-services.json from Firebase Console,
// then sync. Build works without it (plugin not applied).
val googleServicesJson = file("google-services.json")
if (googleServicesJson.exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.vavel.vavel_wallet"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = keyProperties["storeFile"]?.let { file(it as String) }
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.vavel.vavel_wallet"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
