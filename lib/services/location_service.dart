import '../core/api_client.dart';

class LocationResult {
  final String address;
  final double lat;
  final double lng;

  LocationResult({required this.address, required this.lat, required this.lng});

  factory LocationResult.fromJson(Map<String, dynamic> json) => LocationResult(
        address: json['address'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}

/// Address search. The backend proxies TomTom so the API key
/// stays server-side (TOMTOM_API_KEY env var).
class LocationService {
  Future<List<LocationResult>> searchAddress(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      final data = await ApiClient.get(
        '/api/location/search?q=${Uri.encodeQueryComponent(q)}',
      );
      if (data is Map && data['results'] is List) {
        return (data['results'] as List)
            .whereType<Map>()
            .map((m) => LocationResult.fromJson(
                  Map<String, dynamic>.from(m),
                ))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
