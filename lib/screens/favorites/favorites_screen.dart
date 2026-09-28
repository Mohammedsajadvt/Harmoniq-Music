import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/track_tile.dart';

class FavoritesScreen extends StatelessWidget {
  final VoidCallback? onExplore;

  const FavoritesScreen({super.key, this.onExplore});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final player = context.watch<AudioPlayerProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Music Library',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text(
                              'Favorites',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                              ),
                              child: Text(
                                '${favorites.count}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (favorites.favorites.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.textMuted),
                      tooltip: 'Clear Favorites',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surfaceElevated,
                            title: const Text('Clear All Favorites?'),
                            content: const Text('This will remove all saved songs from your favorites list.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () {
                                  favorites.clearAll();
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Clear All', style: TextStyle(color: AppColors.accent)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Play All & Shuffle Buttons
            if (favorites.favorites.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          player.playPlaylist(favorites.favorites, startIndex: 0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'Play All Favorites',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (!player.isShuffle) player.toggleShuffle();
                        player.playPlaylist(favorites.favorites, startIndex: 0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.primaryLight.withOpacity(0.3)),
                        ),
                      ),
                      child: const Icon(Icons.shuffle_rounded, size: 22, color: AppColors.secondaryLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Body List
            Expanded(
              child: favorites.favorites.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: favorites.favorites.length,
                      itemBuilder: (context, index) {
                        final track = favorites.favorites[index];
                        return TrackTile(
                          track: track,
                          playlist: favorites.favorites,
                          index: index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Heart your favorite tracks to build your personal collection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            if (onExplore != null)
              ElevatedButton.icon(
                onPressed: onExplore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(color: AppColors.secondary.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Explore Online Music', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
