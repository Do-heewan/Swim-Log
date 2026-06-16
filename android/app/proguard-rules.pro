# Samsung Health Data SDK — R8/ProGuard가 SDK 클래스를 strip하지 않도록 keep.
-keep class com.samsung.android.sdk.health.data.** { *; }
-dontwarn com.samsung.android.sdk.health.data.**
