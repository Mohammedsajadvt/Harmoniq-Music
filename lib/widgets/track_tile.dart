import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/time_formatter.dart';
import '../models/track_model.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favorites_provider.dart';
import '../screens/player/widgets/equalizer_visualizer.dart';

class TrackTile extends StatelessWidget {
  final TrackModel track;
  final List<TrackModel>? playlist;
  final int? index;
  final bool showDuration;
  final VoidCallback? onMore;

  const TrackTile({
    super.key,
    required this.track,
    this.playlist,
    this.index,
    this.showDuration = true,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();
    final favorites = context.watch<FavoritesProvider>();

    final isCurrent = player.currentTrack?.id == track.id;
    final isPlaying = isCurrent && player.isPlaying;
    final isFav = favorites.isFavorite(track.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppColors.primaryLight.withOpacity(0.4)
              : Colors.white.withOpacity(0.04),
          width: isCurrent ? 1.2 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            player.playTrack(
              track,
              newPlaylist: playlist,
              index: index,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Track Artwork with Status overlay
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: track.albumImage,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 54,
                          height: 54,
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.music_note, color: AppColors.textMuted),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/images/album1.jpg',
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: isPlaying
                              ? const EqualizerVisualizer(
                                  isPlaying: true,
                                  barCount: 3,
                                  maxHeight: 18,
                                )
                              : const Icon(
                                  Icons.pause_rounded,
                                  color: AppColors.secondary,
                                  size: 22,
                                ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Title & Artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? AppColors.secondaryLight
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          // Platform Source Badge (Spotify)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DB954).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF1DB954).withOpacity(0.4),
                                width: 0.6,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 9,
                                  color: Color(0xFF1DB954),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'SPOTIFY',
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1DB954),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (track.tags.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                track.tags.first.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Duration
                if (showDuration) ...[
                  Text(
                    TimeFormatter.formatSeconds(track.duration),
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrent ? AppColors.secondary : AppColors.textMuted,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],

                const SizedBox(width: 4),

                // Favorite Button
                IconButton(
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: const EdgeInsets.all(6),
                  icon: Icon(
                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFav ? AppColors.accent : AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    favorites.toggleFavorite(track);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
