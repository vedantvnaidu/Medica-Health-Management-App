import 'package:flutter/material.dart';
import 'package:medica_test/backend/putData.dart'; // Import the backend file

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({Key? key}) : super(key: key);

  @override
  _PatientRegisterScreenState createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _showPassword = false;
  bool _showConfirm = false;

  // Gender dropdown state with integer mapping
  // Other(-1), Female(0), Male(1)
  final Map<String, int> _genderMap = {
    'Other': -1,
    'Female': 0,
    'Male': 1,
  };
  String _selectedGender = 'Other';

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Convert string gender selection to integer value
      final genderValue = _genderMap[_selectedGender]!;
      print('Selected gender: $_selectedGender (value: $genderValue)');

      // Call the registerPatient function from putData.dart
      final result = await registerPatient(
        password: _passwordController.text,
        name: _nameController.text,
        dob: _dobController.text,
        age: int.parse(_ageController.text),
        gender: genderValue,
        contact: _contactController.text,
        address: _addressController.text,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Registered with Patient ID: ${result['patient_id']}')),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Failed to register. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to register. Please try again. Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = picked.toIso8601String().split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Select DOB' : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter age';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Invalid age';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: _genderMap.keys.map((g) {
                  return DropdownMenuItem(value: g, child: Text(g));
                }).toList(),
                onChanged: (val) => setState(() {
                  _selectedGender = val!;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter contact' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 12),
              // Password fields at bottom
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                obscureText: !_showPassword,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
                obscureText: !_showConfirm,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirm password';
                  if (v != _passwordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register'),
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
    _nameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
