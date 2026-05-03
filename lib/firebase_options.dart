import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('web not configured yet');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcnvHV0c8yPYpJg-Oim3Eo57FXc7oKP-8',
    appId: '1:1070441052675:android:596e6457a8d6ad3d8b6c36',
    messagingSenderId: '1070441052675',
    projectId: 'fir-auth-app-a32da',
    storageBucket: 'fir-auth-app-a32da.firebasestorage.app',
  );

  // placeholder — will be replaced by flutterfire configure

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.focusnflow.focusnflowApp',
  );
}