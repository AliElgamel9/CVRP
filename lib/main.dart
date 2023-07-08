import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_backend/firebase_options.dart';
import 'firebase_backend/authentication_services.dart';
import 'utils/global_views.dart';
import 'authentication/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              Provider<AuthenticationService>(
                create: (_) => AuthenticationService(),
              )
            ],
            child: MaterialApp(
              home: LoginPage(),
            ),
          );
        }
        return loadingScreen();
      },
    );
  }
}
