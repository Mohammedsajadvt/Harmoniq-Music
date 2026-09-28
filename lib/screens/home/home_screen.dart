import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/album_model.dart';
import '../../models/artist_model.dart';
import '../../models/track_model.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/creator_profile_sheet.dart';
import '../../widgets/language_picker_sheet.dart';
import '../../widgets/section_header.dart';
import '../../widgets/track_tile.dart';
import '../see_all/album_detail_screen.dart';
import '../see_all/artist_detail_screen.dart';
import '../see_all/see_all_albums_screen.dart';
import '../see_all/see_all_artists_screen.dart';
import '../see_all/see_all_tracks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _trendingScrollController;
  late final ScrollController _upcomingScrollController;
  late final ScrollController _royaltyFreeScrollController;
  late final ScrollController _genreScrollController;
  late final ScrollController _albumsScrollController;
  late final ScrollController _artistsScrollController;
  late final ScrollController _filterChipsScrollController;

  @override
  void initState() {
    super.initState();
    _trendingScrollController = ScrollController();
    _upcomingScrollController = ScrollController();
    _royaltyFreeScrollController = ScrollController();
    _genreScrollController = ScrollController();
    _albumsScrollController = ScrollController();
    _artistsScrollController = ScrollController();
    _filterChipsScrollController = ScrollController();
  }

  @override
  void dispose() {
    _trendingScrollController.dispose();
    _upcomingScrollController.dispose();
    _royaltyFreeScrollController.dispose();
    _genreScrollController.dispose();
    _albumsScrollController.dispose();
    _artistsScrollController.dispose();
    _filterChipsScrollController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🎧';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final player = context.watch<AudioPlayerProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.secondary,
        backgroundColor: AppColors.surface,
        onRefresh: () => music.loadHomeData(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Sliver Header with Dynamic Greeting & Hero
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Discover Soundscapes',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hero Featured Card (Shown when 'All' is selected)
            if (music.selectedGenre.toLowerCase() == 'all')
              SliverToBoxAdapter(
                child: _buildHeroBanner(context, music, player),
              ),

            // Genre / Mood Horizontal Filter Chips with Language Picker
            SliverToBoxAdapter(
              child: _buildGenreFilter(context, music, controller: _filterChipsScrollController),
            ),

            // === SPECIFIC GENRE VIEW (When any filter like Chillout, Pop, Rock is selected) ===
            if (music.selectedGenre.toLowerCase() != 'all') ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: '${music.selectedGenre} Hits & Spotlight',
                  subtitle: 'Live API stream • Top ${music.selectedGenre} tracks',
                  icon: Icons.electric_bolt_rounded,
                  scrollController: _genreScrollController,
                  onSeeAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SeeAllTracksScreen(
                          title: '${music.selectedGenre} Vibes',
                          subtitle: 'Curated Spotify & iTunes tracks for ${music.selectedGenre}',
                          icon: Icons.queue_music_rounded,
                          tracks: music.genreTracks,
                          isGenreView: true,
                          genre: music.selectedGenre,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _buildTrackCarousel(
                  music.genreTracks,
                  player,
                  controller: _genreScrollController,
                  isLoading: music.isLoadingGenre && music.genreTracks.isEmpty,
                ),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'All ${music.selectedGenre} Songs',
                  subtitle: '${music.genreTracks.length} tracks loaded from API',
                  icon: Icons.queue_music_rounded,
                  onSeeAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SeeAllTracksScreen(
                          title: '${music.selectedGenre} Vibes',
                          subtitle: 'Full API library for ${music.selectedGenre}',
                          icon: Icons.queue_music_rounded,
                          tracks: music.genreTracks,
                          isGenreView: true,
                          genre: music.selectedGenre,
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildGenreTrackList(music, player),
            ],

            // === GLOBAL HOME VIEW (When 'All' is selected) ===
            if (music.selectedGenre.toLowerCase() == 'all') ...[
              // Trending Hits Section
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Trending Hits',
                  subtitle: 'Top worldwide charts',
                  icon: Icons.local_fire_department_rounded,
                  scrollController: _trendingScrollController,
                  onSeeAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SeeAllTracksScreen(
                          title: 'Trending Hits',
                          subtitle: 'Top charts from Spotify & Global feeds',
                          icon: Icons.local_fire_department_rounded,
                          tracks: music.trendingTracks,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _buildTrackCarousel(
                  music.trendingTracks,
                  player,
                  controller: _trendingScrollController,
                  isLoading: music.isLoadingTrending && music.trendingTracks.isEmpty,
                ),
              ),

              // Upcoming & Fresh Drops Section
              if (music.upcomingTracks.isNotEmpty || music.isLoadingUpcoming) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Upcoming & Fresh Drops',
                    subtitle: 'Latest single & album releases 2026',
                    icon: Icons.fiber_new_rounded,
                    scrollController: _upcomingScrollController,
                    onSeeAll: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SeeAllTracksScreen(
                            title: 'Upcoming & Fresh Drops',
                            subtitle: 'New music releases & upcoming tracks',
                            icon: Icons.fiber_new_rounded,
                            tracks: music.upcomingTracks,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildTrackCarousel(
                    music.upcomingTracks,
                    player,
                    controller: _upcomingScrollController,
                    isLoading: music.isLoadingUpcoming && music.upcomingTracks.isEmpty,
                  ),
                ),
              ],

              // Epidemic Sound Royalty-Free Creator Hits
              if (music.royaltyFreeTracks.isNotEmpty || music.isLoadingRoyaltyFree) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Epidemic Sound Hits',
                    subtitle: 'Studio-grade royalty-free creator tracks',
                    icon: Icons.verified_user_rounded,
                    scrollController: _royaltyFreeScrollController,
                    onSeeAll: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SeeAllTracksScreen(
                            title: 'Epidemic Sound Hits',
                            subtitle: 'Royalty-free music library for creators',
                            icon: Icons.verified_user_rounded,
                            tracks: music.royaltyFreeTracks,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildTrackCarousel(
                    music.royaltyFreeTracks,
                    player,
                    controller: _royaltyFreeScrollController,
                    isLoading: music.isLoadingRoyaltyFree && music.royaltyFreeTracks.isEmpty,
                  ),
                ),
              ],
            ],

            // Featured Albums Section
            if (music.featuredAlbums.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Featured Albums',
                  subtitle: 'Curated Spotify records',
                  icon: Icons.album_rounded,
                  scrollController: _albumsScrollController,
                  onSeeAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SeeAllAlbumsScreen(
                          initialAlbums: music.featuredAlbums,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _buildAlbumsList(music.featuredAlbums, player, controller: _albumsScrollController),
              ),
            ],

            // Popular Artists
            if (music.popularArtists.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Top Creators',
                  subtitle: 'Spotlight musicians & producers',
                  icon: Icons.person_rounded,
                  scrollController: _artistsScrollController,
                  onSeeAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SeeAllArtistsScreen(
                          initialArtists: music.popularArtists,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _buildArtistsList(music.popularArtists, controller: _artistsScrollController),
              ),
            ],

            // Creator Spotlight Section (Mohammed Sajad VT)
            SliverToBoxAdapter(
              child: _buildCreatorSpotlight(context),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 120), // Bottom padding for miniplayer & nav
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorSpotlight(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: GestureDetector(
        onTap: () => CreatorProfileSheet.show(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E1035),
                Color(0xFF0F0B26),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.secondary.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
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
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Full Creator Info (Multi-line, NO "..." truncation)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Line 1: Creator Name & Verified Icon
                    const Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Mohammed Sajad VT',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.verified_rounded, size: 16, color: AppColors.secondary),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Line 2: Role
                    const Text(
                      'App Creator & Lead Developer',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Line 3: Instagram ID Pill (Complete, no dots!)
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

              // Info Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_rounded, size: 13, color: AppColors.secondary),
                    SizedBox(width: 3),
                    Text(
                      'Info',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    MusicProvider music,
    AudioPlayerProvider player,
  ) {
    if (music.isLoadingTrending && music.trendingTracks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.surfaceElevated.withOpacity(0.5),
            border: Border.all(color: Colors.white10),
          ),
          child: const Center(
            child: SpinKitWave(color: AppColors.secondary, size: 28),
          ),
        ),
      );
    }

    if (music.trendingTracks.isEmpty) {
      return const SizedBox.shrink();
    }

    final track = music.trendingTracks.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: AppColors.darkCardGradient,
          border: Border.all(
            color: AppColors.primaryLight.withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Artwork
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Opacity(
                  opacity: 0.35,
                  child: CachedNetworkImage(
                    imageUrl: track.albumImage,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: AppColors.surfaceElevated),
                    errorWidget: (c, u, e) => Container(color: AppColors.surfaceElevated),
                  ),
                ),
              ),
            ),

            // Gradient Tint
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.background.withOpacity(0.9),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 14, color: AppColors.accent),
                            SizedBox(width: 4),
                            Text(
                              'FEATURED SPOTLIGHT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 22),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'By ${track.artistName}',
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          player.playTrack(track, newPlaylist: music.trendingTracks);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text(
                          'Play Track',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildGenreFilter(
    BuildContext context,
    MusicProvider music, {
    ScrollController? controller,
  }) {
    final hasLang = music.selectedLanguage.code.isNotEmpty;

    return SizedBox(
      height: 46,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ApiConstants.genres.length + 1,
        itemBuilder: (context, index) {
          // First item: Language Filter Dropdown Button
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => LanguagePickerSheet.show(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: hasLang
                        ? AppColors.secondary.withOpacity(0.18)
                        : AppColors.surfaceElevated.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: hasLang
                          ? AppColors.secondary
                          : AppColors.primaryLight.withOpacity(0.3),
                      width: 1.2,
                    ),
                    boxShadow: hasLang
                        ? [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.25),
                              blurRadius: 10,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        music.selectedLanguage.flag,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        music.selectedLanguage.name,
                        style: TextStyle(
                          color: hasLang ? AppColors.secondaryLight : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: hasLang ? AppColors.secondary : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final genre = ApiConstants.genres[index - 1];
          final isSelected = music.selectedGenre.toLowerCase() == genre.toLowerCase();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => music.setGenre(genre),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.surface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryLight
                        : Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    genre,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackCarousel(
    List<TrackModel> tracks,
    AudioPlayerProvider player, {
    bool isLoading = false,
    ScrollController? controller,
  }) {
    if (isLoading && tracks.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: SpinKitWave(color: AppColors.secondary, size: 30),
        ),
      );
    }

    if (tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 215,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          final isCurrent = player.currentTrack?.id == track.id;

          return Container(
            width: 145,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => player.playTrack(track, newPlaylist: tracks, index: index),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: track.albumImage,
                          width: 145,
                          height: 145,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(
                            color: AppColors.surfaceElevated,
                            child: const Icon(Icons.music_note, color: AppColors.textMuted),
                          ),
                          errorWidget: (c, u, e) => Image.asset(
                            'assets/images/album2.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isCurrent ? AppColors.neonGradient : null,
                                color: isCurrent ? null : Colors.black87,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 6,
                                  )
                                ],
                              ),
                              child: Icon(
                                isCurrent && player.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? AppColors.secondary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        track.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildAlbumsList(
    List<AlbumModel> albums,
    AudioPlayerProvider player, {
    ScrollController? controller,
  }) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AlbumDetailScreen(album: album),
                ),
              );
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: album.image,
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.album, color: AppColors.textMuted),
                      ),
                      errorWidget: (c, u, e) => Image.asset(
                        'assets/images/album1.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
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
                  Text(
                    album.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtistsList(
    List<ArtistModel> artists, {
    ScrollController? controller,
  }) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArtistDetailScreen(artist: artist),
                ),
              );
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryLight.withOpacity(0.4), width: 1.5),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: artist.image,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.person, color: AppColors.textMuted),
                        ),
                        errorWidget: (c, u, e) => Container(
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.person, color: AppColors.secondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenreTrackList(MusicProvider music, AudioPlayerProvider player) {
    if (music.isLoadingGenre && music.genreTracks.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 100,
          child: Center(
            child: SpinKitPulse(color: AppColors.secondary, size: 36),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = music.genreTracks[index];
          return TrackTile(
            track: track,
            playlist: music.genreTracks,
            index: index,
          );
        },
        childCount: music.genreTracks.length,
      ),
    );
  }
}
