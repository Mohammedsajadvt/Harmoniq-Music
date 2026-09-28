import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/track_model.dart';

class EpidemicSoundApi {
  static final EpidemicSoundApi _instance = EpidemicSoundApi._internal();
  factory EpidemicSoundApi() => _instance;
  EpidemicSoundApi._internal();

  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${ApiConstants.epidemicApiKey}',
        'x-partner-user-id': ApiConstants.epidemicPartnerUserId,
        'Content-Type': 'application/json',
      };

  /// Map Epidemic Sound JSON item to TrackModel
  TrackModel _mapEpidemicTrack(Map<String, dynamic> item) {
    final images = item['images'] as Map<String, dynamic>? ?? {};
    final mainArtists = item['mainArtists'] as List? ?? [];
    final moods = item['moods'] as List? ?? [];
    final genres = item['genres'] as List? ?? [];

    String imageUrl = images['M'] ??
        images['default'] ??
        images['S'] ??
        'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop';

    final artistName = mainArtists.isNotEmpty ? mainArtists.join(', ') : 'Epidemic Artist';
    final rawId = item['id']?.toString() ?? UniqueKey().toString();

    List<String> tags = ['epidemicsound', 'royalty-free'];
    for (var m in moods) {
      if (m is Map && m['name'] != null) tags.add(m['name'].toString().toLowerCase());
    }
    for (var g in genres) {
      if (g is Map && g['name'] != null) tags.add(g['name'].toString().toLowerCase());
    }

    final length = item['length'] as int? ?? 120;

    return TrackModel(
      id: 'es_$rawId',
      name: item['title'] ?? 'Epidemic Sound Track',
      duration: length,
      artistId: 'es_art_${artistName.hashCode}',
      artistName: artistName,
      albumName: 'Epidemic Sound Collection',
      albumId: 'es_album_royaltyfree',
      albumImage: imageUrl,
      audioUrl: '', // Resolved dynamically via /v0/tracks/{id}/download
      tags: tags,
      source: 'epidemicsound',
    );
  }

  /// Fetch trending / popular tracks from Epidemic Sound (Supports unlimited multi-page pagination)
  Future<List<TrackModel>> getTrendingTracks({int limit = 100, int offset = 0}) async {
    List<TrackModel> allTracks = [];
    int currentOffset = offset;
    int remaining = limit;

    while (remaining > 0) {
      final batchLimit = remaining.clamp(1, 100);
      final uri = Uri.parse('${ApiConstants.epidemicBaseUrl}/v0/tracks?limit=$batchLimit&offset=$currentOffset');
      debugPrint('🟢 [EpidemicSoundApi] GET Tracks: $uri');

      try {
        final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List items = data['tracks'] ?? [];
          if (items.isEmpty) break;

          final batch = items.map((item) => _mapEpidemicTrack(item as Map<String, dynamic>)).toList();
          allTracks.addAll(batch);
          currentOffset += items.length;
          remaining -= items.length;

          if (items.length < batchLimit) break;
        } else {
          break;
        }
      } catch (e) {
        debugPrint('❌ [EpidemicSoundApi] getTrendingTracks error: $e');
        break;
      }
    }

    debugPrint('✅ [EpidemicSoundApi] Total loaded: ${allTracks.length} tracks (starting offset: $offset)');
    return allTracks;
  }

  /// Search tracks on Epidemic Sound (Multi-page batch fetching)
  Future<List<TrackModel>> searchTracks({required String query, int limit = 100, int offset = 0}) async {
    List<TrackModel> allTracks = [];
    int currentOffset = offset;
    int remaining = limit;

    while (remaining > 0) {
      final batchLimit = remaining.clamp(1, 100);
      final uri = Uri.parse(
        '${ApiConstants.epidemicBaseUrl}/v0/tracks/search?term=${Uri.encodeComponent(query)}&limit=$batchLimit&offset=$currentOffset',
      );
      debugPrint('🔍 [EpidemicSoundApi] Search: $uri');

      try {
        final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List items = data['tracks'] ?? [];
          if (items.isEmpty) break;

          final batch = items.map((item) => _mapEpidemicTrack(item as Map<String, dynamic>)).toList();
          allTracks.addAll(batch);
          currentOffset += items.length;
          remaining -= items.length;

          if (items.length < batchLimit) break;
        } else {
          break;
        }
      } catch (e) {
        debugPrint('❌ [EpidemicSoundApi] searchTracks error: $e');
        break;
      }
    }

    debugPrint('✅ [EpidemicSoundApi] Search "$query" total: ${allTracks.length} tracks');
    return allTracks;
  }

  /// Fetch tracks by genre / mood on Epidemic Sound
  Future<List<TrackModel>> getTracksByGenre({required String genre, int limit = 100, int offset = 0}) async {
    if (genre.toLowerCase() == 'all') {
      return getTrendingTracks(limit: limit, offset: offset);
    }
    return searchTracks(query: genre, limit: limit, offset: offset);
  }

  /// Get direct MP3 streaming URL for an Epidemic Sound track
  Future<String> getTrackAudioUrl(String trackId) async {
    final rawId = trackId.startsWith('es_') ? trackId.substring(3) : trackId;
    try {
      final uri = Uri.parse('${ApiConstants.epidemicBaseUrl}/v0/tracks/$rawId/download');
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final url = data['url']?.toString() ?? '';
        if (url.isNotEmpty) {
          debugPrint('🎵 [EpidemicSoundApi] Resolved live stream audio URL');
          return url;
        }
      }
    } catch (e) {
      debugPrint('❌ [EpidemicSoundApi] getTrackAudioUrl error: $e');
    }
    return '';
  }
}
