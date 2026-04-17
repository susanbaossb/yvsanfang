plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yvsanfang"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yvsanfang"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 极光推送占位符（实际值在 Dart 代码中配置）
        manifestPlaceholders["JPUSH_APPKEY"] = project.findProperty("JPUSH_APPKEY") ?: "b2cb97c91afe25f739bc267f"
        manifestPlaceholders["JPUSH_CHANNEL"] = project.findProperty("JPUSH_CHANNEL") ?: "developer_default"
        
        // ========== 厂商通道 AppKey ==========
        // 华为
        manifestPlaceholders["HUAWEI_APPID"] = project.findProperty("HUAWEI_APPID") ?: ""
        // 小米
        manifestPlaceholders["XIAOMI_APPID"] = project.findProperty("XIAOMI_APPID") ?: ""
        manifestPlaceholders["XIAOMI_APPKEY"] = project.findProperty("XIAOMI_APPKEY") ?: ""
        // OPPO
        manifestPlaceholders["OPPO_APPKEY"] = project.findProperty("OPPO_APPKEY") ?: ""
        manifestPlaceholders["OPPO_APPSECRET"] = project.findProperty("OPPO_APPSECRET") ?: ""
        // VIVO
        manifestPlaceholders["VIVO_APPID"] = project.findProperty("VIVO_APPID") ?: ""
        manifestPlaceholders["VIVO_APPKEY"] = project.findProperty("VIVO_APPKEY") ?: ""
        // 魅族
        manifestPlaceholders["MEIZU_APPID"] = project.findProperty("MEIZU_APPID") ?: ""
        manifestPlaceholders["MEIZU_APPKEY"] = project.findProperty("MEIZU_APPKEY") ?: ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ========== 极光厂商通道依赖 ==========
    // 配置好厂商凭证后，取消对应行的注释即可启用
    // 华为
    // implementation("cn.jiguang:jmap-huawei:1.1.1")
    // 小米
    // implementation("cn.jiguang:jmap-xiaomi:1.1.1")
    // OPPO
    // implementation("cn.jiguang:jmap-oppo:1.1.1")
    // VIVO
    // implementation("cn.jiguang:jmap-vivo:1.1.1")
    // 魅族
    // implementation("cn.jiguang:jmap-meizu:1.1.1")
}
