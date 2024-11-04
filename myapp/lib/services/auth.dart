import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/models/user.dart'; // Assuming User1 model is defined correctly

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instanceFor(app: Firebase.app());
  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(app: Firebase.app());

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Check if a user is already signed in
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Convert Firebase User to custom User1 model
  User1 _userFromFirebaseUser(User? user) {
    return User1(
      uid: user?.uid ?? '',
      id: '',
      name: user?.displayName ?? '',
      email: user?.email ?? '',
      username: user?.displayName ?? '',
      phoneNumber: user?.phoneNumber ?? '',
    );
  }

  // Stream to listen to authentication state changes
  Stream<User1?> get user {
    return _auth.authStateChanges().map((User? user) => _userFromFirebaseUser(user));
  }

  // Verify phone number and return verification ID
  Future<String?> verifyPhoneNumber(String phoneNumber, Function(String) onCodeSent) async {
    String? verificationId;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android devices
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Phone verification failed: ${e.message}');
        },
        codeSent: (String vId, int? resendToken) {
          verificationId = vId;
          onCodeSent(vId); // Pass verification ID to the callback function
        },
        codeAutoRetrievalTimeout: (String vId) {
          verificationId = vId;
        },
      );
      return verificationId;
    } catch (e) {
      print('Error verifying phone number: $e');
      return null;
    }
  }

  // Verify SMS code using the verification ID
  Future<bool> verifySmsCode(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print('Failed to verify SMS code: $e');
      return false;
    }
  }

  // Register user after phone verification
  Future<User1?> registerWithEmailPasswordAndPhone(
      String email, String password, String username, String phoneNumber) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      // Update user's display name (username)
      await user?.updateDisplayName(username);

      // Send email verification
      await user?.sendEmailVerification();

      // Store additional user data in Firestore
      await _storeUserData(user!.uid, email, username, phoneNumber);

      return _userFromFirebaseUser(user);
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  // Sign out


  // Store user data in Firestore
  Future<void> _storeUserData(String userId, String email, String username, String phoneNumber) async {
    try {
      await _db.collection('users').doc(userId).set({
        'email': email,
        'username': username,
        'phoneNumber': phoneNumber,
      });
    } catch (e) {
      print('Error storing user data: $e');
    }
  }

  // Sign in with email and password and check if email is verified
  
}