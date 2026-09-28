import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/track_model.dart';
import '../../models/album_model.dart';
import '../../models/artist_model.dart';

enum AudioFormat {
  mp31, // Standard 128kbps VBR
  mp32, // High Quality 192-320kbps VBR
  ogg,  // OGG Vorbis
  flac, // Lossless FLAC
}

extension AudioFormatExt on AudioFormat {
  String get value {
    switch (this) {
      case AudioFormat.mp31:
        return 'mp31';
      case AudioFormat.mp32:
        return 'mp32';
      case AudioFormat.ogg:
        return 'ogg';
      case AudioFormat.flac:
        return 'flac';
    }
  }

  String get displayName {
    switch (this) {
      case AudioFormat.mp31:
        return 'MP3 Standard (128 kbps)';
      case AudioFormat.mp32:
        return 'MP3 HQ (320 kbps)';
      case AudioFormat.ogg:
        return 'OGG Vorbis';
      case AudioFormat.flac:
        return 'Lossless FLAC';
    }
  }
}

class JamendoApi {
  static final JamendoApi _instance = JamendoApi._internal();
  factory JamendoApi() => _instance;
  JamendoApi._internal();

  final http.Client _client = http.Client();
  AudioFormat _selectedFormat = AudioFormat.mp31;

  AudioFormat get selectedFormat => _selectedFormat;

  void setAudioFormat(AudioFormat format) {
    _selectedFormat = format;
    debugPrint('🔊 [JamendoApi] Streaming Audio Format updated to: ${format.displayName} (${format.value})');
  }

  void _logRequest(String method, Uri uri) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🌐 [JamendoApi DYNAMIC REQUEST] $method');
    debugPrint('🔗 URL: $uri');
    debugPrint('⏱️ Timestamp: ${DateTime.now().toIso8601String()}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  void _logResponse(Uri uri, int statusCode, dynamic data, int durationMs) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('✅ [JamendoApi DYNAMIC RESPONSE] Status: $statusCode (${durationMs}ms)');
    debugPrint('🔗 URL: $uri');
    if (data is Map && data['headers'] != null) {
      final headers = data['headers'];
      debugPrint('📊 Jamendo Status: ${headers['status']} | Results Count: ${headers['results_count']} | Code: ${headers['code']}');
      if (headers['error_message'] != null && headers['error_message'].toString().isNotEmpty) {
        debugPrint('⚠️ Warnings/Errors: ${headers['error_message']}');
      }
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  void _logError(Uri uri, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('❌ [JamendoApi ERROR]');
    debugPrint('🔗 URL: $uri');
    debugPrint('💥 Error details: $error');
    if (stackTrace != null) {
      debugPrint('📜 StackTrace: $stackTrace');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  String _buildLanguageParam(LanguageOption? language) {
    if (language == null || language.code.isEmpty) return '';
    if (language.code.toLowerCase() == 'instrumental') {
      return '&vocalinstruments=instrumental';
    }
    if (language.searchTag != null && language.searchTag!.isNotEmpty) {
      return '&fuzzytags=${language.searchTag}&lang=${language.code}';
    }
    return '&lang=${language.code}';
  }

  /// Fetch Trending / Top Tracks dynamically from Jamendo API
  Future<List<TrackModel>> getTrendingTracks({
    int limit = 50,
    int offset = 0,
    String boost = 'popularity_month',
    LanguageOption? language,
  }) async {
    final langParam = _buildLanguageParam(language);
    final uri = Uri.parse(
      '${ApiConstants.tracksEndpoint}/?client_id=${ApiConstants.clientId}&format=${ApiConstants.format}&limit=$limit&offset=$offset&include=musicinfo&boost=$boost&audioformat=${_selectedFormat.value}$langParam',
    );

    _logRequest('GET Trending Tracks (Lang: ${language?.name ?? "All"})', uri);
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.get(uri);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logResponse(uri, response.statusCode, data, stopwatch.elapsedMilliseconds);

        if (data['headers'] != null && data['headers']['status'] == 'success') {
          final List results = data['results'] ?? [];
          final tracks = results.map((item) => TrackModel.fromJson(item)).toList();
          debugPrint('🎵 [JamendoApi] Successfully parsed ${tracks.length} dynamic live tracks');
          return tracks;
        }
      }
      throw Exception('Failed to fetch trending tracks (HTTP ${response.statusCode})');
    } catch (e, stack) {
      _logError(uri, e, stack);
      return [];
    }
  }

  /// Fetch Tracks filtered dynamically by Genre or Tag with language support
  Future<List<TrackModel>> getTracksByGenre({
    required String genre,
    int limit = 50,
    int offset = 0,
    LanguageOption? language,
  }) async {
    if (genre.toLowerCase() == 'all') {
      return getTrendingTracks(limit: limit, offset: offset, language: language);
    }

    final langParam = _buildLanguageParam(language);
    final tag = genre.toLowerCase().replaceAll(' ', '+');
    final uri = Uri.parse(
      '${ApiConstants.tracksEndpoint}/?client_id=${ApiConstants.clientId}&format=${ApiConstants.format}&limit=$limit&offset=$offset&tags=$tag&include=musicinfo&boost=popularity_month&audioformat=${_selectedFormat.value}$langParam',
    );

    _logRequest('GET Genre Tracks ($genre, Lang: ${language?.name ?? "All"})', uri);
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.get(uri);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logResponse(uri, response.statusCode, data, stopwatch.elapsedMilliseconds);

        if (data['headers'] != null && data['headers']['status'] == 'success') {
          final List results = data['results'] ?? [];
          final tracks = results.map((item) => TrackModel.fromJson(item)).toList();
          debugPrint('🎵 [JamendoApi] Found ${tracks.length} dynamic live tracks for genre "$genre"');
          return tracks;
        }
      }
      throw Exception('Failed to fetch tracks for genre "$genre"');
    } catch (e, stack) {
      _logError(uri, e, stack);
      return [];
    }
  }

