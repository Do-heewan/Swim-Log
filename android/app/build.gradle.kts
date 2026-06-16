plugins {
    id("com.android.application")
    id("kotlin-android")
    // Samsung Health Data SDK 데이터 클래스가 kotlinx-parcelize 런타임을 요구한다.
    // (로컬 AAR은 transitive 의존성을 안 가져오므로 직접 제공.)
    id("kotlin-parcelize")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.noh.swim_log"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.noh.swim_log"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Samsung Health Data SDK는 Android 10(API 29) 이상 필요.
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Samsung Health Data SDK — AAR을 android/app/libs/ 에 두면 자동 포함된다.
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    // suspend 브릿지 호출용 코루틴 + lifecycleScope.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.4")
    // SDK가 내부 직렬화에 gson을 쓴다(로컬 AAR transitive 미포함 → 직접 제공).
    implementation("com.google.code.gson:gson:2.11.0")
}
