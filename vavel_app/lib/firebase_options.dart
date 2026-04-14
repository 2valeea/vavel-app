// Firebase options for this app.
//
// **Production:** run once from the project root:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
// which regenerates this file and downloads `android/app/google-services.json`.
//
// Until then, placeholders let the project compile; [Firebase.initializeApp] may
// fail at runtime until values match your Firebase Console project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only set up for Android in this project.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-your-firebase-project-id',
    storageBucket: 'replace-with-your-firebase-project-id.appspot.com',
  );
}
