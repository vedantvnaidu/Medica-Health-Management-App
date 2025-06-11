import 'package:flutter/material.dart';
import 'package:medica_test/choose.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase instance
  await Supabase.initialize(
    url: 'https://akyctnbgjawqmpmmppgh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFreWN0bmJnamF3cW1wbW1wcGdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc3NjM3NzUsImV4cCI6MjA2MzMzOTc3NX0.y1qXEgx9MEEyqIPCfxZmNHQQzvrSqA2PJOlZyXa-J_k',
    debug: true, // set to false in production
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: Choose(),
    );
  }
}
