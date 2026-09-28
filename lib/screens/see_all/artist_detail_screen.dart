import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/artist_model.dart';
import '../../models/track_model.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/track_tile.dart';
import '../player/widgets/mini_player_bar.dart';

class ArtistDetailScreen extends StatefulWidget {
  final ArtistModel artist;

  const ArtistDetailScreen({
    super.key,
    required this.artist,
  });

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  List<TrackModel> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistTracks();
  }

  Future<void> _loadArtistTracks() async {
    setState(() => _isLoading = true);
    final music = context.read<MusicProvider>();
    final tracks = await music.getArtistTracks(widget.artist);
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Artist Banner Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred background
                      CachedNetworkImage(
                        imageUrl: widget.artist.image,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: AppColors.surface),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              AppColors.background.withOpacity(0.85),
                              AppColors.background,
                            ],
                          ),
                        ),
                      ),

                      // Artist Avatar & Verified badge
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 25),
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.secondary, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: widget.artist.image,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: AppColors.surfaceElevated,
                                    child: const Icon(Icons.person, color: AppColors.textMuted),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppColors.surfaceElevated,
                                    child: const Icon(Icons.person, color: AppColors.secondary),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Artist Info & Controls
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.artist.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, size: 20, color: AppColors.secondary),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Featured Independent Musician',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Play Top Tracks & Shuffle
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.neonGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.4),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _tracks.isEmpty
                                        ? null
                                        : () {
                                            player.playPlaylist(_tracks, startIndex: 0);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                    label: Text(
                                      'Play Top Tracks (${_tracks.length})',
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: IconButton(
                                  onPressed: _tracks.isEmpty
                                      ? null
                                      : () {
                                          final shuffled = List<TrackModel>.from(_tracks)..shuffle();
                                          player.playPlaylist(shuffled, startIndex: 0);
                                        },
                                  icon: const Icon(Icons.shuffle_rounded, color: AppColors.secondary, size: 22),
                                  tooltip: 'Shuffle Artist Tracks',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Tracks List or Loading
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: SpinKitPulse(color: AppColors.secondary, size: 40),
                    ),
                  ),
                )
              else if (_tracks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No tracks found for this artist.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = _tracks[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 850),
                          child: TrackTile(
                            track: track,
                            playlist: _tracks,
                            index: index,
                          ),
                        ),
                      );
                    },
                    childCount: _tracks.length,
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
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
