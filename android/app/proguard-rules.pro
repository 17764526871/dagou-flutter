# Flutter Gemma ProGuard Rules
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Keep MediaPipe proto classes
-keep class com.google.mediapipe.proto.** { *; }
-dontwarn com.google.mediapipe.proto.**

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep TensorFlow Lite
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Keep Gemma classes
-keep class dev.flutterberlin.flutter_gemma.** { *; }
-dontwarn dev.flutterberlin.flutter_gemma.**
