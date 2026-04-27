# VAVEL Wallet — release shrinking / obfuscation (R8)
# https://docs.flutter.dev/deployment/android#enabling-r8

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase / Play Services (messaging, common)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
# Huawei Mobile Services (Push Kit + availability checks)
-keep class com.huawei.hms.** { *; }
-dontwarn com.huawei.hms.**

# Kotlin / coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Gson / reflective JSON (some SDKs)
-keepattributes EnclosingMethod
-keepclassmembers enum * { public static **[] values(); public static ** valueOf(java.lang.String); }

# WalletConnect / Reown (JNI and reflective entry points vary by version)
-keep class com.reown.** { *; }
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Mobile scanner / CameraX
-keep class androidx.camera.** { *; }

# Play Core — Flutter embedding references deferred split-install APIs; omitting the
# dependency is normal for a single App Bundle. R8 otherwise fails minifyReleaseWithR8.
-dontwarn com.google.android.play.core.**
