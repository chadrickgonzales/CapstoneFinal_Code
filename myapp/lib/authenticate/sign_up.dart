import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterWithEmailForm extends StatefulWidget {
  const RegisterWithEmailForm({Key? key}) : super(key: key);

  @override
  _RegisterWithEmailFormState createState() => _RegisterWithEmailFormState();
}

class _RegisterWithEmailFormState extends State<RegisterWithEmailForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _error = '';
  String _successMessage = '';

 void _registerWithEmailAndPassword() async {
  String email = _emailController.text.trim();
  String password = _passwordController.text.trim();
  String username = _usernameController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    setState(() {
      _error = 'Please enter both email and password.';
      _successMessage = '';
    });
    return;
  }

  try {
    // Create user
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;

    if (user != null) {
      // Add user to Firestore immediately
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false, 
        'isAdmin': false,
        'isDeactivate': false// You can add a field to indicate verification status
      });

      // Send email verification
      await user.sendEmailVerification();

      // Optionally update user profile with username
      await user.updateProfile(displayName: username);

      setState(() {
        _successMessage = 'Account created. Check your email for verification.';
        _error = '';
      });

      // Prompt user to check their email
      _showVerificationDialog();
    }
  } catch (e) {
    setState(() {
      _error = 'Failed to register: $e';
      _successMessage = '';
    });
  }
}
  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Verify Email'),
          content: Text('Please verify your email address before logging in.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register with Email'),
      ),
      backgroundColor: Color.fromARGB(225, 80, 96, 116),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            ElevatedButton(
              onPressed: _registerWithEmailAndPassword,
              child: Text('Register'),
            ),
            SizedBox(height: 12.0),
            Text(
              _error,
              style: TextStyle(color: Colors.red, fontSize: 14.0),
            ),
            Text(
              _successMessage,
              style: TextStyle(color: Colors.green, fontSize: 14.0),
            ),
          ],
        ),
      ),
    );
  }
}