// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhyxUFAhSDIlO0_eVA-v1mvFL-NPOpe7k',
    appId: '1:127169780369:android:71e3b5b90541252162fd30',
    messagingSenderId: '127169780369',
    projectId: 'progetto-mobile-flutter',
    storageBucket: 'progetto-mobile-flutter.appspot.com',
    databaseURL: 'https://progetto-mobile-flutter-default-rtdb.europe-west1.firebasedatabase.app/',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCiDLhR6Dpngqfw5HmBlMMQj3Uot8Vvy50',
    appId: '1:127169780369:ios:84e01503683e87de62fd30',
    messagingSenderId: '127169780369',
    projectId: 'progetto-mobile-flutter',
    storageBucket: 'progetto-mobile-flutter.appspot.com',
    iosBundleId: 'com.example.progettomobileflutter',
    databaseURL: 'https://progetto-mobile-flutter-default-rtdb.europe-west1.firebasedatabase.app/',
  );
}
