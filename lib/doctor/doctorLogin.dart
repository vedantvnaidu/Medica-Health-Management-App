import 'package:flutter/material.dart';
import 'package:medica_test/doctor/doctorDashboard.dart';
import 'package:medica_test/backend/fetchDoctorData.dart'; // Your auth service
import 'package:shared_preferences/shared_preferences.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({Key? key}) : super(key: key);

  @override
  _DoctorLoginScreenState createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
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
      // Call the doctor authentication service from fetchDoctorData.dart
      final authResult = await DoctorAuthService.authenticateDoctor(
        contact: _idController.text,
        password: _passwordController.text,
      );

      if (authResult != null && authResult['success'] == true) {
        // Login successful - save doctor data to SharedPreferences
        final doctorData = authResult['doctor'] as Map<String, dynamic>;

        // Save all doctor information to SharedPreferences
        await _saveDoctorData(doctorData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authResult['message'] ?? 'Login successful!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to doctor dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(),
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

  // Helper method to save doctor data to SharedPreferences
  Future<void> _saveDoctorData(Map<String, dynamic> doctorData) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Store all doctor information with null safety
      await prefs.setString(
          'current_doctor_id', (doctorData['doctor_id'] ?? 0).toString());
      await prefs.setString('doctor_name', doctorData['name'] ?? 'Dr. Unknown');
      await prefs.setString(
          'doctor_contact', (doctorData['contact'] ?? 0).toString());
      await prefs.setString('doctor_specialization',
          doctorData['specialization'] ?? 'General Practice');

      // Handle rating with proper type conversion
      double rating = 0.0;
      if (doctorData['rating'] != null) {
        if (doctorData['rating'] is int) {
          rating = (doctorData['rating'] as int).toDouble();
        } else if (doctorData['rating'] is double) {
          rating = doctorData['rating'] as double;
        }
      }
      await prefs.setDouble('doctor_rating', rating);

      // Set login status
      await prefs.setBool('is_doctor_logged_in', true);

      print('Doctor data saved successfully: ${doctorData['name']}');
    } catch (e) {
      print('Error saving doctor data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Login'),
        backgroundColor: Colors.teal.shade600,
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
                Icons.medical_services,
                size: 80,
                color: Colors.teal.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                'Doctor Portal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome Back Doctor',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
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
                        BorderSide(color: Colors.teal.shade600, width: 2),
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
                        BorderSide(color: Colors.teal.shade600, width: 2),
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
                    backgroundColor: Colors.teal.shade600,
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

              // Forgot Password Link
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        // TODO: Implement forgot password functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Forgot password feature coming soon!'),
                          ),
                        );
                      },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.teal.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Footer text
              Text(
                'Secure Doctor Portal\nYour credentials are encrypted and protected',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
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
