pluginManagement {
val flutterSdkPath = run {
val properties = java.util.Properties()
file("local.properties").inputStream().use { properties.load(it) }
properties.getProperty("flutter.sdk")
}

```
includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
}
```

}

dependencyResolutionManagement {
repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
repositories {
google()
mavenCentral()
}
}

rootProject.name = "car_rental"
include(":app")
