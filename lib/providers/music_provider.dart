import 'package:flutter/foundation.dart';
import '../core/api/epidemic_sound_api.dart';
import '../core/api/jamendo_api.dart';
import '../core/api/spotify_api.dart';
import '../core/constants/api_constants.dart';
import '../models/track_model.dart';
import '../models/album_model.dart';
import '../models/artist_model.dart';

class MusicProvider extends ChangeNotifier {
  final SpotifyApi _spotifyApi = SpotifyApi();
  final EpidemicSoundApi _epidemicApi = EpidemicSoundApi();
  final JamendoApi _jamendoApi = JamendoApi();

  // State Variables
  List<TrackModel> _trendingTracks = [];
  List<TrackModel> _upcomingTracks = [];
  List<TrackModel> _royaltyFreeTracks = [];
  List<TrackModel> _genreTracks = [];
  List<AlbumModel> _featuredAlbums = [];
  List<ArtistModel> _popularArtists = [];
  List<TrackModel> _searchResults = [];

  String _selectedGenre = 'All';
  LanguageOption _selectedLanguage = ApiConstants.languages.first; // Default: All Languages

  bool _isLoadingTrending = false;
  bool _isLoadingUpcoming = false;
  bool _isLoadingRoyaltyFree = false;
  bool _isLoadingGenre = false;
  bool _isLoadingAlbums = false;
  bool _isLoadingArtists = false;
  bool _isSearching = false;
  String _lastSearchQuery = '';

  // Getters
  List<TrackModel> get trendingTracks => _trendingTracks;
  List<TrackModel> get upcomingTracks => _upcomingTracks;
  List<TrackModel> get royaltyFreeTracks => _royaltyFreeTracks;
  List<TrackModel> get genreTracks => _genreTracks;
  List<AlbumModel> get featuredAlbums => _featuredAlbums;
  List<ArtistModel> get popularArtists => _popularArtists;
  List<TrackModel> get searchResults => _searchResults;

  String get selectedGenre => _selectedGenre;
  LanguageOption get selectedLanguage => _selectedLanguage;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isLoadingUpcoming => _isLoadingUpcoming;
  bool get isLoadingRoyaltyFree => _isLoadingRoyaltyFree;
  bool get isLoadingGenre => _isLoadingGenre;
  bool get isLoadingAlbums => _isLoadingAlbums;
  bool get isLoadingArtists => _isLoadingArtists;
  bool get isSearching => _isSearching;
  String get lastSearchQuery => _lastSearchQuery;

  MusicProvider() {
    loadHomeData();
  }

  /// Initial load for home screen with unlimited catalog sections
  Future<void> loadHomeData() async {
    fetchTrendingTracks();
    fetchUpcomingTracks();
    fetchRoyaltyFreeTracks();
    fetchFeaturedAlbums();
    fetchPopularArtists();
    fetchGenreTracks(_selectedGenre);
  }

  /// Update selected language and refresh data
  Future<void> setLanguage(LanguageOption language) async {
    if (_selectedLanguage.code == language.code && _selectedLanguage.searchTag == language.searchTag) return;
    _selectedLanguage = language;
    notifyListeners();

    debugPrint('🌐 [MusicProvider] Language switched to: ${language.name} (${language.code})');
    await Future.wait([
      fetchTrendingTracks(),
      fetchUpcomingTracks(),
      fetchRoyaltyFreeTracks(),
      fetchGenreTracks(_selectedGenre),
      if (_lastSearchQuery.isNotEmpty) search(_lastSearchQuery),
    ]);
  }

  /// Fetch Upcoming & New Releases (100+ tracks & unlimited pagination)
  Future<void> fetchUpcomingTracks({bool loadMore = false}) async {
    if (_isLoadingUpcoming) return;
    _isLoadingUpcoming = true;
    notifyListeners();

    try {
      final offset = loadMore ? _upcomingTracks.length : 0;
      final query = (_selectedLanguage.searchTag != null && _selectedLanguage.searchTag!.isNotEmpty)
          ? 'new releases ${_selectedLanguage.searchTag}'
          : 'upcoming new releases 2026';

      final tracks = await _spotifyApi.searchTracks(
        query: query,
        limit: 100,
        offset: offset,
        language: _selectedLanguage,
      );

      if (tracks.isNotEmpty) {
        if (loadMore) {
          _upcomingTracks.addAll(tracks);
        } else {
          _upcomingTracks = tracks;
        }
      } else if (!loadMore) {
        _upcomingTracks = await _jamendoApi.getTrendingTracks(limit: 100, boost: 'buzz_rate', language: _selectedLanguage);
      }
    } catch (e) {
      debugPrint('Error fetchUpcomingTracks: $e');
    } finally {
      _isLoadingUpcoming = false;
      notifyListeners();
    }
  }

  /// Fetch Epidemic Sound Royalty-Free Creator Tracks (100+ tracks & unlimited pagination)
  Future<void> fetchRoyaltyFreeTracks({bool loadMore = false}) async {
    if (_isLoadingRoyaltyFree) return;
    _isLoadingRoyaltyFree = true;
    notifyListeners();

    try {
      final offset = loadMore ? _royaltyFreeTracks.length : 0;
      final tracks = await _epidemicApi.getTrendingTracks(limit: 100, offset: offset);
      if (loadMore) {
        _royaltyFreeTracks.addAll(tracks);
      } else {
        _royaltyFreeTracks = tracks;
      }
    } catch (e) {
      debugPrint('Error fetchRoyaltyFreeTracks: $e');
    } finally {
      _isLoadingRoyaltyFree = false;
      notifyListeners();
    }
  }

