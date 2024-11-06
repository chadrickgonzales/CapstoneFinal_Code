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

  // Check if the user is signed in and if their email is verified
  void _checkUserSignedIn() async {
    var user = _auth.getCurrentUser();
    if (user != null) {
      // If user is signed in, check if email is verified
      if (user.emailVerified) {
        // If verified, check if user is deactivated
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          bool isDeactivated = userDoc.data()?['isDeactivated'] ?? false;

          if (isDeactivated) {
            // User is deactivated, show the deactivation message
            String deactivateMessage = userDoc.data()?['deactivateMessage'] ?? 'Your account has been deactivated.';
            setState(() {
              error = deactivateMessage;
            });
          } else {
            // User is not deactivated, navigate to MapSample
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MapSample()),
            );
          }
        } else {
          setState(() {
            error = 'User not found.';
          });
        }
      } else {
        // Email is not verified, prompt user to verify
        setState(() {
          error = 'Please verify your email before signing in.';
        });
        await user.sendEmailVerification(); // Resend verification email
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

                var result = await _auth.signInWithEmailPassword(email, password);

                if (result == null) {
                  setState(() {
                    error = 'Failed to sign in. Check your email and password.';
                  });
                } else {
                  if (!result.emailVerified) {
                    // If email is not verified, prompt user
                    setState(() {
                      error = 'Please verify your email before signing in.';
                    });
                    await result.sendEmailVerification();  // Resend verification email
                  } else {
                    // Check if the account is deactivated in Firestore
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(result.uid)
                        .get();

                    if (userDoc.exists) {
                      bool isDeactivated = userDoc.data()?['isDeactivated'] ?? false;

                      if (isDeactivated) {
                        String deactivateMessage = userDoc.data()?['deactivateMessage'] ?? 'Your account has been deactivated.';
                        setState(() {
                          error = deactivateMessage;
                        });
                      } else {
                        // Navigate to MapSample if the user is not deactivated
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MapSample()),
                        );
                      }
                    } else {
                      setState(() {
                        error = 'User not found.';
                      });
                    }
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterWithEmailForm()),
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