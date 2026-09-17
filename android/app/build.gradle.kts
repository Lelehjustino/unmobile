import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.un.recepcao"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17 
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
    
    defaultConfig {
        applicationId = "com.un.recepcao"
        // minSdk = flutter.minSdkVersion //bundle
        // targetSdk = 36
        // minSdk = flutter.minSdkVersion
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            /* keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String*/
            keyAlias = keystoreProperties["keyAlias"]?.toString()
            keyPassword = keystoreProperties["keyPassword"]?.toString()
            storeFile = keystoreProperties["storeFile"]?.let { file(it.toString()) }
            storePassword = keystoreProperties["storePassword"]?.toString()
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// android {
//     namespace = "com.un.recepcao"
//     compileSdk = 36
//     ndkVersion = "27.0.12077973"

//     compileOptions {
//         sourceCompatibility = JavaVersion.VERSION_17 
//         targetCompatibility = JavaVersion.VERSION_17
//     }

//     kotlinOptions {
//         jvmTarget = "17"
//     }

//     defaultConfig {
//         applicationId = "com.un.recepcao"
//         minSdk = flutter.minSdkVersion
//         targetSdk = flutter.targetSdkVersion
//         versionCode = flutter.versionCode
//         versionName = flutter.versionName
//     }

//     signingConfigs {
//         create("release") {
//             keyAlias = keystoreProperties["keyAlias"] as String
//             keyPassword = keystoreProperties["keyPassword"] as String
//             storeFile = file(keystoreProperties["storeFile"] as String)
//             storePassword = keystoreProperties["storePassword"] as String
//         }
//     }

//     buildTypes {
//         getByName("release") {
//             signingConfig = signingConfigs.getByName("release")
//             isMinifyEnabled = false
//             isShrinkResources = false
//         }
//     }
// }

flutter {
    source = "../.."
}

dependencies {
    implementation("br.com.uol.pagseguro.plugpagservice.wrapper:wrapper:1.35.0")
}


// plugins {
//     id("com.android.application")
//     id("kotlin-android")
//     // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
//     id("dev.flutter.flutter-gradle-plugin")
// }

// android {
//     namespace = "com.un.recepcao"
//     compileSdk = flutter.compileSdkVersion
//     ndkVersion = flutter.ndkVersion

//     compileOptions {
//         sourceCompatibility = JavaVersion.VERSION_11
//         targetCompatibility = JavaVersion.VERSION_11
//     }

//     kotlinOptions {
//         jvmTarget = JavaVersion.VERSION_11.toString()
//     }

//     defaultConfig {
//         // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
//         applicationId = "com.un.recepcao"
//         // You can update the following values to match your application needs.
//         // For more information, see: https://flutter.dev/to/review-gradle-config.
//         minSdk = flutter.minSdkVersion
//         targetSdk = flutter.targetSdkVersion
//         versionCode = flutter.versionCode
//         versionName = flutter.versionName
//     }

//     buildTypes {
//         getByName("release") {
//             signingConfig = signingConfigs.getByName("debug")

//             isMinifyEnabled = false
//             isShrinkResources = false
//         }
//     }
// }

// flutter {
//     source = "../.."
// }
