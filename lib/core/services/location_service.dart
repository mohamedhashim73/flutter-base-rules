part of 'services.dart';

// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:base/core/services/logging_service.dart';

// class LocationHelper {
//   static Future<(Position, String)> fetch() async {
//     try {
//       final position = await _getCurrentLocation();
//       final locationName = await _getLocationName(position);
//       return (position, locationName);
//     } catch (e) {
//       LoggingService.showMsg('⚠️ Exception in LocationHelper.fetch: $e');
//       rethrow;
//     }
//   }

//   static Future<Position> _getCurrentLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) throw Exception('Location services are disabled.');

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permissions are denied');
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       return Future.error(
//         'Location permissions are permanently denied, cannot request permissions.',
//       );
//     }

//     return await Geolocator.getCurrentPosition(
//       locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
//     );
//   }

//   static Future<String> _getLocationName(Position position) async {
//     try {
//       final placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );

//       if (placemarks.isNotEmpty) {
//         final placemark = placemarks.first;
//         final area = placemark.subLocality ?? '';
//         final city = placemark.locality ?? '';
//         final state = placemark.administrativeArea ?? '';
//         final country = placemark.country ?? '';
//         LoggingService.showMsg(
//           '📍 Area: $area, City: $city, State: $state, Country: $country',
//         );
//         return '📍 Area: $area, City: $city, State: $state, Country: $country';
//       } else {
//         LoggingService.showMsg('❌ No placemarks found.');
//         return '❌ No placemarks found.';
//       }
//     } catch (e) {
//       LoggingService.showMsg('⚠️ Error in reverse geocoding: $e');
//       return 'Error getting location name';
//     }
//   }
// }
