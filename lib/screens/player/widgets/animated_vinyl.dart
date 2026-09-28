import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AnimatedVinyl extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;
  final double size;

  const AnimatedVinyl({
    super.key,
    required this.imageUrl,
    required this.isPlaying,
    this.size = 280,
  });

  @override
  State<AnimatedVinyl> createState() => _AnimatedVinylState();
}

class _AnimatedVinylState extends State<AnimatedVinyl>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedVinyl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double recordSize = widget.size;
    final double centerSize = recordSize * 0.42;

    return Center(
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * 3.1415926535,
            child: child,
          );
        },
        child: Container(
          width: recordSize,
          height: recordSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0F1117),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.2),
                blurRadius: 50,
                spreadRadius: 8,
              ),
            ],
            gradient: const RadialGradient(
              colors: [
                Color(0xFF232733),
                Color(0xFF141722),
                Color(0xFF090A0E),
                Color(0xFF1B1F2D),
                Color(0xFF0B0C10),
              ],
              stops: [0.0, 0.45, 0.65, 0.85, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vinyl Grooves Circles
              ...List.generate(5, (index) {
                final double r = recordSize * (0.55 + index * 0.08);
                return Container(
                  width: r,
                  height: r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.04),
                      width: 1,
                    ),
                  ),
                );
              }),

              // Center Album Cover
              Container(
                width: centerSize,
                height: centerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryLight.withOpacity(0.5),
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceElevated,
                      child: const Icon(Icons.music_note, color: AppColors.secondary),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/app_logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Spindle Hole
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  border: Border.all(
                    color: Colors.white24,
                    width: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
