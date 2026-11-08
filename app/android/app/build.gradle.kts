plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.gramotune"
    // permission_handler_android 14.1.1 (via permission_handler 13.0.2) needs
    // API 37 to compile (D-015 amendment). targetSdk stays at the Play
    // requirement: Android 16 / API 36, in force since 2026-08-31.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Placeholder id until D-001 is decided (05 §1). Permanent once published.
        applicationId = "app.gramotune"
        // 05 §1: minSdk 26 because AAudio starts there; targetSdk 36 is the
        // Google Play requirement for new apps and updates (D-015).
        minSdk = 26
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // D-013: `play` is local only (no INTERNET permission); `full` adds the
    // YouTube source after v1.0 and is distributed outside Google Play.
    flavorDimensions += "distribution"
    productFlavors {
        create("play") {
            dimension = "distribution"
        }
        create("full") {
            dimension = "distribution"
        }
    }

    buildTypes {
        release {
            // Release signing is configured at M4.6 (D-016 decides the license
            // first). Debug keys keep `flutter run --release` working until then.
            signingConfig = signingConfigs.getByName("debug")
            // M0.4 enables R8/shrinking explicitly in release; 05 §2.
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
