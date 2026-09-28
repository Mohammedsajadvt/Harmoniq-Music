import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

class HarmoniqAudioHandler extends BaseAudioHandler with SeekHandler {
  static HarmoniqAudioHandler? _instance;
  static HarmoniqAudioHandler get instance => _instance ??= HarmoniqAudioHandler._();

  HarmoniqAudioHandler._();

  VoidCallback? onPlayCallback;
  VoidCallback? onPauseCallback;
  VoidCallback? onSkipToNextCallback;
  VoidCallback? onSkipToPreviousCallback;
  Function(Duration position)? onSeekCallback;

  static Future<HarmoniqAudioHandler> init() async {
    try {
      final handler = await AudioService.init(
        builder: () => HarmoniqAudioHandler.instance,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.antigravity.myownmusic.channel.audio',
          androidNotificationChannelName: 'Harmoniq Music Playback',
          androidNotificationChannelDescription: 'Control playback of your songs',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'mipmap/launcher_icon',
          androidShowNotificationBadge: true,
          fastForwardInterval: Duration(seconds: 10),
          rewindInterval: Duration(seconds: 10),
        ),
      );
      return handler;
    } catch (e) {
      debugPrint('⚠️ [HarmoniqAudioHandler] Init fallback: $e');
      return HarmoniqAudioHandler.instance;
    }
  }

  /// Update Lock Screen & Notification area metadata (Track title, artist, artwork, duration)
  void setTrackMetadata({
    required String id,
    required String title,
    required String artist,
    required String album,
    required Duration duration,
    String? artUri,
  }) {
    try {
      mediaItem.add(
        MediaItem(
          id: id,
          album: album.isNotEmpty ? album : 'Single',
          title: title,
          artist: artist,
          duration: duration,
          artUri: (artUri != null && artUri.isNotEmpty) ? Uri.tryParse(artUri) : null,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [HarmoniqAudioHandler] setTrackMetadata: $e');
    }
  }

  /// Update Lock Screen & Notification playback controls (Play, Pause, Skip, Next, Position)
  void updatePlaybackState({
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    bool isBuffering = false,
  }) {
    try {
      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (isPlaying) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: isBuffering
              ? AudioProcessingState.buffering
              : (isPlaying ? AudioProcessingState.ready : AudioProcessingState.idle),
          playing: isPlaying,
          updatePosition: position,
          bufferedPosition: position,
          speed: 1.0,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [HarmoniqAudioHandler] updatePlaybackState: $e');
    }
  }

  @override
  Future<void> play() async {
    onPlayCallback?.call();
  }

  @override
  Future<void> pause() async {
    onPauseCallback?.call();
  }

  @override
  Future<void> skipToNext() async {
    onSkipToNextCallback?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onSkipToPreviousCallback?.call();
  }

  @override
  Future<void> seek(Duration position) async {
    onSeekCallback?.call(position);
  }

  @override
  Future<void> stop() async {
    onPauseCallback?.call();
    await super.stop();
  }
}
