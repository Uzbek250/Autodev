# Keep sqflite
-keep class com.tekartik.sqflite.** { *; }

# Keep dio / okhttp internals
-keep class com.squareup.okhttp3.** { *; }
-dontwarn com.squareup.okhttp3.**

# Keep Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Keep Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Gson (if used transitively)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }
