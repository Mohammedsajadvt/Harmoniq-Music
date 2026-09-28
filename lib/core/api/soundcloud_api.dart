import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/track_model.dart';

class SoundCloudApi {
  static final SoundCloudApi _instance = SoundCloudApi._internal();
  factory SoundCloudApi() => _instance;
  SoundCloudApi._internal();

  final http.Client _client = http.Client();
  int _currentClientIdIndex = 0;

  String get _activeClientId {
    const list = ApiConstants.soundCloudFallbackClientIds;
    if (_currentClientIdIndex >= list.length) {
      _currentClientIdIndex = 0;
    }
    return list[_currentClientIdIndex];
  }

  void _rotateClientId() {
    _currentClientIdIndex = (_currentClientIdIndex + 1) % ApiConstants.soundCloudFallbackClientIds.length;
    debugPrint('🔄 [SoundCloudApi] Rotated client ID to index $_currentClientIdIndex');
  }

  /// Search tracks on SoundCloud
  Future<List<TrackModel>> searchTracks({
    required String query,
    int limit = 20,
    LanguageOption? language,
  }) async {
    final searchQuery = (language != null && language.searchTag != null && language.searchTag!.isNotEmpty)
        ? '$query ${language.searchTag}'
        : query;

    final url = Uri.parse(
      '${ApiConstants.soundCloudV2BaseUrl}/search/tracks'
      '?q=${Uri.encodeComponent(searchQuery)}'
      '&client_id=$_activeClientId'
      '&limit=$limit'
      '&offset=0',
    );

    debugPrint('🔍 [SoundCloudApi] GET: $url');

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List collection = data['collection'] ?? [];
        final tracks = collection
            .where((item) => item is Map<String, dynamic> && item['streamable'] != false)
            .map((item) => _mapSoundCloudTrack(item as Map<String, dynamic>))
            .where((track) => track.audioUrl.isNotEmpty)
            .toList();

        debugPrint('✅ [SoundCloudApi] Found ${tracks.length} tracks for "$query"');
        return tracks;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _rotateClientId();
      }
    } catch (e) {
      debugPrint('❌ [SoundCloudApi] Search error: $e');
    }

    return [];
  }

  /// Get Trending / Charts from SoundCloud
  Future<List<TrackModel>> getTrendingTracks({
    int limit = 20,
    LanguageOption? language,
  }) async {
    String genre = 'soundcloud:genres:all-music';
    if (language != null && language.searchTag != null && language.searchTag!.isNotEmpty) {
      // If language specified, search top tracks for that language
      return searchTracks(query: language.searchTag!, limit: limit);
    }

    final url = Uri.parse(
      '${ApiConstants.soundCloudV2BaseUrl}/charts'
      '?kind=top'
      '&genre=${Uri.encodeComponent(genre)}'
      '&client_id=$_activeClientId'
      '&limit=$limit'
      '&offset=0',
    );

    debugPrint('🔥 [SoundCloudApi] GET Charts: $url');

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List collection = data['collection'] ?? [];
        final tracks = <TrackModel>[];

        for (final item in collection) {
          if (item is Map<String, dynamic> && item['track'] is Map<String, dynamic>) {
            final trackData = item['track'] as Map<String, dynamic>;
            final mapped = _mapSoundCloudTrack(trackData);
            if (mapped.audioUrl.isNotEmpty) {
              tracks.add(mapped);
            }
          }
        }

        debugPrint('✅ [SoundCloudApi] Loaded ${tracks.length} trending chart tracks');
        return tracks;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _rotateClientId();
      }
    } catch (e) {
      debugPrint('❌ [SoundCloudApi] Trending error: $e');
    }

    // Fallback to searching popular EDM/Pop tracks on SoundCloud
    return searchTracks(query: 'Trending Hits 2026', limit: limit);
  }

  /// Get tracks by Genre on SoundCloud
  Future<List<TrackModel>> getTracksByGenre({
    required String genre,
    int limit = 20,
    LanguageOption? language,
  }) async {
    if (genre.toLowerCase() == 'all') {
      return getTrendingTracks(limit: limit, language: language);
    }

    return searchTracks(query: genre, limit: limit, language: language);
  }

  /// Resolve progressive stream URL if needed
  Future<String> resolveStreamUrl(TrackModel track) async {
    if (track.audioUrl.startsWith('http') && !track.audioUrl.contains('api-v2.soundcloud.com/media')) {
      return track.audioUrl;
    }

    try {
      final transcodeUrl = Uri.parse('${track.audioUrl}?client_id=$_activeClientId');
      final response = await _client.get(transcodeUrl).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['url'] != null) {
          return data['url'] as String;
        }
      }
    } catch (e) {
      debugPrint('❌ [SoundCloudApi] Stream resolve error: $e');
    }

    return track.audioUrl;
  }

  /// Map SoundCloud JSON to TrackModel
  TrackModel _mapSoundCloudTrack(Map<String, dynamic> item) {
    final user = item['user'] as Map<String, dynamic>? ?? {};
    final String artistName = user['username'] ?? 'SoundCloud Artist';
    final String artistId = user['id']?.toString() ?? '';

    // Artwork: replace -large with -t500x500 for HD cover art
    String artworkUrl = item['artwork_url'] ?? user['avatar_url'] ?? '';
    if (artworkUrl.isNotEmpty && artworkUrl.contains('-large.')) {
      artworkUrl = artworkUrl.replaceAll('-large.', '-t500x500.');
    } else if (artworkUrl.isEmpty) {
      artworkUrl = 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop';
    }

    // Direct Audio Stream URL extraction
    String audioUrl = '';
    final media = item['media'] as Map<String, dynamic>?;
    if (media != null && media['transcodings'] is List) {
      final transcodings = media['transcodings'] as List;
      // Prefer progressive mp3 transcoding
      for (final t in transcodings) {
        if (t is Map<String, dynamic> && t['format'] is Map) {
          final protocol = t['format']['protocol'];
          if (protocol == 'progressive' && t['url'] != null) {
            audioUrl = t['url'];
            break;
          }
        }
      }
      // If no progressive found, pick the first available transcoding
      if (audioUrl.isEmpty && transcodings.isNotEmpty) {
        audioUrl = transcodings.first['url'] ?? '';
      }
    }

    if (audioUrl.isEmpty && item['stream_url'] != null) {
      audioUrl = '${item['stream_url']}?client_id=$_activeClientId';
    }

    // Duration: SoundCloud gives milliseconds
    final int durationMs = item['duration'] is int
        ? item['duration']
        : (int.tryParse(item['duration']?.toString() ?? '0') ?? 0);
    final int durationSec = durationMs > 0 ? (durationMs ~/ 1000) : 180;

    // Tags
    final List<String> tags = [];
    if (item['genre'] != null && item['genre'].toString().isNotEmpty) {
      tags.add(item['genre'].toString());
    }
    if (item['tag_list'] != null && item['tag_list'].toString().isNotEmpty) {
      tags.addAll(item['tag_list'].toString().split(' ').take(3));
    }

    return TrackModel(
      id: 'sc_${item['id'] ?? DateTime.now().millisecondsSinceEpoch}',
      name: item['title'] ?? 'SoundCloud Track',
      duration: durationSec,
      artistId: artistId,
      artistName: artistName,
      albumName: item['genre'] ?? 'SoundCloud Stream',
      albumId: 'sc_album_${item['id']}',
      albumImage: artworkUrl,
      audioUrl: audioUrl,
      audioDownloadUrl: item['downloadable'] == true ? item['download_url'] : null,
      releaseDate: item['created_at']?.toString().split('T').first,
      shareUrl: item['permalink_url'],
      licenseUrl: item['license'],
      tags: tags,
      source: 'soundcloud',
    );
  }
}
