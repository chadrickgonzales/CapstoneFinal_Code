import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/pages/google_map_page.dart';
import 'package:myapp/wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAocNg3WkX5ppmhc-vTf1IHvG75EM1Rr5k",
      appId: "1:69614301418:android:947a9b4d17c8b529f46793",
      messagingSenderId: "69614301418",
      projectId: "outopiadatabase",
      storageBucket: "outopiadatabase.appspot.com",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if a user is already signed in using FirebaseAuth.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has data, it means the user is signed in.
        if (snapshot.hasData) {
          return const MaterialApp(
            home: MapSample(),
          );
        } else {
          // If there is no user, show the authentication wrapper.
          return const MaterialApp(
            home: Wrapper(),
          );
        }
      },
    );
  }
}
