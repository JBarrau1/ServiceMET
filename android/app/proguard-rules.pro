# Reglas para Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Reglas para Kotlin
-keep class kotlin.** { *; }
-keep class org.jetbrains.kotlin.** { *; }
-dontwarn kotlin.**
-dontwarn org.jetbrains.kotlin.**

# Reglas para jcifs
-keep class jcifs.** { *; }
-dontwarn jcifs.**

# Reglas para org.ietf.jgss
-keep class org.ietf.jgss.** { *; }
-dontwarn org.ietf.jgss.**

# Reglas para net.sourceforge.jtds
-keep class net.sourceforge.jtds.** { *; }
-dontwarn net.sourceforge.jtds.**