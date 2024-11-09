import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/authenticate/sign_up.dart';
import 'package:myapp/pages/google_map_page.dart';
import 'package:myapp/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _signIn() async {
  String email = _emailController.text.trim();
  String password = _passwordController.text.trim();

  // Step 1: Fetch user document from Firestore
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();

  if (userDoc.docs.isEmpty) {
    setState(() {
      error = 'User not found.';
    });
    return;
  }

  // Get user data from Firestore
  final userData = userDoc.docs.first.data();
  bool isDeactivated = userData['isDeactivated'] ?? false;
  String deactivationMessage = userData['deactivateMessage'] ?? 'Your account has been deactivated.';

  // Step 2: Check if account is deactivated
  if (isDeactivated) {
    setState(() {
      error = deactivationMessage; // Use the deactivation message from Firestore
    });
    return;
  }

  // Step 3: Sign in with email and password
  User? user = await _auth.signInWithEmailPassword(email, password);
  if (user == null) {
    setState(() {
      error = 'Incorrect email or password. or email is not verified';
    });
    return;
  }

  // Step 4: Check if the email is verified
  if (!user.emailVerified) {
    setState(() {
      error = 'Incorrect email or password. or email is not verified';
    });
    await _auth.signOut(); // Sign out if email is not verified
    return;
  }

  // Step 5: Update isVerified in Firestore
  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    'isVerified': true,
  });

  // Step 6: Redirect to MapSample if all checks are satisfied
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const MapSample()),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
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
              onPressed: _signIn,
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
