import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/text_styles.dart';
import '../constants/colors.dart';

// ── ReelDigit ─────────────────────────────────────────────────────────────────
//
// Single-character reel slot.
//
// Normal tick  : vertical slide, 140 ms, easeInOutCubic.
//                Old digit exits upward; new digit enters from below.
//                Only this digit animates — unchanged digits stay still.
//
// Transition   : 3-D X-axis flip, 340 ms.
//                Marks the 0:00 → 5:00 moment as something different.
//                Uses ease-in (fall away) + ease-out (settle in).
//
// No glow, no gradients, no bounce, no overshoot.

class ReelDigit extends StatefulWidget {
  final String digit;
  final TextStyle? style;
  final bool isTransition;

  const ReelDigit({
    super.key,
    required this.digit,
    this.style,
    this.isTransition = false,
  });

  @override
  State<ReelDigit> createState() => _ReelDigitState();
}

class _ReelDigitState extends State<ReelDigit>
    with SingleTickerProviderStateMixin {
  static const Duration _reelDuration = Duration(milliseconds: 140);
  static const Duration _flipDuration = Duration(milliseconds: 340);

  late AnimationController _controller;
  late String _from;
  late String _to;
  bool _flipMode = false;

  @override
  void initState() {
    super.initState();
    _from = widget.digit;
    _to = widget.digit;
    _controller = AnimationController(vsync: this, duration: _reelDuration);
    _controller.addStatusListener((status) {
      // Once settled, collapse to a single Text so the Stack is gone.
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _from = _to);
      }
    });
  }

  @override
  void didUpdateWidget(ReelDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.digit != oldWidget.digit) {
      setState(() {
        _from = oldWidget.digit;
        _to = widget.digit;
        _flipMode = widget.isTransition;
      });
      _controller.duration =
          widget.isTransition ? _flipDuration : _reelDuration;
      _controller.forward(from: 0);
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

    // Idle — no animation running; single Text, zero overhead.
    if (_from == _to) {
      return Text(widget.digit, style: style, textAlign: TextAlign.center);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_controller.value);
        return _flipMode ? _buildFlip(t, style) : _buildReel(t, style);
      },
    );
  }

  // ── Vertical reel ────────────────────────────────────────────────────────

  Widget _buildReel(double t, TextStyle style) {
    // FractionalTranslation offsets by a fraction of the child's own size,
    // so Offset(0, -1) = "one slot up", Offset(0, 1) = "one slot down".
    // The Stack sizes itself to one digit's layout bounds; ClipRect clips
    // any painted overflow — giving a clean slot-reel appearance.
    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outgoing: centre → top (exits upward)
          FractionalTranslation(
            translation: Offset(0, -t),
            child: Text(_from, style: style, textAlign: TextAlign.center),
          ),
          // Incoming: bottom → centre (rolls in from below)
          FractionalTranslation(
            translation: Offset(0, 1.0 - t),
            child: Text(_to, style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  // ── 3-D flip (transition moment only) ───────────────────────────────────

  Widget _buildFlip(double t, TextStyle style) {
    final isFirstHalf = t < 0.5;
    final displayText = isFirstHalf ? _from : _to;

    double angle;
    double opacity;
    double scaleY;

    if (isFirstHalf) {
      // Ease-in: falls away — accelerates off screen
      final et = Curves.easeIn.transform(t * 2);
      angle = -(math.pi / 2) * et;
      opacity = 1.0 - et;
      scaleY = 1.0 - 0.05 * et;
    } else {
      // Ease-out: settles in — decelerates into place
      final et = Curves.easeOut.transform((t - 0.5) * 2);
      angle = (math.pi / 2) * (1.0 - et);
      opacity = et;
      scaleY = 0.95 + 0.05 * et;
    }

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0008)
      ..rotateX(angle)
      ..scale(1.0, scaleY, 1.0);

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Text(displayText, style: style, textAlign: TextAlign.center),
      ),
    );
  }
}

// ── TimerColon ────────────────────────────────────────────────────────────────

/// Separator colon — pulses gently during countdown, static otherwise.
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

// ── FlipTimerDisplay ──────────────────────────────────────────────────────────

/// Full MM:SS display — four individual ReelDigit slots + colon.
/// Each digit animates independently; unchanged digits stay perfectly still.
class FlipTimerDisplay extends StatelessWidget {
  final String timeString; // "MM:SS"
  final TextStyle? style;
  final bool colonAnimate;
  final bool isTransition;

  const FlipTimerDisplay({
    super.key,
    required this.timeString,
    this.style,
    this.colonAnimate = false,
    this.isTransition = false,
  });

  @override
  Widget build(BuildContext context) {
    final parts = timeString.split(':');
    final mm = parts.isNotEmpty ? parts[0].padLeft(2, '0') : '00';
    final ss = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ReelDigit(digit: mm[0], style: style, isTransition: isTransition),
        ReelDigit(digit: mm[1], style: style, isTransition: isTransition),
        TimerColon(animate: colonAnimate, style: style),
        ReelDigit(digit: ss[0], style: style, isTransition: isTransition),
        ReelDigit(digit: ss[1], style: style, isTransition: isTransition),
      ],
    );
  }
}
