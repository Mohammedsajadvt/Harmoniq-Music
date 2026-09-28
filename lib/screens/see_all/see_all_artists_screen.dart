import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/artist_model.dart';
import '../../providers/music_provider.dart';
import '../../widgets/creator_profile_sheet.dart';
import '../player/widgets/mini_player_bar.dart';
import 'artist_detail_screen.dart';

class SeeAllArtistsScreen extends StatefulWidget {
  final List<ArtistModel> initialArtists;

  const SeeAllArtistsScreen({
    super.key,
    required this.initialArtists,
  });

  @override
  State<SeeAllArtistsScreen> createState() => _SeeAllArtistsScreenState();
}

class _SeeAllArtistsScreenState extends State<SeeAllArtistsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ArtistModel> _artists = [];
  String _filterText = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _artists = widget.initialArtists;
    _fetchMoreArtists();
  }

  Future<void> _fetchMoreArtists() async {
    if (_artists.length >= 50) return;
    setState(() => _isLoading = true);
    final music = context.read<MusicProvider>();
    final extended = await music.fetchAllArtists(limit: 50);
    if (mounted) {
      setState(() {
        _artists = extended.isNotEmpty ? extended : widget.initialArtists;
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
    final filteredArtists = _filterText.isEmpty
        ? _artists
        : _artists.where((a) {
            final query = _filterText.toLowerCase();
            return a.name.toLowerCase().contains(query);
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
              'Top Creators & Artists',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_artists.length} spotlight indie musicians',
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
          // Ambient background flare
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
              constraints: const BoxConstraints(maxWidth: 950),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Creator Special Spotlight Card (Mohammed Sajad VT)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: GestureDetector(
                        onTap: () => CreatorProfileSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2C1654), Color(0xFF1B0B2E), Color(0xFF0F081D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.neonGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'MS',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Mohammed Sajad VT',
                                            style: TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.verified_rounded, size: 16, color: AppColors.secondary),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'App Creator & Lead Developer',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '@mohammed.sajad.vt',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => CreatorProfileSheet.openInstagram(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text(
                                  'Instagram',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Search / Filter Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                            hintText: 'Search creators & artists...',
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

                  // Responsive Artists Grid
                  if (filteredArtists.isEmpty && !_isLoading)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off_rounded, size: 48, color: AppColors.textMuted.withOpacity(0.6)),
                            const SizedBox(height: 12),
                            Text(
                              _filterText.isNotEmpty ? 'No artists matching "$_filterText"' : 'No artists found',
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
                          maxCrossAxisExtent: 160,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final artist = filteredArtists[index];
                            return _buildArtistCard(context, artist);
                          },
                          childCount: filteredArtists.length,
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

  Widget _buildArtistCard(BuildContext context, ArtistModel artist) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArtistDetailScreen(artist: artist),
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
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular photo with verified border
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryLight.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: artist.image,
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
            const SizedBox(height: 8),

            // Artist Name
            Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),

            // Explore hint
            const Text(
              'Explore Tracks',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
