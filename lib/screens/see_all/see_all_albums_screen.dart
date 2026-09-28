import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/album_model.dart';
import '../../providers/music_provider.dart';
import '../player/widgets/mini_player_bar.dart';
import 'album_detail_screen.dart';

class SeeAllAlbumsScreen extends StatefulWidget {
  final List<AlbumModel> initialAlbums;

  const SeeAllAlbumsScreen({
    super.key,
    required this.initialAlbums,
  });

  @override
  State<SeeAllAlbumsScreen> createState() => _SeeAllAlbumsScreenState();
}

class _SeeAllAlbumsScreenState extends State<SeeAllAlbumsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AlbumModel> _albums = [];
  String _filterText = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _albums = widget.initialAlbums;
    _fetchMoreAlbums();
  }

  Future<void> _fetchMoreAlbums() async {
    if (_albums.length >= 50) return;
    setState(() => _isLoading = true);
    final music = context.read<MusicProvider>();
    final extended = await music.fetchAllAlbums(limit: 50);
    if (mounted) {
      setState(() {
        _albums = extended.isNotEmpty ? extended : widget.initialAlbums;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAlbums = _filterText.isEmpty
        ? _albums
        : _albums.where((a) {
            final query = _filterText.toLowerCase();
            return a.name.toLowerCase().contains(query) || a.artistName.toLowerCase().contains(query);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Featured Albums',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_albums.length} complete records & collections',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
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
                    AppColors.secondary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Search / Filter header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Container(
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
                            hintText: 'Search albums or artists...',
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
                    ),
                  ),

                  // Responsive Albums Grid
                  if (filteredAlbums.isEmpty && !_isLoading)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.album_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.6)),
                            const SizedBox(height: 12),
                            Text(
                              _filterText.isNotEmpty ? 'No albums matching "$_filterText"' : 'No albums found',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final album = filteredAlbums[index];
                            return _buildAlbumCard(context, album);
                          },
                          childCount: filteredAlbums.length,
                        ),
                      ),
                    ),

                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: SpinKitPulse(color: AppColors.secondary, size: 30)),
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

  Widget _buildAlbumCard(BuildContext context, AlbumModel album) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AlbumDetailScreen(album: album),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Artwork with play overlay badge
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: album.image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.album, color: AppColors.textMuted),
                        ),
                        errorWidget: (_, __, ___) => Image.asset('assets/images/album1.jpg', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),

            // Artist
            Text(
              album.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
