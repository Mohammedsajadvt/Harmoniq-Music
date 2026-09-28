import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../core/api/epidemic_sound_api.dart';
import '../core/api/jamendo_api.dart';
import '../core/api/saavn_api.dart';
import '../core/api/soundcloud_api.dart';
import '../core/services/audio_handler.dart';
import '../models/track_model.dart';

enum RepeatMode { off, all, one }

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  TrackModel? _currentTrack;
  List<TrackModel> _playlist = [];
  int _currentIndex = -1;

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = false;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;

  // Getters
  TrackModel? get currentTrack => _currentTrack;
  List<TrackModel> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isBuffering => _isBuffering;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;
  bool get hasTrack => _currentTrack != null;

  AudioPlayerProvider() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    // Configure background audio session for lockscreen and background playback
    _player.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {
          AVAudioSessionOptions.defaultToSpeaker,
        },
      ),
    ));

    // Connect Spotify-style notification & lockscreen controls
    final handler = HarmoniqAudioHandler.instance;
    handler.onPlayCallback = () => resume();
    handler.onPauseCallback = () => pause();
    handler.onSkipToNextCallback = () => next();
    handler.onSkipToPreviousCallback = () => previous();
    handler.onSeekCallback = (pos) => seek(pos);

    // Player State stream
    _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      _isBuffering = false;
      _syncAudioHandler();
      notifyListeners();
    });

    // Position stream
    _player.onPositionChanged.listen((pos) {
      _position = pos;
      _syncAudioHandler();
      notifyListeners();
    });

    // Duration stream
    _player.onDurationChanged.listen((dur) {
      _duration = dur;
      _syncAudioHandler();
      notifyListeners();
    });

    // On Track Completion
    _player.onPlayerComplete.listen((_) {
      _handleTrackCompletion();
    });
  }

  void _syncAudioHandler() {
    if (_currentTrack != null) {
      HarmoniqAudioHandler.instance.updatePlaybackState(
        isPlaying: isPlaying,
        position: _position,
        duration: _duration,
        isBuffering: _isBuffering,
      );
    }
  }

  void _handleTrackCompletion() {
    if (_repeatMode == RepeatMode.one && _currentTrack != null) {
      seek(Duration.zero);
      resume();
    } else {
      next(autoPlay: true);
    }
  }

  /// Resolve or prepare audio source (handles full-length JioSaavn streams, Spotify/iTunes full-track resolution, SoundCloud & local files)
  Future<Source?> _resolveSource(TrackModel track) async {
    // 1. Direct local file (downloaded track)
    if (track.isLocal && track.localFilePath != null) {
      final file = File(track.localFilePath!);
      if (await file.exists()) {
        debugPrint('🎧 [AudioPlayer] Using local file: ${track.localFilePath}');
        return DeviceFileSource(track.localFilePath!);
      }
    }

    String activeStreamUrl = track.audioUrl;

    // If it's a 30s preview URL from iTunes (mzstatic) or Spotify (scdn.co) or empty, resolve full track with JioSaavn
    final isPreviewUrl = activeStreamUrl.contains('mzstatic.com') ||
        activeStreamUrl.contains('audio-ak-spotify-com') ||
        activeStreamUrl.contains('p.scdn.co');

    if (track.isSaavn) {
      if (activeStreamUrl.isEmpty) {
        activeStreamUrl = await SaavnApi().resolveStreamUrl(track);
      }
    } else if (track.isEpidemic) {
      activeStreamUrl = await EpidemicSoundApi().getTrackAudioUrl(track.id);
    } else if (track.isSoundCloud) {
      activeStreamUrl = await SoundCloudApi().resolveStreamUrl(track);
    } else if (track.isSpotify || isPreviewUrl || activeStreamUrl.isEmpty) {
      // Find full-length 320kbps audio stream from JioSaavn first
      final fullUrl = await SaavnApi().resolveStreamUrl(track);
      if (fullUrl.isNotEmpty) {
        activeStreamUrl = fullUrl;
      } else {
        // Fallback to Epidemic Sound or Jamendo
        try {
          final epMatches = await EpidemicSoundApi().searchTracks(query: '${track.name} ${track.artistName}', limit: 1);
          if (epMatches.isNotEmpty) {
            activeStreamUrl = await EpidemicSoundApi().getTrackAudioUrl(epMatches.first.id);
          }
        } catch (_) {}

        if (activeStreamUrl.isEmpty || isPreviewUrl) {
          try {
            final matches = await JamendoApi().searchTracks(query: '${track.name} ${track.artistName}', limit: 1);
            if (matches.isNotEmpty && matches.first.audioUrl.isNotEmpty) {
              activeStreamUrl = matches.first.audioUrl;
            }
          } catch (_) {}
        }
      }
    }

    if (activeStreamUrl.isEmpty) return null;

    // 2. Windows Desktop Compatibility: Windows Media Foundation requires explicit file extensions
    // or cached stream file to prevent C00D001A (unsupported bytestream) error with URL redirects.
    if (!kIsWeb && Platform.isWindows) {
      try {
        final tempDir = await getTemporaryDirectory();
        final cacheFile = File('${tempDir.path}/audio_cache_${track.id}.mp3');

        if (await cacheFile.exists() && (await cacheFile.length()) > 50000) {
          debugPrint('🎧 [AudioPlayer Windows] Using cached stream file: ${cacheFile.path}');
          return DeviceFileSource(cacheFile.path);
        }

        debugPrint('🎧 [AudioPlayer Windows] Streaming & caching audio for Windows Media Foundation: $activeStreamUrl');
        final response = await http.get(Uri.parse(activeStreamUrl));
        if (response.statusCode == 200) {
          await cacheFile.writeAsBytes(response.bodyBytes);
          return DeviceFileSource(cacheFile.path);
        }
      } catch (e) {
        debugPrint('⚠️ [AudioPlayer Windows Cache Warning] $e');
      }
    }

    // 3. Standard UrlSource with explicit MIME type for Android/iOS/Web
    return UrlSource(activeStreamUrl, mimeType: 'audio/mpeg');
  }

  /// Play a specific track, optionally setting the current queue
  Future<void> playTrack(
    TrackModel track, {
    List<TrackModel>? newPlaylist,
    int? index,
  }) async {
    if (newPlaylist != null) {
      _playlist = List.from(newPlaylist);
      _currentIndex = index ?? _playlist.indexWhere((t) => t.id == track.id);
    } else if (!_playlist.any((t) => t.id == track.id)) {
      _playlist.add(track);
      _currentIndex = _playlist.length - 1;
    } else {
      _currentIndex = _playlist.indexWhere((t) => t.id == track.id);
    }

    _currentTrack = track;
    _position = Duration.zero;
    _duration = Duration(seconds: track.duration);
    _isBuffering = true;
    notifyListeners();

    HarmoniqAudioHandler.instance.setTrackMetadata(
      id: track.id,
      title: track.name,
      artist: track.artistName,
      album: track.albumName,
      duration: Duration(seconds: track.duration),
      artUri: track.albumImage,
    );
    HarmoniqAudioHandler.instance.updatePlaybackState(
      isPlaying: true,
      position: Duration.zero,
      duration: Duration(seconds: track.duration),
      isBuffering: true,
    );

    try {
      await _player.stop();
      final source = await _resolveSource(track);
      if (source != null) {
        await _player.play(source);
      } else {
        throw Exception('Unable to resolve audio source for "${track.name}"');
      }
    } catch (e) {
      debugPrint('❌ [AudioPlayer Error] Failed to play track: $e');
      _isBuffering = false;
      notifyListeners();
    }
  }

  /// Play whole playlist starting from index
  Future<void> playPlaylist(List<TrackModel> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    final targetIndex = startIndex.clamp(0, tracks.length - 1);
    await playTrack(tracks[targetIndex], newPlaylist: tracks, index: targetIndex);
  }

  /// Toggle Play / Pause
  Future<void> togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Pause
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume
  Future<void> resume() async {
    if (_currentTrack != null) {
      if (_playerState == PlayerState.paused) {
        await _player.resume();
      } else {
        final source = await _resolveSource(_currentTrack!);
        if (source != null) {
          await _player.play(source);
        }
      }
    }
  }

  /// Next Track
  Future<void> next({bool autoPlay = true}) async {
    if (_playlist.isEmpty) return;

    if (_isShuffle) {
      final random = Random();
      int nextIdx = random.nextInt(_playlist.length);
      if (_playlist.length > 1 && nextIdx == _currentIndex) {
        nextIdx = (nextIdx + 1) % _playlist.length;
      }
      _currentIndex = nextIdx;
    } else {
      if (_currentIndex < _playlist.length - 1) {
        _currentIndex++;
      } else {
        if (_repeatMode == RepeatMode.all) {
          _currentIndex = 0;
        } else {
          return; // End of playlist
        }
      }
    }

    final nextTrack = _playlist[_currentIndex];
    if (autoPlay) {
      await playTrack(nextTrack, index: _currentIndex);
    } else {
      _currentTrack = nextTrack;
      notifyListeners();
    }
  }

  /// Previous Track
  Future<void> previous() async {
    if (_position.inSeconds > 4) {
      await seek(Duration.zero);
      return;
    }

    if (_playlist.isEmpty) return;

    if (_currentIndex > 0) {
      _currentIndex--;
    } else {
      _currentIndex = _playlist.length - 1;
    }

    final prevTrack = _playlist[_currentIndex];
    await playTrack(prevTrack, index: _currentIndex);
  }

  /// Seek to duration
  Future<void> seek(Duration targetPosition) async {
    _position = targetPosition;
    notifyListeners();
    await _player.seek(targetPosition);
  }

  /// Toggle Shuffle
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  /// Toggle Loop / Repeat
  void toggleRepeatMode() {
    if (_repeatMode == RepeatMode.off) {
      _repeatMode = RepeatMode.all;
    } else if (_repeatMode == RepeatMode.all) {
      _repeatMode = RepeatMode.one;
    } else {
      _repeatMode = RepeatMode.off;
    }
    notifyListeners();
  }

  /// Stop audio playback
  Future<void> stop() async {
    await _player.stop();
    _playerState = PlayerState.stopped;
    _position = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
