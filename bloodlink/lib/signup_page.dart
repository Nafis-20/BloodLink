import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dobController = TextEditingController();

  String? _name, _email, _phone, _nidPassport, _password;
  String _bloodGroup = "A+"; // default value
  String _division = "Dhaka"; // default value

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // Add user to Firestore under 'users' collection
        await FirebaseFirestore.instance.collection('users').add({
          'name': _name,
          'email': _email,
          'phone': _phone,
          'dob': _dobController.text,
          'nid_passport': _nidPassport,
          'blood_group': _bloodGroup,
          'division': _division,
          'is_donor': true, // Assume donor for now
          'last_donation': '',
          'location': '', // can be added later
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Create Account",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter your name" : null,
                onSaved: (value) => _name = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@')
                    ? "Enter a valid email"
                    : null,
                onSaved: (value) => _email = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.length < 10
                    ? "Enter valid number"
                    : null,
                onSaved: (value) => _phone = value,
              ),
              TextFormField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: "Date of Birth",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) => value == null || value.isEmpty
                    ? "Select date of birth"
                    : null,
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: "NID or Passport Number"),
                validator: (value) =>
                    value == null || value.length < 6 ? "Enter valid ID" : null,
                onSaved: (value) => _nidPassport = value,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Blood Group"),
                value: _bloodGroup,
                items: ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
                    .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _bloodGroup = value!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Division"),
                value: _division,
                items: [
                  "Dhaka",
                  "Chittagong",
                  "Khulna",
                  "Rajshahi",
                  "Sylhet",
                  "Barisal",
                  "Rangpur",
                  "Mymensingh"
                ]
                    .map(
                        (div) => DropdownMenuItem(value: div, child: Text(div)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _division = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
