import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class EqualizerVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double maxHeight;
  final double width;
  final Color? color;
  final Gradient? gradient;

  const EqualizerVisualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 4,
    this.maxHeight = 22,
    this.width = 3,
    this.color,
    this.gradient,
  });

  @override
  State<EqualizerVisualizer> createState() => _EqualizerVisualizerState();
}

class _EqualizerVisualizerState extends State<EqualizerVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late List<double> _targetHeights;
  late List<double> _currentHeights;

  @override
  void initState() {
    super.initState();
    _currentHeights = List.generate(widget.barCount, (_) => 4.0);
    _targetHeights = List.generate(widget.barCount, (_) => 8.0);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(_updateHeights);

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  void _updateHeights() {
    if (!widget.isPlaying) return;
    if (_controller.status == AnimationStatus.forward && _controller.value > 0.9) {
      for (int i = 0; i < widget.barCount; i++) {
        _currentHeights[i] = _targetHeights[i];
        _targetHeights[i] = 4.0 + _random.nextDouble() * (widget.maxHeight - 4.0);
      }
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(EqualizerVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(widget.barCount, (index) {
        double height = 4.0;
        if (widget.isPlaying) {
          final t = _controller.value;
          final start = _currentHeights[index];
          final end = _targetHeights[index];
          height = start + (end - start) * t;
        }

        return Container(
          width: widget.width,
          height: height.clamp(3.0, widget.maxHeight),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.width / 2),
            gradient: widget.gradient ?? AppColors.primaryGradient,
            color: widget.gradient == null ? (widget.color ?? AppColors.secondary) : null,
          ),
        );
      }),
    );
  }
}