  /// Search Tracks dynamically by keyword with language filter
  Future<List<TrackModel>> searchTracks({
    required String query,
    int limit = 50,
    int offset = 0,
    LanguageOption? language,
  }) async {
    if (query.trim().isEmpty) return [];

    final langParam = _buildLanguageParam(language);
    final encodedQuery = Uri.encodeComponent(query.trim());
    final uri = Uri.parse(
      '${ApiConstants.tracksEndpoint}/?client_id=${ApiConstants.clientId}&format=${ApiConstants.format}&limit=$limit&offset=$offset&namesearch=$encodedQuery&include=musicinfo&audioformat=${_selectedFormat.value}$langParam',
    );

    _logRequest('GET Search Tracks ("$query", Lang: ${language?.name ?? "All"})', uri);
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.get(uri);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logResponse(uri, response.statusCode, data, stopwatch.elapsedMilliseconds);

        if (data['headers'] != null && data['headers']['status'] == 'success') {
          final List results = data['results'] ?? [];
          final tracks = results.map((item) => TrackModel.fromJson(item)).toList();
          debugPrint('🔎 [JamendoApi] Search "$query" matched ${tracks.length} dynamic live tracks');
          return tracks;
        }
      }
      throw Exception('Failed to search tracks for "$query"');
    } catch (e, stack) {
      _logError(uri, e, stack);
      return [];
    }
  }

  /// Fetch Featured Albums dynamically
  Future<List<AlbumModel>> getFeaturedAlbums({int limit = 50}) async {
    final uri = Uri.parse(
      '${ApiConstants.albumsEndpoint}/?client_id=${ApiConstants.clientId}&format=${ApiConstants.format}&limit=$limit&hasimage=true&order=popularity_month',
    );

    _logRequest('GET Featured Albums', uri);
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.get(uri);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logResponse(uri, response.statusCode, data, stopwatch.elapsedMilliseconds);

        if (data['headers'] != null && data['headers']['status'] == 'success') {
          final List results = data['results'] ?? [];
          return results.map((item) => AlbumModel.fromJson(item)).toList();
        }
      }
      throw Exception('Failed to fetch albums');
    } catch (e, stack) {
      _logError(uri, e, stack);
      return [];
    }
  }

  /// Fetch Popular Artists dynamically
  Future<List<ArtistModel>> getPopularArtists({int limit = 50}) async {
    final uri = Uri.parse(
      '${ApiConstants.artistsEndpoint}/?client_id=${ApiConstants.clientId}&format=${ApiConstants.format}&limit=$limit&hasimage=true&order=popularity_month',
    );

    _logRequest('GET Popular Artists', uri);
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.get(uri);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logResponse(uri, response.statusCode, data, stopwatch.elapsedMilliseconds);

        if (data['headers'] != null && data['headers']['status'] == 'success') {
          final List results = data['results'] ?? [];
          return results.map((item) => ArtistModel.fromJson(item)).toList();
        }
      }
      throw Exception('Failed to fetch artists');
    } catch (e, stack) {
      _logError(uri, e, stack);
      return [];
    }
  }

  /// Fetch tracks belonging to a specific album dynamically
  Future<List<TrackModel>> getTracksByAlbum(String albumId, {int limit = 30}) async {
    final uri = Uri.parse(
      '${ApiConstants.tracksEndpoint}/?client_id=${ApiConstants.clientId}&format=${ApiConstants.format}&album_id=$albumId&include=musicinfo&audioformat=mp32&limit=$limit&order=track_position',
    );

    _logRequest('GET Album Tracks ($albumId)', uri);
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.get(uri);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logResponse(uri, response.statusCode, data, stopwatch.elapsedMilliseconds);

        if (data['headers'] != null && data['headers']['status'] == 'success') {
          final List results = data['results'] ?? [];
          return results.map((item) => TrackModel.fromJson(item)).toList();
        }
      }
      throw Exception('Failed to fetch album tracks');
    } catch (e, stack) {
      _logError(uri, e, stack);
      return [];
    }
  }

  /// Fetch tracks created by a specific artist dynamically
  Future<List<TrackModel>> getTracksByArtist(String artistId, {String? artistName, int limit = 30}) async {
    final queryParam = artistId.isNotEmpty
        ? 'artist_id=$artistId'
        : 'artist_name=${Uri.encodeComponent(artistName ?? '')}';
    final uri = Uri.parse(
      '${ApiConstants.tracksEndpoint}/?client_id=${ApiConstants.clientId}&format=${ApiConstants.format}&$queryParam&include=musicinfo&audioformat=mp32&limit=$limit&order=popularity_total',
    );

    _logRequest('GET Artist Tracks ($artistId / $artistName)', uri);
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.get(uri);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logResponse(uri, response.statusCode, data, stopwatch.elapsedMilliseconds);

        if (data['headers'] != null && data['headers']['status'] == 'success') {
          final List results = data['results'] ?? [];
          return results.map((item) => TrackModel.fromJson(item)).toList();
        }
      }
      throw Exception('Failed to fetch artist tracks');
    } catch (e, stack) {
      _logError(uri, e, stack);
      return [];
    }
  }

  /// Get direct download URL for a track
  String getTrackDownloadUrl(String trackId, {AudioFormat format = AudioFormat.mp32}) {
    final formatStr = (format == AudioFormat.flac) ? 'flac' : 'mp32';
    return 'https://prod-1.storage.jamendo.com/download/track/$trackId/$formatStr/?client_id=${ApiConstants.clientId}';
  }
}
