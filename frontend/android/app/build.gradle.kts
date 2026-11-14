import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Lee android/app/google-services.json (Firebase / notificaciones push)
    id("com.google.gms.google-services")
}

// Datos de la llave de firma (android/key.properties, no se sube a Git)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val tieneLlaveRelease = keystorePropertiesFile.exists()

if (tieneLlaveRelease) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.spa_vehicular.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requerido por flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.spa_vehicular.app"
        // Android 7.0 (API 24) como mínimo: lo exigen las notificaciones locales y Firebase
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Solo se crea si existe key.properties. Así, quien no tenga la llave
        // (por ejemplo un compañero) puede seguir corriendo la app en debug.
        if (tieneLlaveRelease) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Con key.properties firma con la llave de subida (Play Store);
            // sin él usa la de debug para que `flutter run --release` siga funcionando.
            signingConfig = if (tieneLlaveRelease) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}