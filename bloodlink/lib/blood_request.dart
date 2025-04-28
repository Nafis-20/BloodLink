import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BloodRequestPage extends StatefulWidget {
  @override
  _BloodRequestPageState createState() => _BloodRequestPageState();
}

class _BloodRequestPageState extends State<BloodRequestPage> {
  Position? _currentPosition;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _fetchBloodRequests();
  }

  Future<void> _loadCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.requestPermission();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _createBloodRequest() async {
    if (_currentPosition == null) return;

    await FirebaseFirestore.instance.collection('bloodRequests').add({
      'requestedBy': 'UserID123', // Replace with your real user ID
      'latitude': _currentPosition!.latitude,
      'longitude': _currentPosition!.longitude,
      'timestamp': Timestamp.now(),
      'status': 'pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Blood request created!')),
    );

    _fetchBloodRequests();
  }

  Future<void> _fetchBloodRequests() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bloodRequests')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> tempRequests = [];

    Set<Marker> tempMarkers = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      double lat = data['latitude'];
      double lng = data['longitude'];

      String address = await _getAddressFromLatLng(lat, lng);

      double distanceKm = _currentPosition != null
          ? Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                lat,
                lng,
              ) /
              1000
          : 0.0;

      tempRequests.add({
        'id': doc.id,
        'requestedBy': data['requestedBy'],
        'latitude': lat,
        'longitude': lng,
        'timestamp': data['timestamp'],
        'status': data['status'],
        'address': address,
        'distance': distanceKm,
      });

      tempMarkers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: "Blood Request",
            snippet: address,
          ),
        ),
      );
    }

    setState(() {
      _requests = tempRequests;
      _markers = tempMarkers;
    });
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      Placemark place = placemarks.first;
      return "${place.street}, ${place.locality}, ${place.country}";
    } catch (e) {
      return "Unknown Location";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Requests'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_location),
            onPressed: _createBloodRequest,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: _currentPosition == null
                ? Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 12,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  ),
          ),
          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                var request = _requests[index];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.bloodtype, color: Colors.red),
                    title: Text("Requested by: ${request['requestedBy']}"),
                    subtitle: Text("${request['address']}\n"
                        "Distance: ${request['distance'].toStringAsFixed(2)} km"),
                    trailing: Text(
                      "${request['status']}",
                      style: TextStyle(
                        color: request['status'] == 'pending'
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
