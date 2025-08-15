## ----------------------------------
## Flutter & Dart basic rules
## ----------------------------------
# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Dart generated code
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class androidx.lifecycle.** { *; }

# Avoid warnings from Flutter
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugins.**

## ----------------------------------
## Google ML Kit rules
## ----------------------------------
# Keep all ML Kit classes (all features)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep text recognition (Chinese, Japanese, Korean, etc.)
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

## ----------------------------------
## TensorFlow Lite rules
## ----------------------------------
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.**

## ----------------------------------
## Google Play Services rules
## ----------------------------------
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

## ----------------------------------
## Google Play Core / SplitCompat
## ----------------------------------
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

## ----------------------------------
## CameraX rules (jika pakai camera plugin)
## ----------------------------------
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

## ----------------------------------
## JSON / GSON rules
## ----------------------------------
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

## ----------------------------------
## Miscellaneous
## ----------------------------------
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

## ----------------------------------
## Prevent stripping of Parcelable objects
## ----------------------------------
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}
