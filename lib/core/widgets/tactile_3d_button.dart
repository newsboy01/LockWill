import 'package:flutter/material.dart';

/// Nút bấm nổi khối 3D phong cách ứng dụng thiếu nhi (nhấn lún xuống mượt mà).
class Tactile3DButton extends StatefulWidget {
  const Tactile3DButton({
    super.key,
    required this.onPressed,
    required this.color,
    required this.shadowColor,
    required this.child,
    this.borderRadius = 22,
    this.depth = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  final VoidCallback? onPressed;
  final Color color;
  final Color shadowColor;
  final Widget child;
  final double borderRadius;
  final double depth;
  final EdgeInsetsGeometry padding;

  @override
  State<Tactile3DButton> createState() => _Tactile3DButtonState();
}

class _Tactile3DButtonState extends State<Tactile3DButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final offset = _pressed ? widget.depth : 0.0;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: SizedBox(
        child: Stack(
          children: [
            // Lớp đế 3D phía dưới
            Container(
              margin: EdgeInsets.only(top: widget.depth),
              padding: widget.padding,
              decoration: BoxDecoration(
                color: enabled ? widget.shadowColor : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: Opacity(opacity: 0, child: widget.child),
            ),
            // Mặt nút nổi bóng phía trên
            AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              transform: Matrix4.translationValues(0, offset, 0),
              padding: widget.padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: enabled
                      ? [
                          Color.lerp(widget.color, Colors.white, 0.14)!,
                          widget.color,
                        ]
                      : [Colors.grey.shade300, Colors.grey.shade300],
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: Center(child: widget.child),
            ),
          ],
        ),
      ),
    );
  }
}
