import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

class LocationViewModel extends ChangeNotifier {
  final _service = LocationService();

  List<LocationResult> searchResults = [];
  LocationResult? selectedLocation;
  bool isSearching = false;
  String? error;

  Future<void> searchAddress(String query) async {
    if (query.trim().isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }
    isSearching = true;
    error = null;
    notifyListeners();
    try {
      searchResults = await _service.searchAddress(query);
    } catch (_) {
      error = 'Location search failed';
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  void selectLocation(LocationResult result) {
    selectedLocation = result;
    searchResults = [];
    notifyListeners();
  }

  void clearSelection() {
    selectedLocation = null;
    notifyListeners();
  }
}
