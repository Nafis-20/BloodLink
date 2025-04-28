import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

Future<void> updateUserLocation(String uid) async {
  try {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are denied');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Update user location in "users" collection
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
    });

    // If user is a donor, also update location in "donors" collection
    final donorDoc =
        await FirebaseFirestore.instance.collection('donors').doc(uid).get();
    if (donorDoc.exists) {
      await FirebaseFirestore.instance.collection('donors').doc(uid).update({
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      });
    }
  } catch (e) {
    print('Error updating location: $e');
  }
}
