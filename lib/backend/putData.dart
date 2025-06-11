import 'package:supabase_flutter/supabase_flutter.dart';

// Get a reference to the Supabase client
final supabase = Supabase.instance.client;

// Function to register a new patient in Supabase
// Gender values: Other(-1), Female(0), Male(1)
Future<Map<String, dynamic>> registerPatient({
  required String password,
  required String name,
  required String dob,
  required int age,
  required int gender, // Integer value: -1 (Other), 0 (Female), 1 (Male)
  required String contact,
  required String address,
}) async {
  try {
    // Insert data into patients table
    final response = await supabase
        .from('Patients')
        .insert({
          'password': password,
          'name': name,
          'dob': dob,
          'age': age,
          'gender': gender,
          'contact': contact,
          'address': address,
        })
        .select('patient_id')
        .single();

    // Return success with the new patient ID
    return {
      'success': true,
      'patient_id': response['patient_id'],
      'message': 'Patient registered successfully'
    };
  } catch (e) {
    // Return error information
    return {
      'success': false,
      'message': 'Failed to register patient: ${e.toString()}',
    };
  }
}
