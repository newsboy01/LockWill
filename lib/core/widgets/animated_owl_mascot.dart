import 'dart:math' as math;
import 'package:flutter/material.dart';

enum OwlMood { idle, happy, encourage }

/// Nhân vật Cú mèo chuyển động mượt mà (nhún thở, chớp mắt, nhảy mừng khi đúng, lắc nhẹ khích lệ khi sai).
class AnimatedOwlMascot extends StatefulWidget {
  const AnimatedOwlMascot({
    super.key,
    this.mood = OwlMood.idle,
    this.size = 110,
  });

  final OwlMood mood;
  final double size;

  @override
  State<AnimatedOwlMascot> createState() => _AnimatedOwlMascotState();
}

class _AnimatedOwlMascotState extends State<AnimatedOwlMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        double dy = math.sin(t * math.pi) * 6;
        double angle = 0;
        double scale = 1.0;

        if (widget.mood == OwlMood.happy) {
          dy = -math.sin(t * math.pi).abs() * 14;
          scale = 1.0 + math.sin(t * math.pi) * 0.08;
        } else if (widget.mood == OwlMood.encourage) {
          angle = math.sin(t * math.pi * 2) * 0.08;
        }

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.mood == OwlMood.happy
                ? const [Color(0xFFFFF3B0), Color(0xFFFFCA3A)]
                : (widget.mood == OwlMood.encourage
                    ? const [Color(0xFFFFE5D9), Color(0xFFFFB5A7)]
                    : const [Color(0xFFFFE4B5), Color(0xFFFFC875)]),
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              widget.mood == OwlMood.happy ? '🦉✨' : '🦉',
              style: TextStyle(fontSize: widget.size * 0.48),
            ),
          ],
        ),
      ),
    );
  }
}
