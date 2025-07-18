import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

enum AuthMode { signUp, login }

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthMode _authMode = AuthMode.login;
  final Map<String, String> _authData = {
    'email': '',
    'password': '',
  };
  bool _isLoading = false;
  final _passwordController = TextEditingController(); // For password confirmation

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    if (!mounted) return; // Ensure widget is still in the tree
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('An Error Occurred!'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      if (_authMode == AuthMode.login) {
        // Log user in
        await _auth.signInWithEmailAndPassword(
          email: _authData['email']!,
          password: _authData['password']!,
        );
      } else {
        // Sign user up
        await _auth.createUserWithEmailAndPassword(
          email: _authData['email']!,
          password: _authData['password']!,
        );
        // Optionally, send email verification after sign up
        User? user = _auth.currentUser;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification email sent to ${user.email}. Please check your inbox.')),
            );
          }
        }
      }
      // Navigation to home screen will be handled by the StreamBuilder in main.dart
      // If sign up was successful and you're not automatically navigating,
      // you might want to switch to login mode or show a success message.
      if (_authMode == AuthMode.signUp && mounted) {
        // Optionally switch to login mode after successful signup
        // _switchAuthMode();
        // Or just let the StreamBuilder handle navigation
      }

    } on FirebaseAuthException catch (error) {
      var errorMessage = 'Authentication failed. Please try again later.';
      // You can customize messages based on error.code
      // e.g., 'weak-password', 'email-already-in-use', 'user-not-found', 'wrong-password'
      print('FirebaseAuthException: ${error.code} - ${error.message}');
      if (error.message != null) {
        errorMessage = error.message!;
      }
      _showErrorDialog(errorMessage);
    } catch (error) {
      print('Generic Error: $error');
      const errorMessage =
          'Could not authenticate you. Please try again later.';
      _showErrorDialog(errorMessage);
    }

    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.login) {
      setState(() {
        _authMode = AuthMode.signUp;
      });
    } else {
      setState(() {
        _authMode = AuthMode.login;
      });
    }
    _formKey.currentState?.reset(); // Reset form when switching modes
    _passwordController.clear(); // Clear password for confirmation
    if (mounted) {
      setState(() {}); // Ensure UI updates after form reset
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView( // To avoid overflow when keyboard appears
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Make children take full width
            children: <Widget>[
              // Replace with your App Logo or Title
              FlutterLogo(size: 80, textColor: Theme.of(context).primaryColor),
              const SizedBox(height: 20),
              Text(
                _authMode == AuthMode.login ? 'Welcome Back!' : 'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Take up only necessary space
                  children: <Widget>[
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'E-Mail'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Invalid email!';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _authData['email'] = value!;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      controller: _passwordController, // Used for confirm password
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 6) {
                          return 'Password is too short! (Min. 6 characters)';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _authData['password'] = value!;
                      },
                    ),
                    if (_authMode == AuthMode.signUp) // Only show if signing up
                      const SizedBox(height: 12),
                    if (_authMode == AuthMode.signUp)
                      TextFormField(
                        enabled: _authMode == AuthMode.signUp,
                        decoration: const InputDecoration(labelText: 'Confirm Password'),
                        obscureText: true,
                        validator: _authMode == AuthMode.signUp
                            ? (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match!';
                          }
                          return null;
                        }
                            : null,
                      ),
                    const SizedBox(height: 25),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _submit,
                        child: Text(_authMode == AuthMode.login ? 'LOGIN' : 'SIGN UP'),
                      ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _switchAuthMode,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: Text(
                          '${_authMode == AuthMode.login ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
