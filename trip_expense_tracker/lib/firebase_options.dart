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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAN3WO-h2m2yFO-N9Litov6iFXam4bCZX8',
    appId: '1:1050071786747:web:5f49e8ac1c79fd186c3c5e',
    messagingSenderId: '1050071786747',
    projectId: 'tallyapp-77f07',
    authDomain: 'tallyapp-77f07.firebaseapp.com',
    storageBucket: 'tallyapp-77f07.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC14quN748x1hW3UuRYLbPkfK7redOQGEE',
    appId: '1:1050071786747:android:a5282c4f6e6530f66c3c5e',
    messagingSenderId: '1050071786747',
    projectId: 'tallyapp-77f07',
    storageBucket: 'tallyapp-77f07.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC6whcMXOT0mRzVB-RD77a4ycLsuRaOaWU',
    appId: '1:1050071786747:ios:cd3570f81ce90b786c3c5e',
    messagingSenderId: '1050071786747',
    projectId: 'tallyapp-77f07',
    storageBucket: 'tallyapp-77f07.firebasestorage.app',
    iosBundleId: 'com.example.tripExpenseTracker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC6whcMXOT0mRzVB-RD77a4ycLsuRaOaWU',
    appId: '1:1050071786747:ios:cd3570f81ce90b786c3c5e',
    messagingSenderId: '1050071786747',
    projectId: 'tallyapp-77f07',
    storageBucket: 'tallyapp-77f07.firebasestorage.app',
    iosBundleId: 'com.example.tripExpenseTracker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAN3WO-h2m2yFO-N9Litov6iFXam4bCZX8',
    appId: '1:1050071786747:web:6e86f7b510f633016c3c5e',
    messagingSenderId: '1050071786747',
    projectId: 'tallyapp-77f07',
    authDomain: 'tallyapp-77f07.firebaseapp.com',
    storageBucket: 'tallyapp-77f07.firebasestorage.app',
  );

}