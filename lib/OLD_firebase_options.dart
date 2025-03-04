import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAfkTh1bZvZr1nFgTx7Y_bNkTY_NNRPwjw',
    appId: '1:317289370549:web:3cf0ef6336cc20c762fffc',
    messagingSenderId: '317289370549',
    projectId: 'assetflow-fire1',
    authDomain: 'assetflow-fire1.firebaseapp.com',
    storageBucket: 'assetflow-fire1.firebasestorage.app',
    measurementId: 'G-4BDB018L60',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAtDs2s9T2NuHx2roT8fYX6obbj9H_dGR0',
    appId: '1:317289370549:android:cbc9efa0566f428962fffc',
    messagingSenderId: '317289370549',
    projectId: 'assetflow-fire1',
    storageBucket: 'assetflow-fire1.firebasestorage.app',
  );
}