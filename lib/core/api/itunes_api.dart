import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/track_model.dart';

class ITunesApi {
  static final ITunesApi _instance = ITunesApi._internal();
  factory ITunesApi() => _instance;
  ITunesApi._internal();

  final http.Client _client = http.Client();

  /// Map iTunes item to TrackModel
  TrackModel _mapITunesTrack(Map<String, dynamic> item) {
    final trackId = item['trackId']?.toString() ?? UniqueKey().toString();
    final trackName = item['trackName'] ?? 'Unknown Track';
    final artistName = item['artistName'] ?? 'Various Artists';
    final collectionName = item['collectionName'] ?? 'Single';
    final artistId = item['artistId']?.toString() ?? '';
    final collectionId = item['collectionId']?.toString() ?? '';
    final durationMs = item['trackTimeMillis'] as int? ?? 180000;
    final previewUrl = item['previewUrl']?.toString() ?? '';
    final genre = item['primaryGenreName']?.toString() ?? 'Music';

    String rawArtwork = item['artworkUrl100'] ??
        item['artworkUrl60'] ??
        'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop';

    // Upgrade resolution to 600x600
    final highResArtwork = rawArtwork.replaceAll('100x100bb', '600x600bb').replaceAll('60x60bb', '600x600bb');

    return TrackModel(
      id: 'it_$trackId',
      name: trackName,
      duration: (durationMs / 1000).round(),
      artistId: 'it_art_$artistId',
      artistName: artistName,
      albumName: collectionName,
      albumId: 'it_alb_$collectionId',
      albumImage: highResArtwork,
      audioUrl: previewUrl,
      tags: [genre.toLowerCase(), 'popular', 'hit'],
      source: 'spotify',
    );
  }

  /// Search tracks with high precision across global and Indian/regional music libraries
  Future<List<TrackModel>> searchTracks({
    required String query,
    int limit = 100,
    int offset = 0,
    LanguageOption? language,
  }) async {
    final langTag = language?.searchTag;
    final effectiveQuery = (langTag != null && langTag.isNotEmpty)
        ? (query.toLowerCase().contains(langTag.toLowerCase()) ? query : '$query $langTag')
        : query;

    final effectiveLimit = limit.clamp(1, 200);

    final uri = Uri.parse(
      'https://itunes.apple.com/search'
      '?term=${Uri.encodeComponent(effectiveQuery)}'
      '&entity=song'
      '&limit=$effectiveLimit'
      '&offset=$offset',
    );

    debugPrint('🔍 [ITunesApi] High-Precision Search: $uri');

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        final tracks = results.map((item) => _mapITunesTrack(item as Map<String, dynamic>)).toList();
        debugPrint('✅ [ITunesApi] Found ${tracks.length} exact matching tracks for "$effectiveQuery"');
        return tracks;
      }
    } catch (e) {
      debugPrint('❌ [ITunesApi] searchTracks error: $e');
    }
    return [];
  }

  /// Fetch tracks specifically tailored for a genre / mood filter
  Future<List<TrackModel>> getTracksByGenre({
    required String genre,
    int limit = 100,
    int offset = 0,
    LanguageOption? language,
  }) async {
    final langTag = language?.searchTag;
    final query = (genre.toLowerCase() == 'all')
        ? ((langTag != null && langTag.isNotEmpty) ? '$langTag top hits' : 'top hits')
        : ((langTag != null && langTag.isNotEmpty)
            ? '$genre $langTag hits'
            : '$genre hits best');

    return searchTracks(
      query: query,
      limit: limit,
      offset: offset,
      language: language,
    );
  }
}
