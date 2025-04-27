import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'signup_page.dart'; // import the signup page you just created

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // important for Firebase to work
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Donor App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const SignupPage(), // first page will be signup
    );
  }
}
