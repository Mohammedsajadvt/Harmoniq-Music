import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/album_model.dart';
import '../../models/track_model.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/track_tile.dart';
import '../player/widgets/mini_player_bar.dart';

class AlbumDetailScreen extends StatefulWidget {
  final AlbumModel album;

  const AlbumDetailScreen({
    super.key,
    required this.album,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<TrackModel> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbumTracks();
  }

  Future<void> _loadAlbumTracks() async {
    setState(() => _isLoading = true);
    final music = context.read<MusicProvider>();
    final tracks = await music.getAlbumTracks(widget.album);
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
              // Dynamic Sliver App Bar with Album Cover Art
              SliverAppBar(
                expandedHeight: 320,
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
                      // Blurred Ambient Background
                      CachedNetworkImage(
                        imageUrl: widget.album.image,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Image.asset('assets/images/album1.jpg', fit: BoxFit.cover),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              AppColors.background.withOpacity(0.8),
                              AppColors.background,
                            ],
                          ),
                        ),
                      ),

                      // Album Center Artwork
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),
                            Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CachedNetworkImage(
                                  imageUrl: widget.album.image,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Image.asset('assets/images/album1.jpg', fit: BoxFit.cover),
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

              // Album Info & Action Bar
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.album.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_rounded, size: 14, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                widget.album.artistName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                              if (widget.album.releasedate.isNotEmpty) ...[
                                const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                                Text(
                                  widget.album.releasedate.split('-').first,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Play Album & Shuffle Controls
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
                                      'Play Album (${_tracks.length})',
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
                                  tooltip: 'Shuffle Album',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
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
                      'No tracks found for this album.',
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
