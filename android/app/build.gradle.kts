import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key for the Play Store – android/key.properties and the keystore
// stay on the developer's machine (.gitignore); without them release builds
// are signed with the debug key, as for playtest APKs.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Dev build (SC_DEV=1, scripts/install_dev.sh): its own app id and name,
// so it sits next to the Play Store version on the test phone.
val devBuild = System.getenv("SC_DEV") == "1"

android {
    namespace = "de.heilsarmee.spiritual_city"
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
        // Never changes once on the Play Store: the Salvation Army corps
        // Chemnitz is responsible for the game.
        applicationId = "de.heilsarmee.spiritual_city"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        if (devBuild) applicationIdSuffix = ".dev"
        resValue("string", "app_name", if (devBuild) "Spiritual City Dev" else "Spiritual City")
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (keystorePropertiesFile.exists()) "release" else "debug")
        }
    }
}

flutter {
    source = "../.."
}
