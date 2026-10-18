# Pigeon JNI bindings look up Kotlin coroutine classes and suspend methods by
# their full JVM names. R8 cannot rename or discard these runtime references.
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
