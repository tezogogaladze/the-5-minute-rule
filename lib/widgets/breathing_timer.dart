import 'package:flutter/material.dart';

/// Wraps a child in a very subtle scale breathing animation.
/// Scale oscillates between 1.0 and 1.02 over 4.5 seconds.
class BreathingTimer extends StatefulWidget {
  final Widget child;
  final bool active;

  const BreathingTimer({super.key, required this.child, this.active = true});

  @override
  State<BreathingTimer> createState() => _BreathingTimerState();
}

class _BreathingTimerState extends State<BreathingTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BreathingTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always use the same tree shape so the child's element (and all
    // ReelDigit states inside it) survive the active→inactive phase switch.
    // Changing the structure here would destroy those states before
    // didUpdateWidget can fire, causing the digits to snap instead of animate.
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final scale = widget.active ? _scaleAnimation.value : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
