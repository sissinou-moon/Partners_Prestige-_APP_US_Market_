# Keep Stripe SDK classes
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }

# Keep all Stripe Android SDK classes to be safe
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Keep React Native Stripe SDK classes
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**