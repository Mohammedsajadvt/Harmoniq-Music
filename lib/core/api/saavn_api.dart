import 'dart:convert';
import 'package:dart_des/dart_des.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/album_model.dart';
import '../../models/artist_model.dart';
import '../../models/track_model.dart';
import '../constants/api_constants.dart';

class SaavnApi {
  static final SaavnApi _instance = SaavnApi._internal();
  factory SaavnApi() => _instance;
  SaavnApi._internal();

  final http.Client _client = http.Client();

  static final DES _des = DES(
    key: utf8.encode('38346591'),
    mode: DESMode.ECB,
    paddingType: DESPaddingType.PKCS7,
  );

  /// Decrypt encrypted_media_url from JioSaavn to full 320kbps audio stream URL
  static String decryptMediaUrl(String encryptedUrl, {String quality = '320'}) {
    if (encryptedUrl.isEmpty) return '';
    try {
      final encryptedBytes = base64.decode(encryptedUrl);
      final decryptedBytes = _des.decrypt(encryptedBytes);
      String decrypted = utf8.decode(decryptedBytes);
      
      // Upgrade bitrate from 96 / 160 to 320 kbps for ultra HD audio quality
      if (quality == '320') {
        decrypted = decrypted
            .replaceAll('_96.mp4', '_320.mp4')
            .replaceAll('_160.mp4', '_320.mp4');
      } else if (quality == '160') {
        decrypted = decrypted
            .replaceAll('_96.mp4', '_160.mp4')
            .replaceAll('_320.mp4', '_160.mp4');
      }
      return decrypted;
    } catch (e) {
      debugPrint('⚠️ [SaavnApi] Decryption error: $e');
      return '';
    }
  }

  /// Clean HTML entities in titles and artist names
  String _cleanString(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// Map JioSaavn song JSON to TrackModel
  TrackModel? _mapSongToTrack(Map<String, dynamic> item) {
    try {
      final encryptedUrl = item['encrypted_media_url']?.toString() ?? '';
      String audioUrl = decryptMediaUrl(encryptedUrl);
      if (audioUrl.isEmpty) {
        audioUrl = item['media_preview_url']?.toString() ?? '';
      }

      final songTitle = _cleanString(item['song']?.toString() ?? item['title']?.toString() ?? 'Unknown Track');
      final artistName = _cleanString(item['primary_artists']?.toString() ?? item['singers']?.toString() ?? item['music']?.toString() ?? 'Various Artists');
      final albumName = _cleanString(item['album']?.toString() ?? 'Single');
      final albumId = item['albumid']?.toString() ?? '';
      final trackId = item['id']?.toString() ?? UniqueKey().toString();
      final durationSec = int.tryParse(item['duration']?.toString() ?? '180') ?? 180;

      String rawImage = item['image']?.toString() ?? '';
      if (rawImage.isEmpty) {
        rawImage = 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop';
      } else {
        // Upgrade image quality to 500x500
        rawImage = rawImage.replaceAll('150x150', '500x500').replaceAll('50x50', '500x500');
      }

      final language = item['language']?.toString().toLowerCase() ?? 'music';
      final permaUrl = item['perma_url']?.toString();

      return TrackModel(
        id: 'sv_$trackId',
        name: songTitle,
        duration: durationSec,
        artistId: 'sv_art_${item['primary_artists_id']?.toString() ?? '0'}',
        artistName: artistName,
        albumName: albumName,
        albumId: 'sv_alb_$albumId',
        albumImage: rawImage,
        audioUrl: audioUrl,
        audioDownloadUrl: audioUrl,
        releaseDate: item['year']?.toString() ?? item['release_date']?.toString(),
        shareUrl: permaUrl,
        licenseUrl: item['copyright_text']?.toString(),
        tags: [language, 'full_song', '320kbps'],
        source: 'saavn',
      );
    } catch (e) {
      debugPrint('⚠️ [SaavnApi] Error mapping song: $e');
      return null;
    }
  }

  /// Search for full-length songs with high precision
  Future<List<TrackModel>> searchTracks({
    required String query,
    int limit = 50,
    int offset = 0,
    LanguageOption? language,
  }) async {
    final page = (offset / limit.clamp(1, 50)).floor() + 1;
    final langTag = language?.searchTag;
    final effectiveQuery = (langTag != null && langTag.isNotEmpty)
        ? (query.toLowerCase().contains(langTag.toLowerCase()) ? query : '$query $langTag')
        : query;

    final uri = Uri.parse(
      'https://www.jiosaavn.com/api.php?__call=search.getResults&_format=json&_marker=0&cc=in&includeMetaTags=1&p=$page&n=${limit.clamp(1, 50)}&q=${Uri.encodeComponent(effectiveQuery)}',
    );

    try {
      debugPrint('🟢 [SaavnApi] Search: $effectiveQuery (page $page)');
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final tracks = results
            .map((item) => _mapSongToTrack(item as Map<String, dynamic>))
            .whereType<TrackModel>()
            .toList();

        debugPrint('✅ [SaavnApi] Found ${tracks.length} full-length tracks');
        return tracks;
      }
    } catch (e) {
      debugPrint('❌ [SaavnApi] Search error: $e');
    }
    return [];
  }

