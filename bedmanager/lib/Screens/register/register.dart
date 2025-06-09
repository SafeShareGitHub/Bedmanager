// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  // Registration Screen Widget
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Form key to manage form state
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture user input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Loading state
  bool _isLoading = false;

  // Function to handle user registration
  Future<void> _register() async {
    print("Registration initiated");
    // Validate form fields
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      print("Form validated successfully");

      try {
        print(
            "Attempting to create user with email: ${_emailController.text.trim()}");
        // Create user with email and password
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print("User created successfully: ${userCredential.user?.uid}");

        // Registration successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Successful!')),
        );

        // Optionally, navigate to the login screen after registration
        Navigator.pop(context); // Navigate back to login
      } on FirebaseAuthException catch (e) {
        print("FirebaseAuthException caught: ${e.code} - ${e.message}");
        String errorMessage = 'An error occurred. Please try again.';

        // Customize error messages based on error codes
        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already in use.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is invalid.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'The password is too weak.';
        }

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        print("Unexpected error caught: $e");
        // Handle other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred.')),
        );
      } finally {
        // Reset loading state
        setState(() {
          _isLoading = false;
        });
        print("Loading state set to false");
      }
    } else {
      print("Form validation failed");
    }
  }

  @override
  void dispose() {
    // Dispose controllers when not needed
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
    print("Controllers disposed");
  }

  @override
  Widget build(BuildContext context) {
    // Build the registration form
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, // Assign form key
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Email Input Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    // Basic email validation
                    if (value == null || value.isEmpty) {
                      print("Email field is empty");
                      return 'Please enter your email.';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      print("Invalid email format: $value");
                      return 'Please enter a valid email.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),

                // Password Input Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password (min 6 characters)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true, // Hide password input
                  validator: (value) {
                    // Basic password validation
                    if (value == null || value.isEmpty) {
                      print("Password field is empty");
                      return 'Please enter your password.';
                    }
                    if (value.length < 6) {
                      print("Password too short: ${value.length} characters");
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.0),

                // Register Button
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        child: Text('Register'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50), // Full-width
                        ),
                      ),

                SizedBox(height: 16.0),

                // Navigate to Login Screen
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Navigate back to login
                  },
                  child: Text("Already have an account? Login here."),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
