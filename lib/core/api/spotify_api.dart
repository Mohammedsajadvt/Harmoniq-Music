import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/album_model.dart';
import '../../models/artist_model.dart';
import '../../models/track_model.dart';
import '../constants/api_constants.dart';
import 'saavn_api.dart';
import 'itunes_api.dart';
import 'epidemic_sound_api.dart';
import 'jamendo_api.dart';

class SpotifyApi {
  static final SpotifyApi _instance = SpotifyApi._internal();
  factory SpotifyApi() => _instance;
  SpotifyApi._internal();

  final http.Client _client = http.Client();
  String _accessToken = ApiConstants.spotifyDefaultToken;

  void setToken(String token) {
    if (token.isNotEmpty && token != 'undefined') {
      _accessToken = token;
      debugPrint('🔑 [SpotifyApi] Access token updated');
    }
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  /// Map Spotify JSON track to TrackModel
  TrackModel _mapSpotifyTrack(Map<String, dynamic> item) {
    final album = item['album'] as Map<String, dynamic>? ?? {};
    final artists = item['artists'] as List? ?? [];
    final images = album['images'] as List? ?? [];

    String imageUrl = 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop';
    if (images.isNotEmpty) {
      imageUrl = images.first['url'] ?? imageUrl;
    }

    final artistNames = artists.map((a) => a['name']?.toString() ?? '').where((n) => n.isNotEmpty).join(', ');
    final primaryArtistId = artists.isNotEmpty ? (artists.first['id']?.toString() ?? '') : '';

    final durationMs = item['duration_ms'] as int? ?? 180000;
    final previewUrl = item['preview_url']?.toString() ?? '';

    return TrackModel(
      id: 'sp_${item['id'] ?? UniqueKey().toString()}',
      name: item['name'] ?? 'Unknown Track',
      duration: (durationMs / 1000).round(),
      artistId: primaryArtistId,
      artistName: artistNames.isNotEmpty ? artistNames : 'Various Artists',
      albumName: album['name'] ?? 'Single',
      albumId: album['id']?.toString() ?? '',
      albumImage: imageUrl,
      audioUrl: previewUrl,
      tags: ['spotify', 'pop', 'trending'],
      source: 'spotify',
    );
  }

  /// Get user's top tracks or top trending hits (Supports unlimited pagination)
  Future<List<TrackModel>> getTopTracks({
    int limit = 100,
    int offset = 0,
    LanguageOption? language,
  }) async {
    // 1. Prioritize Saavn Full-Length HD Songs
    final saavnTracks = await SaavnApi().getTrendingTracks(limit: limit, offset: offset, language: language);
    if (saavnTracks.isNotEmpty) return saavnTracks;

    try {
      final effectiveLimit = limit.clamp(1, 50);
      final uri = Uri.parse('${ApiConstants.spotifyBaseUrl}/me/top/tracks?time_range=long_term&limit=$effectiveLimit&offset=$offset');
      debugPrint('🟢 [SpotifyApi] GET Top Tracks: $uri');

      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'] ?? [];
        final tracks = items.map((item) => _mapSpotifyTrack(item as Map<String, dynamic>)).toList();
        if (tracks.isNotEmpty) {
          debugPrint('✅ [SpotifyApi] Loaded ${tracks.length} top tracks');
          return tracks;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SpotifyApi] /me/top/tracks fallback: $e');
    }

    // High-precision global and regional catalog search
    final tracks = await getTrendingTracks(limit: limit, offset: offset, language: language);
    if (tracks.isNotEmpty) return tracks;

    // Fallback to Epidemic Sound & Jamendo free music API
    final epTracks = await EpidemicSoundApi().getTrendingTracks(limit: limit, offset: offset);
    if (epTracks.isNotEmpty) return epTracks;

    debugPrint('🔄 [SpotifyApi] Falling back to Jamendo free music API');
    return await JamendoApi().getTrendingTracks(limit: limit, offset: offset, language: language);
  }

  /// Get Trending / Viral Charts (Full-length tracks)
  Future<List<TrackModel>> getTrendingTracks({
    int limit = 100,
    int offset = 0,
    LanguageOption? language,
  }) async {
    // 1. Saavn full tracks
    final saavnTracks = await SaavnApi().getTrendingTracks(limit: limit, offset: offset, language: language);
    if (saavnTracks.isNotEmpty) return saavnTracks;

    final query = (language != null && language.searchTag != null && language.searchTag!.isNotEmpty)
        ? '${language.searchTag} top hits'
        : 'top hits trending';

    final tracks = await searchTracks(query: query, limit: limit, offset: offset, language: language);
    if (tracks.isNotEmpty) return tracks;

    // Fallback to Epidemic Sound & Jamendo
    final epTracks = await EpidemicSoundApi().getTrendingTracks(limit: limit, offset: offset);
    if (epTracks.isNotEmpty) return epTracks;

    return await JamendoApi().getTrendingTracks(limit: limit, offset: offset, language: language);
  }

  /// Search Tracks with High Precision (Saavn Full Tracks -> iTunes -> Spotify -> Jamendo -> Epidemic)
  Future<List<TrackModel>> searchTracks({
    required String query,
    int limit = 100,
    int offset = 0,
    LanguageOption? language,
  }) async {
    // 1. Saavn full-length 320kbps engine (Matches exact tracks, Indian & Global hits, full duration audio)
    final saavnTracks = await SaavnApi().searchTracks(
      query: query,
      limit: limit,
      offset: offset,
      language: language,
    );

    if (saavnTracks.isNotEmpty) {
      return saavnTracks;
    }

    // 2. High-precision global search engine fallback
    final itunesTracks = await ITunesApi().searchTracks(
      query: query,
      limit: limit,
      offset: offset,
      language: language,
    );

    if (itunesTracks.isNotEmpty) {
      return itunesTracks;
    }

    // 2. Spotify Search (when active token available)
    final langTag = language?.searchTag;
    final effectiveQuery = (langTag != null && langTag.isNotEmpty)
        ? (query.toLowerCase().contains(langTag.toLowerCase()) ? query : '$query $langTag')
        : query;

    List<TrackModel> allTracks = [];
    int remaining = limit;
    int currentOffset = offset;

    while (remaining > 0) {
      final batchLimit = remaining.clamp(1, 50);
      final uri = Uri.parse(
        '${ApiConstants.spotifyBaseUrl}/search'
        '?q=${Uri.encodeComponent(effectiveQuery)}'
        '&type=track'
        '&limit=$batchLimit'
        '&offset=$currentOffset',
      );

      try {
        final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final tracksObj = data['tracks'] as Map<String, dynamic>? ?? {};
          final List items = tracksObj['items'] ?? [];

          if (items.isEmpty) break;

          final batch = items.map((item) => _mapSpotifyTrack(item as Map<String, dynamic>)).toList();
          allTracks.addAll(batch);
          currentOffset += items.length;
          remaining -= items.length;

          if (items.length < batchLimit) break;
        } else {
          break;
        }
      } catch (e) {
        break;
      }
    }

    if (allTracks.isNotEmpty) {
      return allTracks;
    }

    // 3. Fallback to Jamendo free music library
    final jamendoResults = await JamendoApi().searchTracks(query: effectiveQuery, limit: limit, offset: offset, language: language);
    if (jamendoResults.isNotEmpty) return jamendoResults;

    // 4. Fallback to Epidemic Sound (Strict relevance filtered)
    final epResults = await EpidemicSoundApi().searchTracks(query: effectiveQuery, limit: limit, offset: offset);
    final relevantEp = epResults.where((t) {
      final q = query.toLowerCase();
      return t.name.toLowerCase().contains(q) || t.artistName.toLowerCase().contains(q);
    }).toList();

    return relevantEp.isNotEmpty ? relevantEp : epResults;
  }

