import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")   // 🔥 REQUIRED FOR FIREBASE
}

android {
    namespace = "com.example.resqnet_frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "23.1.7779620"
    packaging {
    jniLibs {
        useLegacyPackaging = true
    }
}

    androidResources {
    noCompress += "tflite"
}

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.resqnet_frontend"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"].toString()
        keyPassword = keystoreProperties["keyPassword"].toString()
        storeFile = file("upload-keystore.jks")   // ✅ ADD THIS LINE
        storePassword = keystoreProperties["storePassword"].toString()
    }
}

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            ndk {
                debugSymbolLevel = "NONE"
            }
        }
    }
}  // ✅ ADD THIS (closing android)

flutter {
    source = "../.."
}