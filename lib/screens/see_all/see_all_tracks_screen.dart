import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/track_model.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/track_tile.dart';
import '../player/widgets/mini_player_bar.dart';

class SeeAllTracksScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<TrackModel> tracks;
  final bool isGenreView;
  final String? genre;

  const SeeAllTracksScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.tracks,
    this.isGenreView = false,
    this.genre,
  });

  @override
  State<SeeAllTracksScreen> createState() => _SeeAllTracksScreenState();
}

class _SeeAllTracksScreenState extends State<SeeAllTracksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  void _loadMore() {
    final music = context.read<MusicProvider>();
    if (widget.isGenreView && widget.genre != null) {
      music.fetchGenreTracks(widget.genre!, loadMore: true);
    } else if (widget.title.contains('Trending')) {
      music.fetchTrendingTracks(loadMore: true);
    } else if (widget.title.contains('Upcoming')) {
      music.fetchUpcomingTracks(loadMore: true);
    } else if (widget.title.contains('Epidemic')) {
      music.fetchRoyaltyFreeTracks(loadMore: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final player = context.watch<AudioPlayerProvider>();

    // Select dynamic track pool
    final rawTracks = widget.isGenreView
        ? music.genreTracks
        : (widget.title.contains('Trending')
            ? music.trendingTracks
            : (widget.title.contains('Upcoming')
                ? music.upcomingTracks
                : (widget.title.contains('Epidemic') ? music.royaltyFreeTracks : widget.tracks)));

    final filteredTracks = _filterText.isEmpty
        ? rawTracks
        : rawTracks.where((t) {
            final query = _filterText.toLowerCase();
            return t.name.toLowerCase().contains(query) ||
                t.artistName.toLowerCase().contains(query) ||
                t.albumName.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.92),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (widget.icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 18, color: AppColors.secondary),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${rawTracks.length} tracks • Spotify Music',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background ambient flare
          Positioned(
            top: 0,
            left: 60,
            right: 60,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Action Header: Search bar + Play All / Shuffle
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search inside tracks
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() {
                                  _filterText = val.trim();
                                });
                              },
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Filter inside ${widget.title}...',
                                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                                suffixIcon: _filterText.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _filterText = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Play All & Shuffle Buttons
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: filteredTracks.isEmpty
                                        ? null
                                        : () {
                                            player.playPlaylist(filteredTracks, startIndex: 0);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                                    label: const Text(
                                      'Play All',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: IconButton(
                                  onPressed: filteredTracks.isEmpty
                                      ? null
                                      : () {
                                          final shuffled = List<TrackModel>.from(filteredTracks)..shuffle();
                                          player.playPlaylist(shuffled, startIndex: 0);
                                        },
                                  icon: const Icon(Icons.shuffle_rounded, color: AppColors.secondary, size: 20),
                                  tooltip: 'Shuffle Play',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Track List
                  if (filteredTracks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.music_off_rounded, size: 48, color: AppColors.textMuted.withOpacity(0.6)),
                            const SizedBox(height: 12),
                            Text(
                              _filterText.isNotEmpty ? 'No tracks matching "$_filterText"' : 'No tracks available',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = filteredTracks[index];
                          return TrackTile(
                            track: track,
                            playlist: filteredTracks,
                            index: index,
                          );
                        },
                        childCount: filteredTracks.length,
                      ),
                    ),

                  if (music.isLoadingTrending || music.isLoadingGenre || music.isLoadingUpcoming || music.isLoadingRoyaltyFree)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),
            ),
          ),

          // Docked Mini Player
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: const MiniPlayerBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
