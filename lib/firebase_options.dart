// This file will be generated automatically when Firebase is configured.
// For now, using default configuration to prevent compilation errors.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyB3SH2qCdtyKwx7LHLlOkU5SaR4tu1GHHw',
    appId: '1:687008024925:web:24e3ea99219826eca380b4',
    messagingSenderId: '687008024925',
    projectId: 'o6hxc54nwwi030f8y17tsfe3qxhlt5',
    authDomain: 'o6hxc54nwwi030f8y17tsfe3qxhlt5.firebaseapp.com',
    storageBucket: 'o6hxc54nwwi030f8y17tsfe3qxhlt5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBb62nxEn62DYZEzO0Lrxl478aegrwLrzI',
    appId: '1:687008024925:android:4ce6fba291e5b5f0a380b4',
    messagingSenderId: '687008024925',
    projectId: 'o6hxc54nwwi030f8y17tsfe3qxhlt5',
    storageBucket: 'o6hxc54nwwi030f8y17tsfe3qxhlt5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjtP9uAnZvIrMFGUiKv8z3OiQ2GfZMfQM',
    appId: '1:687008024925:ios:82298f7c8b782c8ea380b4',
    messagingSenderId: '687008024925',
    projectId: 'o6hxc54nwwi030f8y17tsfe3qxhlt5',
    storageBucket: 'o6hxc54nwwi030f8y17tsfe3qxhlt5.firebasestorage.app',
    iosBundleId: 'app.trashit.online',
  );

}