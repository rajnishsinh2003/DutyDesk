# TensorFlow Lite ProGuard / R8 Rules
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.**
-keep class org.tensorflow.lite.** { *; }

# Google ML Kit Rules
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