  /// Fetch trending tracks from Spotify (100+ tracks & unlimited pagination)
  Future<void> fetchTrendingTracks({bool loadMore = false}) async {
    if (_isLoadingTrending) return;
    _isLoadingTrending = true;
    notifyListeners();

    try {
      final offset = loadMore ? _trendingTracks.length : 0;
      final tracks = await _spotifyApi.getTopTracks(
        limit: 100,
        offset: offset,
        language: _selectedLanguage,
      );
      if (loadMore) {
        _trendingTracks.addAll(tracks);
      } else {
        _trendingTracks = tracks;
      }
    } catch (e) {
      debugPrint('Error fetchTrendingTracks: $e');
    } finally {
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  /// Fetch tracks by selected Genre dynamically from API (100+ tracks & unlimited pagination)
  Future<void> setGenre(String genre) async {
    if (_selectedGenre == genre && _genreTracks.isNotEmpty && !_isLoadingGenre) return;
    _selectedGenre = genre;
    _genreTracks = [];
    _isLoadingGenre = true;
    notifyListeners();

    debugPrint('🎧 [MusicProvider] Genre filter activated: $genre (API fetching...)');
    await fetchGenreTracks(genre);
  }

  Future<void> fetchGenreTracks(String genre, {bool loadMore = false}) async {
    if (_isLoadingGenre && loadMore) return;
    _isLoadingGenre = true;
    notifyListeners();

    try {
      final offset = loadMore ? _genreTracks.length : 0;
      final tracks = await _spotifyApi.getTracksByGenre(
        genre: genre,
        limit: 100,
        offset: offset,
        language: _selectedLanguage,
      );
      if (loadMore) {
        _genreTracks.addAll(tracks);
      } else {
        _genreTracks = tracks;
      }
      debugPrint('✅ [MusicProvider] Loaded ${_genreTracks.length} tracks for genre: "$genre" from API');
    } catch (e) {
      debugPrint('❌ Error fetchGenreTracks: $e');
    } finally {
      _isLoadingGenre = false;
      notifyListeners();
    }
  }

  /// Fetch Featured Albums from Spotify (100 albums)
  Future<void> fetchFeaturedAlbums() async {
    _isLoadingAlbums = true;
    notifyListeners();

    try {
      _featuredAlbums = await _spotifyApi.getFeaturedAlbums(limit: 50);
    } catch (e) {
      debugPrint('Error fetchFeaturedAlbums: $e');
    } finally {
      _isLoadingAlbums = false;
      notifyListeners();
    }
  }

  /// Fetch Popular Artists from Spotify (100 artists)
  Future<void> fetchPopularArtists() async {
    _isLoadingArtists = true;
    notifyListeners();

    try {
      _popularArtists = await _spotifyApi.getPopularArtists(limit: 50);
    } catch (e) {
      debugPrint('Error fetchPopularArtists: $e');
    } finally {
      _isLoadingArtists = false;
      notifyListeners();
    }
  }

  /// Search Tracks across Spotify (100+ tracks & unlimited pagination)
  Future<void> search(String query, {bool loadMore = false}) async {
    if (!loadMore) {
      _lastSearchQuery = query;
      if (query.trim().isEmpty) {
        _searchResults = [];
        _isSearching = false;
        notifyListeners();
        return;
      }
    }

    _isSearching = true;
    notifyListeners();

    try {
      final offset = loadMore ? _searchResults.length : 0;
      final tracks = await _spotifyApi.searchTracks(
        query: query,
        limit: 100,
        offset: offset,
        language: _selectedLanguage,
      );
      if (loadMore) {
        _searchResults.addAll(tracks);
      } else {
        _searchResults = tracks;
      }
    } catch (e) {
      debugPrint('Error search: $e');
      if (!loadMore) _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _lastSearchQuery = '';
    _isSearching = false;
    notifyListeners();
  }

  /// Get tracks for a specific album from Spotify
  Future<List<TrackModel>> getAlbumTracks(AlbumModel album) async {
    try {
      return await _spotifyApi.searchTracks(query: 'album:"${album.name}"', limit: 50);
    } catch (e) {
      debugPrint('Error getAlbumTracks: $e');
      return [];
    }
  }

  /// Get tracks for a specific artist from Spotify
  Future<List<TrackModel>> getArtistTracks(ArtistModel artist) async {
    try {
      return await _spotifyApi.searchTracks(query: 'artist:"${artist.name}"', limit: 50);
    } catch (e) {
      debugPrint('Error getArtistTracks: $e');
      return [];
    }
  }

  /// Fetch extended catalog of albums for See All view (Unlimited)
  Future<List<AlbumModel>> fetchAllAlbums({int limit = 100}) async {
    try {
      final albums = await _spotifyApi.getFeaturedAlbums(limit: limit);
      return albums.isNotEmpty ? albums : _featuredAlbums;
    } catch (e) {
      debugPrint('Error fetchAllAlbums: $e');
      return _featuredAlbums;
    }
  }

  /// Fetch extended catalog of artists for See All view (Unlimited)
  Future<List<ArtistModel>> fetchAllArtists({int limit = 100}) async {
    try {
      final artists = await _spotifyApi.getPopularArtists(limit: limit);
      return artists.isNotEmpty ? artists : _popularArtists;
    } catch (e) {
      debugPrint('Error fetchAllArtists: $e');
      return _popularArtists;
    }
  }
}
