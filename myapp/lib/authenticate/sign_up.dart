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
  bool _isTermsAccepted = false; // Track if terms are accepted

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

    if (!_isTermsAccepted) {
      setState(() {
        _error = 'You must agree to the terms and conditions.';
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

 void _showTermsDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Terms and Conditions'),
        content: SingleChildScrollView(
          child: Text(
            'Welcome to our application! Please read these Terms and Conditions carefully before using our services.\n\n'
            '1. Acceptance of Terms\n'
            '   By creating an account, you agree to abide by these Terms and Conditions. If you do not agree, please refrain from using our services.\n\n'
            
            '2. Account Responsibility\n'
            '   You are responsible for maintaining the confidentiality of your account and password, and for all activities that occur under your account. Please notify us immediately of any unauthorized use.\n\n'
            
            '3. Content Guidelines\n'
            '   - Users must not post any form of inappropriate, offensive, or illegal content, including but not limited to:\n'
            '     - Hate speech, harassment, or abusive language.\n'
            '     - Nudity, explicit material, or violent imagery.\n'
            '     - Copyrighted or protected material that you do not have the right to use.\n\n'
            '   - We reserve the right to review, moderate, and remove content that violates these guidelines. Repeat offenses may result in suspension or termination of your account.\n\n'
            
            '4. User Conduct\n'
            '   You agree not to engage in any activities that may harm or interfere with other users or with the operation of our services. This includes, but is not limited to, attempting to hack, spam, or phish.\n\n'
            
            '5. Privacy Policy\n'
            '   Your use of our service is also governed by our Privacy Policy, which outlines how we collect, use, and protect your data.\n\n'
            
            '6. Modification of Terms\n'
            '   We reserve the right to modify or update these Terms at any time. Continued use of our services constitutes acceptance of the updated Terms.\n\n'
            
            '7. Termination\n'
            '   We reserve the right to suspend or terminate your account at our sole discretion if you violate any part of these Terms.\n\n'
            
            'Thank you for using our application responsibly and respecting our community guidelines. If you have any questions, feel free to contact us.\n\n'
            
            'By agreeing to these Terms and Conditions, you confirm that you understand and accept the rules outlined above.'
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Close'),
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
              style: TextStyle(color: Colors.white),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _isTermsAccepted,
                  onChanged: (bool? value) {
                    setState(() {
                      _isTermsAccepted = value ?? false;
                    });
                  },
                ),
                GestureDetector(
                  onTap: _showTermsDialog,
                  child: Text(
                    'I agree to the Terms and Conditions',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
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
