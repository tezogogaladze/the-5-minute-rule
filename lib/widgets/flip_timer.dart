import 'package:flutter/material.dart';
import '../constants/text_styles.dart';
import '../constants/colors.dart';

// ── ReelDigit ─────────────────────────────────────────────────────────────────
//
// Single-character reel slot.
//
// scrollDown = false (countdown)
//   Old digit exits upward, new digit enters from below.
//
// scrollDown = true (countup)
//   Old digit exits downward, new digit enters from above.
//
// Phase transition (countdown → countup):
//   Detected when scrollDown flips AND the digit jumps by more than one step.
//   Example: ones-of-minutes 0 → 5 plays a cascade: 0→1→2→3→4→5.
//   Each cascade step: 80 ms. Normal single-step tick: 140 ms.
//   All changed digits start their animations simultaneously.
//
// Only digits that actually change animate. Unchanged digits are plain Text.

class ReelDigit extends StatefulWidget {
  final String digit;
  final TextStyle? style;
  final bool scrollDown;

  const ReelDigit({
    super.key,
    required this.digit,
    this.style,
    this.scrollDown = false,
  });

  @override
  State<ReelDigit> createState() => _ReelDigitState();
}

class _ReelDigitState extends State<ReelDigit>
    with SingleTickerProviderStateMixin {
  static const Duration _normalDuration = Duration(milliseconds: 140);
  static const Duration _cascadeDuration = Duration(milliseconds: 80);

  late AnimationController _controller;
  late String _from;
  late String _to;
  bool _scrollDown = false;

  // Pending digits to step through for a cascade animation.
  final List<String> _queue = [];

  @override
  void initState() {
    super.initState();
    _from = widget.digit;
    _to = widget.digit;
    _scrollDown = widget.scrollDown;
    _controller = AnimationController(vsync: this, duration: _normalDuration);
    _controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (_queue.isNotEmpty) {
      setState(() {
        _from = _to;
        _to = _queue.removeAt(0);
      });
      _controller.duration = _cascadeDuration;
      _controller.forward(from: 0);
    } else {
      setState(() => _from = _to);
      _controller.duration = _normalDuration;
    }
  }

  @override
  void didUpdateWidget(ReelDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.digit == oldWidget.digit) return;

    _queue.clear();

    final isPhaseTransition = widget.scrollDown != oldWidget.scrollDown;
    final fromInt = int.tryParse(oldWidget.digit);
    final toInt = int.tryParse(widget.digit);
    final span = (fromInt != null && toInt != null) ? (toInt - fromInt).abs() : 0;

    if (isPhaseTransition && span > 1) {
      // Cascade: roll through every intermediate value between old and new.
      final step = toInt! > fromInt! ? 1 : -1;
      for (int i = fromInt + step * 2; (step > 0 ? i <= toInt : i >= toInt); i += step) {
        _queue.add(i.toString());
      }
      setState(() {
        _from = oldWidget.digit;
        _to = (fromInt + step).toString();
        _scrollDown = widget.scrollDown;
      });
      _controller.duration = _cascadeDuration;
    } else {
      setState(() {
        _from = oldWidget.digit;
        _to = widget.digit;
        _scrollDown = widget.scrollDown;
      });
      _controller.duration = _normalDuration;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? AppTextStyles.timerHuge;

    // Idle — single Text, zero overhead.
    if (_from == _to) {
      return Text(widget.digit, style: style, textAlign: TextAlign.center);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_controller.value);

        // scrollDown = false → sign = -1 → exits upward,   enters from below
        // scrollDown = true  → sign = +1 → exits downward, enters from above
        final sign = _scrollDown ? 1.0 : -1.0;

        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              FractionalTranslation(
                translation: Offset(0, sign * t),
                child: Text(_from, style: style, textAlign: TextAlign.center),
              ),
              FractionalTranslation(
                translation: Offset(0, sign * (t - 1.0)),
                child: Text(_to, style: style, textAlign: TextAlign.center),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── TimerColon ────────────────────────────────────────────────────────────────

/// Static colon separator.
/// Shifted upward by 5 px to compensate for font optical imbalance —
/// the colon glyph sits at x-height centre while digits fill cap height.
class TimerColon extends StatelessWidget {
  final TextStyle? style;

  const TimerColon({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final textStyle = style ??
        AppTextStyles.timerHuge.copyWith(color: AppColors.secondaryText);
    return Transform.translate(
      offset: const Offset(0, -5),
      child: Text(':', style: textStyle),
    );
  }
}

// ── FlipTimerDisplay ──────────────────────────────────────────────────────────

/// Full MM:SS display — four individual ReelDigit slots + colon.
/// [scrollDown] flips the reel direction: false = countdown, true = countup.
class FlipTimerDisplay extends StatelessWidget {
  final String timeString;
  final TextStyle? style;
  final bool scrollDown;

  const FlipTimerDisplay({
    super.key,
    required this.timeString,
    this.style,
    this.scrollDown = false,
  });

  @override
  Widget build(BuildContext context) {
    final parts = timeString.split(':');
    final mm = (parts.isNotEmpty ? parts[0] : '00').padLeft(2, '0');
    final ss = (parts.length > 1 ? parts[1] : '00').padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ReelDigit(digit: mm[0], style: style, scrollDown: scrollDown),
        ReelDigit(digit: mm[1], style: style, scrollDown: scrollDown),
        TimerColon(style: style),
        ReelDigit(digit: ss[0], style: style, scrollDown: scrollDown),
        ReelDigit(digit: ss[1], style: style, scrollDown: scrollDown),
      ],
    );
  }
}
