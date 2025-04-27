import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class LandingPage extends StatefulWidget {
  final String uid;
  const LandingPage(this.uid, {Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String userName = "";

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  void fetchUserName() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();
    setState(() {
      userName = doc['name'] ?? 'User';
    });
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          )
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, $userName!',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
