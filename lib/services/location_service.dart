import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class LocationResult {
  final String address;
  final double lat;
  final double lng;

  LocationResult({required this.address, required this.lat, required this.lng});
}

/// TomTom Fuzzy Search — biased toward VVU campus area, Ghana
class LocationService {
  Future<List<LocationResult>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      'https://api.tomtom.com/search/2/search/${Uri.encodeComponent(query)}.json'
      '?key=${AppConstants.tomTomApiKey}'
      '&limit=5'
      '&lat=${AppConstants.campusLat}'
      '&lon=${AppConstants.campusLng}'
      '&radius=20000'
      '&countrySet=GH',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List? ?? [];

    return results.map((r) {
      final pos = r['position'] as Map;
      final address = r['address'] as Map;
      final label = address['freeformAddress'] ??
          (r['poi'] as Map?)?['name'] ??
          query;
      return LocationResult(
        address: label as String,
        lat: (pos['lat'] as num).toDouble(),
        lng: (pos['lon'] as num).toDouble(),
      );
    }).toList();
  }
}
