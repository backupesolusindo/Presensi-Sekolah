plugins {
    id("com.android.application")
    id("kotlin-android")
}

android {
    namespace = "com.example.mguru" // Ganti sesuai package kamu
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.mguru" // Ganti sesuai package kamu
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    ndkVersion = "25.1.8937393" // Pastikan sesuai versi yang terinstall di Android SDK
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")

    // Untuk desugaring (flutter_local_notifications & Java 8+ API)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
