import 'package:flutter/material.dart';
import 'package:medica_test/doctor/doctorLogin.dart';
import 'package:medica_test/patient/patientLogin.dart';

class Choose extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Role'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Action for Doctor button
                print('Doctor button pressed');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DoctorLoginScreen()),
                );
              },
              child: Text('Doctor'),
            ),
            SizedBox(height: 20), // Add some space between buttons
            ElevatedButton(
              onPressed: () {
                // Action for Patient button
                print('Patient button pressed');

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PatientLoginScreen()),
                );
              },
              child: Text('Patient'),
            ),
          ],
        ),
      ),
    );
  }
}
