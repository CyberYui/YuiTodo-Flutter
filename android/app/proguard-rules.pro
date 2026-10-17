# Keep generic signatures and annotations so Gson can deserialize the
# scheduled-notification journal used by flutter_local_notifications.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# flutter_local_notifications models + Gson
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep @SerializedName fields
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep enum values used by the plugin
-keepclassmembers enum * {
  public static **[] values();
  public static ** valueOf(java.lang.String);
}
