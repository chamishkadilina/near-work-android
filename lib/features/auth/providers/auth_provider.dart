import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAuthenticating => _status == AuthStatus.authenticating;

  AuthProvider() {
    // Initialize GoogleSignIn with proper configuration
    _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    // Listen to auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Auth state change handler
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      _user = firebaseUser;
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      // Start interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled sign-in
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      // Obtain authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      _user = userCredential.user;

      // Update or create user document in Firestore
      if (_user != null) {
        await _updateUserData(_user!);
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      if (kDebugMode) {
        print("Error signing in with Google: $e");
      }
      notifyListeners();
      return false;
    }
  }

  // Update user data in Firestore
  Future<void> _updateUserData(User user) async {
    DocumentReference userDoc = _firestore.collection('users').doc(user.uid);

    try {
      DocumentSnapshot docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // First-time login: create a new document
        await userDoc.set({
          'email': user.email,
          'username': user.displayName,
          'photoURL': user.photoURL,
          'created_at': FieldValue.serverTimestamp(),
          'last_login': FieldValue.serverTimestamp(),
        });
      } else {
        // Existing user: update data
        await userDoc.update({
          'email': user.email,
          'username': user.displayName,
          'photoURL': user.photoURL,
          'last_login': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error updating user data: $e");
      }
      throw Exception('Failed to update user data');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print("Error signing out: $e");
      }
      notifyListeners();
    }
  }
}
