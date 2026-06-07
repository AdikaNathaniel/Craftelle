# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
<<<<<<< HEAD
-keep class io.flutter.embedding.** { *; }

# Google Maps & GMS
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.internal.firebase** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepclassmembers class ** {
    @kotlin.jvm.JvmStatic *;
    @kotlin.jvm.JvmField *;
}
-dontwarn kotlin.**

# OkHttp (used internally by Flutter http plugin on Android)
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Gson / JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Play Core (deferred components)
-dontwarn com.google.android.play.core.**

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Local auth (biometrics)
-keep class io.flutter.plugins.localauth.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Camera (legacy plugin)
-keep class io.flutter.plugins.camera.** { *; }

# camera_android_camerax plugin (Kotlin 2.1.0, used by camera: ^0.11.1)
-keep class io.flutter.plugins.camerax.** { *; }
-keep class androidx.camera.** { *; }
-keep interface androidx.camera.** { *; }
-dontwarn androidx.camera.**

# WebView
-keep class io.flutter.plugins.webviewflutter.** { *; }

# URL launcher
-keep class io.flutter.plugins.urllauncher.** { *; }
=======

# Google Maps
-keep class com.google.android.gms.maps.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Play Core (deferred components)
-dontwarn com.google.android.play.core.**
>>>>>>> 7199ffd5e8563def48bf8789ffc3431a4c9325a7
