import 'package:geolocator/geolocator.dart';  
import 'package:geocoding/geocoding.dart';  
  
class LocationHelper {  
  static Future<Position> getCurrentPosition() async {  
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();  
    if (!serviceEnabled) {  
      throw Exception('Location services are disabled.');  
    }  
  
    LocationPermission permission = await Geolocator.checkPermission();  
    if (permission == LocationPermission.denied) {  
      permission = await Geolocator.requestPermission();  
      if (permission == LocationPermission.denied) {  
        throw Exception('Location permissions are denied.');  
      }  
    }  
  
    if (permission == LocationPermission.deniedForever) {  
      throw Exception('Location permissions are permanently denied.');  
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