  /// Fetch Tracks by Genre on Spotify (Supports unlimited pagination)
  Future<List<TrackModel>> getTracksByGenre({
    required String genre,
    int limit = 100,
    int offset = 0,
    LanguageOption? language,
  }) async {
    final langTag = language?.searchTag;
    final effectiveQuery = (genre.toLowerCase() == 'all')
        ? ((langTag != null && langTag.isNotEmpty) ? langTag : 'popular')
        : ((langTag != null && langTag.isNotEmpty)
            ? (genre.toLowerCase().contains(langTag.toLowerCase()) ? genre : '$genre $langTag')
            : '$genre vibe');

    final tracks = await searchTracks(query: effectiveQuery, limit: limit, offset: offset, language: language);
    if (tracks.isNotEmpty) return tracks;

    final epTracks = await EpidemicSoundApi().getTracksByGenre(genre: genre, limit: limit, offset: offset);
    if (epTracks.isNotEmpty) return epTracks;

    return await JamendoApi().getTracksByGenre(genre: genre, limit: limit, language: language);
  }

  /// Fetch Featured Albums on Spotify (Up to 50 albums)
  Future<List<AlbumModel>> getFeaturedAlbums({int limit = 50}) async {
    try {
      final effectiveLimit = limit.clamp(1, 50);
      final uri = Uri.parse('${ApiConstants.spotifyBaseUrl}/browse/new-releases?limit=$effectiveLimit');
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final albumsObj = data['albums'] as Map<String, dynamic>? ?? {};
        final List items = albumsObj['items'] ?? [];

        final albums = items.map((item) {
          final images = item['images'] as List? ?? [];
          final artists = item['artists'] as List? ?? [];
          return AlbumModel(
            id: 'sp_album_${item['id']}',
            name: item['name'] ?? 'Album',
            releasedate: item['release_date'] ?? '',
            artistId: artists.isNotEmpty ? (artists.first['id']?.toString() ?? '') : '',
            artistName: artists.map((a) => a['name']).join(', '),
            image: images.isNotEmpty ? images.first['url'] : '',
          );
        }).toList();

        if (albums.isNotEmpty) return albums;
      }
    } catch (e) {
      debugPrint('❌ [SpotifyApi] getFeaturedAlbums error: $e');
    }

    final saavnAlbums = await SaavnApi().getFeaturedAlbums(limit: limit);
    if (saavnAlbums.isNotEmpty) return saavnAlbums;

    return await JamendoApi().getFeaturedAlbums(limit: limit);
  }

  /// Fetch Popular Artists on Spotify (Up to 50 artists)
  Future<List<ArtistModel>> getPopularArtists({int limit = 50}) async {
    try {
      final effectiveLimit = limit.clamp(1, 50);
      final uri = Uri.parse('${ApiConstants.spotifyBaseUrl}/me/top/artists?limit=$effectiveLimit');
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'] ?? [];

        final artists = items.map((item) {
          final images = item['images'] as List? ?? [];
          return ArtistModel(
            id: 'sp_art_${item['id']}',
            name: item['name'] ?? 'Artist',
            image: images.isNotEmpty ? images.first['url'] : '',
          );
        }).toList();

        if (artists.isNotEmpty) return artists;
      }
    } catch (e) {
      debugPrint('❌ [SpotifyApi] getPopularArtists error: $e');
    }

    final saavnArtists = await SaavnApi().getPopularArtists(limit: limit);
    if (saavnArtists.isNotEmpty) return saavnArtists;

    return await JamendoApi().getPopularArtists(limit: limit);
  }
}
