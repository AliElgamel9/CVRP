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
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyA4Uk0JuLsR7rP_pYXneWXtFtgIpWJwZNs',
    appId: '1:185913722733:web:242d180f7827e88c14fc64',
    messagingSenderId: '185913722733',
    projectId: 'cvrp-23ec2',
    authDomain: 'cvrp-23ec2.firebaseapp.com',
    databaseURL: 'https://cvrp-23ec2-default-rtdb.firebaseio.com',
    storageBucket: 'cvrp-23ec2.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDi6gAPGmQ1MtDhIM3cIZlSsAOQuNgKjbM',
    appId: '1:185913722733:android:4e0012a360702ab514fc64',
    messagingSenderId: '185913722733',
    projectId: 'cvrp-23ec2',
    databaseURL: 'https://cvrp-23ec2-default-rtdb.firebaseio.com',
    storageBucket: 'cvrp-23ec2.appspot.com',
  );
}
