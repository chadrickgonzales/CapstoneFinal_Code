import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/authenticate/sign_up.dart';
import 'package:myapp/pages/google_map_page.dart';
import 'package:myapp/services/auth.dart';

class SignInWithEmail extends StatefulWidget {
  const SignInWithEmail({Key? key}) : super(key: key);

  @override
  _SignInWithEmailState createState() => _SignInWithEmailState();
}

class _SignInWithEmailState extends State<SignInWithEmail> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  String error = '';

  @override
  void initState() {
    super.initState();
    _checkUserSignedIn();
  }

  void _checkUserSignedIn() async {
    // Check if a user is already signed in using the token
    var user = _auth.getCurrentUser();
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        bool isDeactivated = userDoc.data()?['isDeactivated'] ?? false;

        if (isDeactivated) {
          // Check if deactivateMessage exists
          String deactivateMessage = userDoc.data()?['deactivateMessage'] ??
              'Your account has been deactivated.';

          setState(() {
            error = deactivateMessage; // Use the message from Firestore
          });
        } else {
          // Navigate to MapSample if the user is not deactivated
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MapSample()),
          );
        }
      } else {
        // Handle case where the document does not exist
        setState(() {
          error = 'User not found.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Email'),
      ),
      backgroundColor: const Color.fromARGB(225, 80, 96, 116),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              obscureText: true,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                String email = _emailController.text.trim();
                String password = _passwordController.text.trim();

                var result =
                    await _auth.signInWithEmailPassword(email, password);
                if (result == null) {
                  setState(() {
                    error = 'Failed to sign in. Check your email and password.';
                  });
                } else {
                  // Check if the account is deactivated in Firestore
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(result.uid)
                      .get();

                  if (userDoc.exists) {
                    bool isDeactivated =
                        userDoc.data()?['isDeactivated'] ?? false;

                    if (isDeactivated) {
                      // Check if deactivateMessage exists
                      String deactivateMessage =
                          userDoc.data()?['deactivateMessage'] ??
                              'Your account has been deactivated.';

                      setState(() {
                        error =
                            deactivateMessage; // Use the message from Firestore
                      });
                    } else {
                      // Navigate to MapSample if the user is not deactivated
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MapSample()),
                      );
                    }
                  } else {
                    // Handle case where the document does not exist
                    setState(() {
                      error = 'User not found.';
                    });
                  }
                }
              },
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 12.0),
            Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 14.0),
            ),
            const SizedBox(height: 20.0),
            TextButton(
              onPressed: () {
                // Navigate to RegisterWithEmailForm when "Create an Account" is clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterWithEmailForm()),
                );
              },
              child: const Text(
                'Create an Account',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
