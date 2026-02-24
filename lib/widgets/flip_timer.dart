import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/text_styles.dart';
import '../constants/colors.dart';

/// Flip-clock digit panel.
///
/// Animation feel:
///   Flip-out  → ease-in  (digit accelerates away like a falling flap)
///   Flip-in   → ease-out (digit decelerates as it settles into place)
///   Tiny Y-scale squish at the pivot gives physical weight.
class FlipTimer extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const FlipTimer({super.key, required this.text, this.style});

  @override
  State<FlipTimer> createState() => _FlipTimerState();
}

class _FlipTimerState extends State<FlipTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late String _currentText;
  late String _nextText;

  @override
  void initState() {
    super.initState();
    _currentText = widget.text;
    _nextText = widget.text;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didUpdateWidget(FlipTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _nextText = widget.text;
      _controller.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _currentText = _nextText);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? AppTextStyles.timerHuge;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final isFirstHalf = t < 0.5;
        final displayText = isFirstHalf ? _currentText : _nextText;

        double angle;
        double opacity;
        double scaleY;

        if (isFirstHalf) {
          // Ease-in: digit accelerates away (falling flap)
          final et = Curves.easeIn.transform(t * 2);
          angle = -(math.pi / 2) * et;
          opacity = 1.0 - et;
          scaleY = 1.0 - 0.06 * et; // very slight compress at pivot
        } else {
          // Ease-out: digit decelerates into place
          final et = Curves.easeOut.transform((t - 0.5) * 2);
          angle = (math.pi / 2) * (1.0 - et);
          opacity = et;
          scaleY = 0.94 + 0.06 * et; // expand back to full
        }

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0008) // perspective
          ..rotateX(angle)
          ..scale(1.0, scaleY, 1.0);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Text(
              displayText,
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

/// Colon separator — pulses gently during countdown.
class TimerColon extends StatefulWidget {
  final bool animate;
  final TextStyle? style;

  const TimerColon({super.key, this.animate = false, this.style});

  @override
  State<TimerColon> createState() => _TimerColonState();
}

class _TimerColonState extends State<TimerColon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(TimerColon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && oldWidget.animate) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ??
        AppTextStyles.timerHuge.copyWith(color: AppColors.secondaryText);
    if (!widget.animate) {
      return Text(':', style: style);
    }
    return FadeTransition(
      opacity: Tween<double>(begin: 0.25, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Text(':', style: style),
    );
  }
}

/// Full MM:SS display — digits animate independently.
class FlipTimerDisplay extends StatelessWidget {
  final String timeString;
  final TextStyle? style;
  final bool colonAnimate;

  const FlipTimerDisplay({
    super.key,
    required this.timeString,
    this.style,
    this.colonAnimate = false,
  });

  @override
  Widget build(BuildContext context) {
    final parts = timeString.split(':');
    final minutes = parts.isNotEmpty ? parts[0] : '00';
    final seconds = parts.length > 1 ? parts[1] : '00';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FlipTimer(text: minutes, style: style),
        TimerColon(animate: colonAnimate, style: style),
        FlipTimer(text: seconds, style: style),
      ],
    );
  }
}
