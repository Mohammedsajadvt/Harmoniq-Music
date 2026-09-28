import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AnimatedGradientText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final List<Color>? colors;
  final Duration duration;

  const AnimatedGradientText({
    super.key,
    required this.text,
    this.style,
    this.colors,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ??
        [
          AppColors.secondary,
          AppColors.primary,
          AppColors.accent,
          AppColors.secondaryLight,
        ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: colors,
              begin: Alignment(-1.0 + (_controller.value * 2.0), -0.5),
              end: Alignment(1.0 + (_controller.value * 2.0), 0.5),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style ??
                const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
        );
      },
    );
  }
}
