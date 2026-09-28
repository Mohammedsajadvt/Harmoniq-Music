import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/jamendo_api.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_formatter.dart';
import '../../models/track_model.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/favorites_provider.dart';
import 'widgets/animated_vinyl.dart';
import 'widgets/equalizer_visualizer.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  bool _showQueue = false;

  void _showQualityModal(BuildContext context) {
    final api = JamendoApi();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Streaming & Audio Format',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Select your preferred Jamendo audio quality',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...AudioFormat.values.map((format) {
                  final isSelected = api.selectedFormat == format;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.secondary : Colors.white10,
                        width: 1.2,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        format.displayName,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.secondary)
                          : null,
                      onTap: () {
                        api.setAudioFormat(format);
                        setModalState(() {});
                        setState(() {});
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceElevated,
                            content: Text('Audio stream quality set to ${format.displayName}'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final track = player.currentTrack;

    if (track == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'No Track Playing',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final isFav = favorites.isFavorite(track.id);
    final isPlaying = player.isPlaying;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Dynamic Background Glow / Blur from Track
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            height: 450,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.35),
                    AppColors.secondary.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 32,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          Text(
                            track.isLocal ? 'PLAYING FROM LOCAL STORAGE' : 'PLAYING FROM JAMENDO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: AppColors.primaryLight.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.albumName.isNotEmpty ? track.albumName : 'Single Track',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          _showQueue ? Icons.album_rounded : Icons.queue_music_rounded,
                          color: _showQueue ? AppColors.secondary : AppColors.textPrimary,
                          size: 26,
                        ),
                        onPressed: () {
                          setState(() {
                            _showQueue = !_showQueue;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _showQueue
                      ? _buildQueueView(player, favorites)
                      : _buildMainPlayerView(track, player, isFav, isPlaying),
                ),

                // Bottom Toolbar with Audio Format, Share, & Like
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Audio Format Selector Badge
                      GestureDetector(
                        onTap: () => _showQualityModal(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.high_quality_rounded, size: 16, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                JamendoApi().selectedFormat.displayName.split(' ').first.toUpperCase(),
                                style: const TextStyle(
                                   fontSize: 11,
                                   fontWeight: FontWeight.w700,
                                   color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.secondary),
                            ],
                          ),
                        ),
                      ),

                      // Share & Fav Buttons
                      Row(
                        children: [
                          // Share Action
                          IconButton(
                            icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.surfaceElevated,
                                  content: Text('Sharing "${track.name}" by ${track.artistName}'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                          ),

                          // Favorite Action
                          IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? AppColors.accent : AppColors.textSecondary,
                              size: 22,
                            ),
                            onPressed: () {
                              favorites.toggleFavorite(track);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPlayerView(
    TrackModel track,
    AudioPlayerProvider player,
    bool isFav,
    bool isPlaying,
  ) {
    final double maxSec = (player.duration.inSeconds > 0)
        ? player.duration.inSeconds.toDouble()
        : (track.duration > 0 ? track.duration.toDouble() : 1.0);
    final double currentSec = player.position.inSeconds.toDouble().clamp(0.0, maxSec);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Animated 3D Vinyl Album Artwork
            AnimatedVinyl(
              imageUrl: track.albumImage,
              isPlaying: isPlaying,
              size: MediaQuery.of(context).size.width * 0.72,
            ),

            const SizedBox(height: 28),

            // Equalizer Waveform Bars Visualizer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EqualizerVisualizer(
                  isPlaying: isPlaying,
                  barCount: 16,
                  maxHeight: 24,
                  width: 3.5,
                  gradient: AppColors.primaryGradient,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Title & Artist
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        track.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress Slider
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: AppColors.secondary,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: currentSec,
                    min: 0.0,
                    max: maxSec,
                    onChanged: (val) {
                      player.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TimeFormatter.formatDuration(player.position),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        TimeFormatter.formatSeconds(track.duration),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Main Media Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Shuffle Button
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: player.isShuffle ? AppColors.secondary : AppColors.textMuted,
                    size: 24,
                  ),
                  onPressed: () => player.toggleShuffle(),
                ),

                // Previous Button
                IconButton(
                  icon: const Icon(
                    Icons.skip_previous_rounded,
                    color: AppColors.textPrimary,
                    size: 36,
                  ),
                  onPressed: () => player.previous(),
                ),

                // Play / Pause Neon Bubble
                GestureDetector(
                  onTap: () => player.togglePlayPause(),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.neonGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: player.isBuffering
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),

                // Next Button
                IconButton(
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    color: AppColors.textPrimary,
                    size: 36,
                  ),
                  onPressed: () => player.next(),
                ),

                // Repeat Mode Button
                IconButton(
                  icon: Icon(
                    player.repeatMode == RepeatMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: player.repeatMode != RepeatMode.off
                        ? AppColors.secondary
                        : AppColors.textMuted,
                    size: 24,
                  ),
                  onPressed: () => player.toggleRepeatMode(),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueView(AudioPlayerProvider player, FavoritesProvider favorites) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Playing Queue (${player.playlist.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (player.isShuffle)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SHUFFLE ON',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: player.playlist.length,
            itemBuilder: (context, index) {
              final item = player.playlist[index];
              final isCurrentItem = index == player.currentIndex;

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.albumImage,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Image.asset(
                      'assets/images/album1.jpg',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrentItem ? AppColors.secondary : AppColors.textPrimary,
                    fontWeight: isCurrentItem ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  item.artistName,
                  maxLines: 1,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                trailing: isCurrentItem
                    ? const EqualizerVisualizer(
                        isPlaying: true,
                        barCount: 3,
                        maxHeight: 16,
                      )
                    : Text(
                        TimeFormatter.formatSeconds(item.duration),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                onTap: () {
                  player.playTrack(item, index: index);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
