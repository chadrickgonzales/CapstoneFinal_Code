import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in.dart'; // Import the sign_in.dart file

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
    UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
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
        'isDeactivate': false
      });

      // Send email verification
      await user.sendEmailVerification();

      // Optionally update user profile with username
      await user.updateProfile(displayName: username);

      setState(() {
        _successMessage =
            'Account created. Check your email for verification.';
        _error = '';
      });

      // Sign out the user to prevent login before verification
      await FirebaseAuth.instance.signOut();

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
                _navigateToSignIn(); // Call the function to navigate
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToSignIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInWithEmail()),
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
            decoration: InputDecoration(
              labelText: 'Email', 
              labelStyle: TextStyle(color: Colors.white),
            ),
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: Colors.white), // Text color inside the TextField
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password', 
              labelStyle: TextStyle(color: Colors.white),
            ),
            obscureText: true,
            style: TextStyle(color: Colors.white),
          ),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username', 
              labelStyle: TextStyle(color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
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