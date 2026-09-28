import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track_model.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _favStorageKey = 'user_favorite_tracks_v1';
  List<TrackModel> _favorites = [];
  bool _isLoaded = false;

  List<TrackModel> get favorites => _favorites;
  bool get isLoaded => _isLoaded;
  int get count => _favorites.length;

  FavoritesProvider() {
    loadFavorites();
  }

  /// Load persisted favorites from SharedPreferences
  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_favStorageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List decoded = json.decode(jsonString);
        _favorites = decoded.map((item) => TrackModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _favorites = [];
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Check if track is marked as favorite
  bool isFavorite(String trackId) {
    return _favorites.any((track) => track.id == trackId);
  }

  /// Toggle Favorite status
  Future<void> toggleFavorite(TrackModel track) async {
    final index = _favorites.indexWhere((t) => t.id == track.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.insert(0, track);
    }
    notifyListeners();
    await _saveFavorites();
  }

  /// Add to favorites
  Future<void> addFavorite(TrackModel track) async {
    if (!isFavorite(track.id)) {
      _favorites.insert(0, track);
      notifyListeners();
      await _saveFavorites();
    }
  }

  /// Remove from favorites
  Future<void> removeFavorite(String trackId) async {
    _favorites.removeWhere((track) => track.id == trackId);
    notifyListeners();
    await _saveFavorites();
  }

  /// Clear all favorites
  Future<void> clearAll() async {
    _favorites.clear();
    notifyListeners();
    await _saveFavorites();
  }

  /// Persist to local storage
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(_favorites.map((t) => t.toJson()).toList());
      await prefs.setString(_favStorageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }
}
