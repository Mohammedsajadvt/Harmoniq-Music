import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/language_picker_sheet.dart';
import '../../widgets/track_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (_controller.text.trim().isNotEmpty) {
        context.read<MusicProvider>().search(_controller.text.trim(), loadMore: true);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, MusicProvider music) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      music.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final player = context.watch<AudioPlayerProvider>();
    final hasLang = music.selectedLanguage.code.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header Bar with Language Selector Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryLight.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        onChanged: (text) => _onSearchChanged(text, music),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search tracks, creators, vibes...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.secondary, size: 22),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 20),
                                  onPressed: () {
                                    _controller.clear();
                                    music.clearSearch();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => LanguagePickerSheet.show(context),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: hasLang
                            ? AppColors.secondary.withOpacity(0.2)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasLang
                              ? AppColors.secondary
                              : AppColors.primaryLight.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          children: [
                            Text(music.selectedLanguage.flag, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: hasLang ? AppColors.secondary : AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Quick Suggestions Chips
            if (_controller.text.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'TRENDING SEARCHES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight.withOpacity(0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ApiConstants.genres.length - 1,
                  itemBuilder: (context, index) {
                    final tag = ApiConstants.genres[index + 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        label: Text(
                          '#$tag',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: Colors.white.withOpacity(0.08)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onPressed: () {
                          _controller.text = tag;
                          music.search(tag);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Search Content / Results
            Expanded(
              child: _buildSearchBody(music, player),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBody(MusicProvider music, AudioPlayerProvider player) {
    if (music.isSearching) {
      return const Center(
        child: SpinKitWave(color: AppColors.secondary, size: 36),
      );
    }

    if (_controller.text.trim().isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceElevated.withOpacity(0.5),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.saved_search_rounded,
                  size: 54,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Explore Jamendo Library',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Search for independent songs, creators, and moods',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (music.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No results for "${music.lastSearchQuery}"',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try searching with different keywords or genre names',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: music.searchResults.length,
      itemBuilder: (context, index) {
        final track = music.searchResults[index];
        return TrackTile(
          track: track,
          playlist: music.searchResults,
          index: index,
        );
      },
    );
  }
}
