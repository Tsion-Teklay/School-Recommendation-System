import 'package:geolocator/geolocator.dart';  
import 'package:geocoding/geocoding.dart';  

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}

class LocationHelper {  
  static Future<Position> getCurrentPosition() async {  
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();  
    if (!serviceEnabled) {  
      throw LocationException('Please enable location services in your device settings to use this feature.');  
    }  
  
    LocationPermission permission = await Geolocator.checkPermission();  
    if (permission == LocationPermission.denied) {  
      permission = await Geolocator.requestPermission();  
      if (permission == LocationPermission.denied) {  
        throw LocationException('Location permission is required to use this feature. Please grant permission in your device settings.');  
      }  
    }  
  
    if (permission == LocationPermission.deniedForever) {  
      throw LocationException('Location permission is permanently denied. Please enable it in your device settings to use this feature.');  
    }  
  
    return await Geolocator.getCurrentPosition(  
      desiredAccuracy: LocationAccuracy.high,  
    );  
  }  
  
  static Future<String> getAddressFromCoordinates(double lat, double lng) async {  
    try {  
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);  
      Placemark place = placemarks[0];  
      return '${place.street}, ${place.locality}, ${place.country}';  
    } catch (e) {  
      return 'Unknown location';  
    }  
  }  
}