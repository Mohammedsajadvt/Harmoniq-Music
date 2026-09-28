import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/animated_gradient_text.dart';
import '../widgets/creator_profile_sheet.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'player/widgets/equalizer_visualizer.dart';
import 'player/widgets/mini_player_bar.dart';
import 'search/search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final player = context.watch<AudioPlayerProvider>();

    final List<Widget> screens = [
      const HomeScreen(),
      const SearchScreen(),
      FavoritesScreen(
        onExplore: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: _buildTopAppBar(context, player),
      ),
      body: Stack(
        children: [
          // Background ambient gradient flare
          Positioned(
            top: 0,
            left: 50,
            right: 50,
            height: 250,
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

          // Current Screen View (Max width centered for tablets/desktop)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ),

          // Docked MiniPlayer and Floating Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Persistent Mini Player Bar (Constrained for tablets/desktop)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: const MiniPlayerBar(),
                  ),
                ),

                // Floating Glass Bottom Nav Bar (Constrained for tablets/desktop)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: _buildBottomNav(context, favorites),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, AudioPlayerProvider player) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 350;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo & Animated Title
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isVeryCompact ? 30 : 36,
                        height: isVeryCompact ? 30 : 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_logo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedGradientText(
                        text: 'HARMONIQ',
                        style: TextStyle(
                          fontSize: isVeryCompact ? 17 : 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: isVeryCompact ? 0.8 : 1.2,
                        ),
                      ),
                    ],
                  ),

                  // Creator Badge & Live Equalizer Visualizer
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (player.isPlaying) ...[
                        const EqualizerVisualizer(
                          isPlaying: true,
                          barCount: 4,
                          maxHeight: 16,
                          width: 2.2,
                          gradient: AppColors.neonGradient,
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Creator Profile Button (Mohammed Sajad VT)
                      GestureDetector(
                        onTap: () => CreatorProfileSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.neonGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'Sajad VT',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    FavoritesProvider favorites,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Container(
      margin: EdgeInsets.fromLTRB(isCompact ? 12 : 24, 4, isCompact ? 12 : 24, 12),
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Discover',
                isCompact: isCompact,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.search_rounded,
                label: 'Search',
                isCompact: isCompact,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.favorite_rounded,
                label: 'Favorites',
                badgeCount: favorites.count,
                isCompact: isCompact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int? badgeCount,
    Color? badgeColor,
    bool isCompact = false,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? (isCompact ? 8 : 12) : (isCompact ? 6 : 10),
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: AppColors.primaryLight.withOpacity(0.4), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: isCompact ? 19 : 21,
                  color: isSelected ? AppColors.secondary : AppColors.textMuted,
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: badgeColor ?? AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
