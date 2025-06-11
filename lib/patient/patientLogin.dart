import 'package:flutter/material.dart';
import 'package:medica_test/patient/patientDashboard.dart';
import 'package:medica_test/patient/patientRegister.dart';
import 'package:medica_test/backend/fetchData.dart'; // Import your fetchData.dart file
import 'package:shared_preferences/shared_preferences.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({Key? key}) : super(key: key);

  @override
  _PatientLoginScreenState createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Call the authentication service from fetchData.dart
      final authResult = await AuthService.authenticateUser(
        contact: _idController.text,
        password: _passwordController.text,
      );

      if (authResult != null && authResult['success'] == true) {
        // Login successful - save user data to SharedPreferences
        final userData = authResult['user'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();

        // Store user information
        await prefs.setString(
            'current_user_id', userData['patient_id'].toString());
        await prefs.setString('user_name', userData['name'] ?? '');
        await prefs.setString('user_contact', userData['contact'].toString());
        await prefs.setBool('is_logged_in', true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authResult['message'] ?? 'Login successful!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDashboardScreen(
                userId: userData['patient_id'],
              ),
            ),
          );
        }
      } else {
        // Login failed
        setState(() {
          _errorMessage = authResult?['message'] ?? 'Invalid credentials';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      print('Login error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Login'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or App Name
              Icon(
                Icons.local_hospital,
                size: 80,
                color: Colors.blue.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Mobile Number Field
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.blue.shade600, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.blue.shade600, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Login Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Register Link
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PatientRegisterScreen(),
                          ),
                        );
                      },
                child: Text(
                  'Don\'t have an account? Register',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
