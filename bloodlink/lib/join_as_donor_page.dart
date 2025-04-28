import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // ✅ added
import 'landing_page.dart';

class JoinAsDonorPage extends StatefulWidget {
  final String uid;
  const JoinAsDonorPage({Key? key, required this.uid}) : super(key: key);

  @override
  _JoinAsDonorPageState createState() => _JoinAsDonorPageState();
}

class _JoinAsDonorPageState extends State<JoinAsDonorPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedBloodGroup;
  DateTime? selectedDate;
  final TextEditingController weightController = TextEditingController();
  final TextEditingController healthIssuesController = TextEditingController();

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  bool isLoading = false;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    getCurrentLocation(); // ✅ fetch location at start
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied')),
      );
      return;
    }

    // Get current location
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentPosition = position;
    });
  }

  void registerDonor() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select last donation date')),
      );
      return;
    }
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to fetch location')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final donorData = {
      'bloodGroup': selectedBloodGroup,
      'lastDonationDate': selectedDate,
      'weight': int.parse(weightController.text),
      'healthIssues': healthIssuesController.text,
      'userId': widget.uid,
      'registeredAt': Timestamp.now(),
      'location': {
        'latitude': currentPosition!.latitude,
        'longitude': currentPosition!.longitude,
      }, // ✅ added location
    };

    try {
      // Save donor info
      await FirebaseFirestore.instance
          .collection('donors')
          .doc(widget.uid)
          .set(donorData);

      // Update user role
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({
        'role': 'donor',
        'location': {
          'latitude': currentPosition!.latitude,
          'longitude': currentPosition!.longitude,
        }, // ✅ update user location also if needed
      });

      setState(() {
        isLoading = false;
      });

      // Show success popup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: const Text('You have registered as a donor.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LandingPage(widget.uid)),
                  (route) => false,
                );
              },
              child: const Text('OK'),
            )
          ],
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as Donor'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedBloodGroup,
                      items: bloodGroups.map((blood) {
                        return DropdownMenuItem(
                          value: blood,
                          child: Text(blood),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedBloodGroup = val;
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Please select a blood group' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: selectedDate == null
                            ? 'Last Donation Date'
                            : 'Last Donation: ${selectedDate!.toLocal()}'
                                .split(' ')[0],
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: pickDate,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Please enter weight';
                        final weight = int.tryParse(val);
                        if (weight == null || weight < 30)
                          return 'Invalid weight';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: healthIssuesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Any health issues?',
                        hintText: 'Type "None" if no issues',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please mention any health issue'
                          : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: registerDonor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Register',
                          style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 10),
                    currentPosition != null
                        ? Text(
                            "Location captured: (${currentPosition!.latitude.toStringAsFixed(4)}, ${currentPosition!.longitude.toStringAsFixed(4)})",
                            textAlign: TextAlign.center,
                          )
                        : const Center(
                            child: Text('Fetching location...'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
