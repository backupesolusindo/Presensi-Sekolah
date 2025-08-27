import 'package:geolocator/geolocator.dart';

class LocationService {
  // Mendapatkan status mock location (menggantikan TrustLocation.isMockLocation)
  static Future<bool> get isMockLocation async {
    try {
      Position position = await getCurrentPosition();
      return position.isMocked;
    } catch (e) {
      print('Error checking mock location: $e');
      return false; // Jika error, anggap bukan mock location
    }
  }

  // Cek apakah location service aktif
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Cek permission lokasi
  static Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request permission lokasi
  static Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  // Mendapatkan posisi saat ini
  static Future<Position> getCurrentPosition() async {
    // Cek apakah location service aktif
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Cek permission
    LocationPermission permission = await checkLocationPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestLocationPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Mendapatkan posisi dengan akurasi tinggi
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    return position;
  }

  // Hitung jarak antara dua koordinat (dalam meter)
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Cek apakah dalam radius yang ditentukan
  static bool isWithinRadius(
    Position currentPosition,
    double targetLatitude,
    double targetLongitude,
    double radiusInMeters,
  ) {
    double distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLatitude,
      targetLongitude,
    );
    
    return distance <= radiusInMeters;
  }
}