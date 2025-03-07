import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for different platforms
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web platform configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAfkTh1bZvZr1nFgTx7Y_bNkTY_NNRPwjw',
    appId: '1:317289370549:web:3cf0ef6336cc20c762fffc',
    messagingSenderId: '317289370549',
    projectId: 'assetflow-fire1',
    authDomain: 'assetflow-fire1.firebaseapp.com',
    storageBucket: 'assetflow-fire1.firebasestorage.app',
    measurementId: 'G-4BDB018L60',
  );

  // Android platform configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAfkTh1bZvZr1nFgTx7Y_bNkTY_NNRPwjw',
    appId: '1:317289370549:android:f47cb46e3d21e4ca62fffc', // Changed to use Android-specific app ID
    messagingSenderId: '317289370549',
    projectId: 'assetflow-fire1',
    storageBucket: 'assetflow-fire1.appspot.com', // Corrected storage bucket format
  );

  // iOS platform configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAfkTh1bZvZr1nFgTx7Y_bNkTY_NNRPwjw',
    appId: '1:317289370549:ios:38a9f6751c67a1d462fffc', // Changed to use iOS-specific app ID
    messagingSenderId: '317289370549',
    projectId: 'assetflow-fire1',
    storageBucket: 'assetflow-fire1.appspot.com', // Corrected storage bucket format
    iosClientId: '317289370549-i9g73v4k2m5e8r6lnt7h1o3qjp9v6b7s.apps.googleusercontent.com', // Added a placeholder
    iosBundleId: 'com.yourcompany.assetflow',
  );
}