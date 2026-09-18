part of '../services.dart';

// import 'package:firebase_core/firebase_core.dart';

// class FirebaseInitializer {
//   FirebaseInitializer._();

//   static Future<void>? _initialization;

//   static Future<void> initialize({required FirebaseOptions options}) {
//     return _initialization ??= _initialize(options);
//   }

//   static Future<void> _initialize(FirebaseOptions options) async {
//     if (Firebase.apps.any((app) => app.name == defaultFirebaseAppName)) {
//       return;
//     }

//     try {
//       await Firebase.initializeApp(options: options);
//     } on FirebaseException catch (error) {
//       if (error.code != 'duplicate-app') rethrow;
//     }
//   }
// }
