import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchDonorPage extends StatefulWidget {
  final String uid; // ✅ Need uid to send request
  const SearchDonorPage({Key? key, required this.uid}) : super(key: key);

  @override
  _SearchDonorPageState createState() => _SearchDonorPageState();
}

class _SearchDonorPageState extends State<SearchDonorPage> {
  late GoogleMapController mapController;
  Position? currentPosition;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    fetchNearbyDonorsAndHospitals();
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentPosition = pos;
      });
    }
  }

  Future<void> fetchNearbyDonorsAndHospitals() async {
    // Fetch nearby donors
    final donorSnapshot = await FirebaseFirestore.instance
        .collection('donors')
        .where('isAvailable', isEqualTo: true) // assuming a field isAvailable
        .get();

    for (var doc in donorSnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('location')) {
        final geoPoint = data['location'];
        _markers.add(
          Marker(
            markerId: MarkerId('donor_${doc.id}'),
            position: LatLng(geoPoint.latitude, geoPoint.longitude),
            infoWindow:
                InfoWindow(title: 'Donor Available', snippet: 'Tap to Request'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    // Fetch hospitals (Assuming you have a 'hospitals' collection)
    final hospitalSnapshot =
        await FirebaseFirestore.instance.collection('hospitals').get();

    for (var doc in hospitalSnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('location')) {
        final geoPoint = data['location'];
        _markers.add(
          Marker(
            markerId: MarkerId('hospital_${doc.id}'),
            position: LatLng(geoPoint.latitude, geoPoint.longitude),
            infoWindow:
                InfoWindow(title: 'Hospital', snippet: data['name'] ?? ''),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    }

    setState(() {});
  }

  void sendBloodRequest() async {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('bloodRequests').add({
        'requestedBy': widget.uid,
        'location':
            GeoPoint(currentPosition!.latitude, currentPosition!.longitude),
        'timestamp': Timestamp.now(),
        'status': 'pending', // pending/accepted/completed
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blood request sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Donor or Hospital'),
        backgroundColor: Colors.red,
      ),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) => mapController = controller,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                        currentPosition!.latitude, currentPosition!.longitude),
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Send Blood Request'),
                          content: const Text(
                              'Do you want to send a blood request to nearby donors?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                sendBloodRequest();
                              },
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Send Blood Request',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
    );
  }
}