  /// Get Top Trending songs (Full tracks)
  Future<List<TrackModel>> getTrendingTracks({
    int limit = 50,
    int offset = 0,
    LanguageOption? language,
  }) async {
    // If language is selected, search language specific trending hits
    String query = 'trending top hits';
    if (language != null && language.searchTag != null && language.searchTag!.isNotEmpty) {
      query = '${language.searchTag} top hits 2024';
    } else if (language != null && language.name.isNotEmpty && language.code.isNotEmpty) {
      query = '${language.name} top songs';
    }

    final tracks = await searchTracks(query: query, limit: limit, offset: offset, language: language);
    if (tracks.isNotEmpty) return tracks;

    // Fallback: Default India Superhits Top 50 Playlist
    try {
      final uri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=playlist.getDetails&_format=json&_marker=0&cc=in&listid=1134548194',
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List songs = data['songs'] ?? [];
        final list = songs
            .map((s) => _mapSongToTrack(s as Map<String, dynamic>))
            .whereType<TrackModel>()
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('⚠️ [SaavnApi] Playlist fallback error: $e');
    }

    return [];
  }

  /// Get tracks by genre
  Future<List<TrackModel>> getTracksByGenre({
    required String genre,
    int limit = 50,
    int offset = 0,
    LanguageOption? language,
  }) async {
    final langTag = language?.searchTag ?? '';
    final query = langTag.isNotEmpty ? '$genre $langTag' : '$genre hits';
    return await searchTracks(query: query, limit: limit, offset: offset, language: language);
  }

  /// Find and resolve full 320kbps streaming audio URL for any track
  Future<String> resolveStreamUrl(TrackModel track) async {
    // If already a JioSaavn track and has audioUrl, return it
    if (track.isSaavn && track.audioUrl.isNotEmpty && track.audioUrl.startsWith('http')) {
      return track.audioUrl;
    }

    try {
      final query = '${track.name} ${track.artistName}';
      final results = await searchTracks(query: query, limit: 3);
      if (results.isNotEmpty) {
        for (final item in results) {
          if (item.audioUrl.isNotEmpty && item.audioUrl.startsWith('http')) {
            debugPrint('🎧 [SaavnApi] Successfully resolved full stream for "${track.name}": ${item.audioUrl}');
            return item.audioUrl;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SaavnApi] resolveStreamUrl failed: $e');
    }
    return '';
  }

  /// Get Featured Albums
  Future<List<AlbumModel>> getFeaturedAlbums({int limit = 50}) async {
    try {
      final uri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=search.getAlbumResults&_format=json&_marker=0&cc=in&p=1&n=$limit&q=top%20albums%202024',
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((item) {
          String img = item['image']?.toString() ?? '';
          if (img.isNotEmpty) {
            img = img.replaceAll('150x150', '500x500');
          }
          return AlbumModel(
            id: 'sv_alb_${item['id'] ?? UniqueKey().toString()}',
            name: _cleanString(item['title'] ?? item['name'] ?? 'Album'),
            artistId: 'sv_art_${item['primary_artists_id'] ?? '0'}',
            artistName: _cleanString(item['primary_artists'] ?? item['artist'] ?? 'Various Artists'),
            releasedate: item['year']?.toString() ?? '2024',
            image: img.isNotEmpty ? img : 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop',
            zip: '',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('❌ [SaavnApi] getFeaturedAlbums error: $e');
    }
    return [];
  }

  /// Get Popular Artists
  Future<List<ArtistModel>> getPopularArtists({int limit = 50}) async {
    try {
      final uri = Uri.parse(
        'https://www.jiosaavn.com/api.php?__call=search.getArtistResults&_format=json&_marker=0&cc=in&p=1&n=$limit&q=top%20artists',
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((item) {
          String img = item['image']?.toString() ?? '';
          if (img.isNotEmpty) {
            img = img.replaceAll('150x150', '500x500').replaceAll('50x50', '500x500');
          }
          return ArtistModel(
            id: 'sv_art_${item['id'] ?? UniqueKey().toString()}',
            name: _cleanString(item['name'] ?? item['title'] ?? 'Artist'),
            website: '',
            joindate: '',
            image: img.isNotEmpty ? img : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop',
            shorturl: '',
            shareurl: '',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('❌ [SaavnApi] getPopularArtists error: $e');
    }
    return [];
  }
}
