plugins {
    id("com.android.application")
    id("kotlin-android")
    // Apply Flutter plugin after Android and Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.attendance_manager"
    compileSdk = 35

    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.attendance_manager"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug") // For now; use release config in production
        }
    }

    packagingOptions {
        resources.excludes += "META-INF/proguard/androidx-annotations.pro"
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")

    // Core library desugaring to support newer Java APIs
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
