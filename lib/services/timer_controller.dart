import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'storage_service.dart';

enum TimerPhase { idle, countdown, countup, complete }

const int kCountdownSeconds = 300; // 5 minutes

class TimerController extends ChangeNotifier with WidgetsBindingObserver {
  final StorageService _storage;

  TimerController(this._storage) {
    WidgetsBinding.instance.addObserver(this);
    _restoreFromStorage();
  }

  // ── State ────────────────────────────────────────────────────────────────────

  TimerPhase _phase = TimerPhase.idle;
  DateTime? _sessionStartedAt;
  DateTime? _countdownEndedAt;
  DateTime? _stoppedAt;

  Timer? _ticker;

  // Track the last displayed seconds value to drive the flip animation
  int _lastDisplayedSeconds = kCountdownSeconds;

  TimerPhase get phase => _phase;
  DateTime? get sessionStartedAt => _sessionStartedAt;
  DateTime? get countdownEndedAt => _countdownEndedAt;
  DateTime? get stoppedAt => _stoppedAt;

  // ── Computed display values ──────────────────────────────────────────────────

  /// Seconds remaining in countdown (0..300). 0 triggers auto-transition.
  int get countdownRemaining {
    if (_sessionStartedAt == null) return kCountdownSeconds;
    final elapsed =
        DateTime.now().difference(_sessionStartedAt!).inSeconds;
    return (kCountdownSeconds - elapsed).clamp(0, kCountdownSeconds);
  }

  /// Seconds elapsed in countup (0..). Displayed as 300 + elapsed.
  /// Clamped to >= 0 so clock set backward never shows negative.
  int get countupElapsed {
    if (_countdownEndedAt == null) return 0;
    final secs = DateTime.now().difference(_countdownEndedAt!).inSeconds;
    return secs < 0 ? 0 : secs;
  }

  /// Total display seconds for the current state (used by both phases).
  int get displaySeconds {
    return switch (_phase) {
      TimerPhase.idle => kCountdownSeconds,
      TimerPhase.countdown => countdownRemaining,
      TimerPhase.countup => kCountdownSeconds + countupElapsed,
      TimerPhase.complete => kCountdownSeconds + countupElapsed,
    };
  }

  int get lastDisplayedSeconds => _lastDisplayedSeconds;

  /// Total session duration in seconds (from Start to Stop press).
  /// Clamped to >= 0 for clock-change robustness.
  int get totalDurationSeconds {
    if (_sessionStartedAt == null) return 0;
    final end = _stoppedAt ?? DateTime.now();
    final secs = end.difference(_sessionStartedAt!).inSeconds;
    return secs < 0 ? 0 : secs;
  }

  static String formatSeconds(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get displayTime => formatSeconds(displaySeconds);

  // ── Actions ──────────────────────────────────────────────────────────────────

  void startCountdown() {
    assert(_phase == TimerPhase.idle);
    _sessionStartedAt = DateTime.now();
    _phase = TimerPhase.countdown;
    _lastDisplayedSeconds = kCountdownSeconds;
    _persistState();
    _startTicker();
    WakelockPlus.enable();
    notifyListeners();
  }

  void stop() {
    assert(_phase == TimerPhase.countup);
    _stoppedAt = DateTime.now();
    _phase = TimerPhase.complete;
    _stopTicker();
    _persistState();
    WakelockPlus.disable();
    notifyListeners();
  }

  void reset() {
    _phase = TimerPhase.idle;
    _sessionStartedAt = null;
    _countdownEndedAt = null;
    _stoppedAt = null;
    _lastDisplayedSeconds = kCountdownSeconds;
    _stopTicker();
    _storage.clearTimerState();
    WakelockPlus.disable();
    notifyListeners();
  }

  // ── Ticker ───────────────────────────────────────────────────────────────────

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _onTick();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onTick() {
    if (_phase == TimerPhase.countdown) {
      final remaining = countdownRemaining;
      final didFlip = remaining != _lastDisplayedSeconds;
      _lastDisplayedSeconds = remaining;

      if (remaining <= 0) {
        _transitionToCountup();
      } else {
        if (didFlip) notifyListeners();
      }
    } else if (_phase == TimerPhase.countup) {
      final current = kCountdownSeconds + countupElapsed;
      if (current != _lastDisplayedSeconds) {
        _lastDisplayedSeconds = current;
        notifyListeners();
      }
    }
  }

  void _transitionToCountup() {
    _countdownEndedAt = DateTime.now();
    _phase = TimerPhase.countup;
    _lastDisplayedSeconds = kCountdownSeconds;
    _persistState();
    _triggerHaptic();
    notifyListeners();
  }

  void _triggerHaptic() {
    HapticFeedback.mediumImpact();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _persistState();
    } else if (state == AppLifecycleState.resumed) {
      _onResume();
    }
  }

  void _onResume() {
    if (_phase == TimerPhase.countdown || _phase == TimerPhase.countup) {
      // Ticker may have been paused; restart it.
      // Time is calculated from stored timestamps, so no drift occurs.
      _startTicker();

      // If we were in countdown and 5 min passed while backgrounded, snap to countup
      if (_phase == TimerPhase.countdown && countdownRemaining <= 0) {
        _countdownEndedAt = _sessionStartedAt!
            .add(const Duration(seconds: kCountdownSeconds));
        _phase = TimerPhase.countup;
        _persistState();
      }
      notifyListeners();
    }
  }

  // ── Persistence ──────────────────────────────────────────────────────────────

  void _persistState() {
    _storage.saveTimerState(
      phase: _phase.name,
      sessionStartedAt: _sessionStartedAt,
      countdownEndedAt: _countdownEndedAt,
    );
  }

  void _restoreFromStorage() {
    final saved = _storage.loadTimerState();
    final phaseName = saved['phase'] as String;
    final sessionStartedAt = saved['sessionStartedAt'] as DateTime?;
    final countdownEndedAt = saved['countdownEndedAt'] as DateTime?;

    if (phaseName == 'idle' || phaseName == 'complete') {
      // Complete sessions are handled by the completion screen before reset;
      // if we're restoring a 'complete' state it means the app was killed on
      // the completion screen — treat it as idle.
      return;
    }

    if (phaseName == 'countdown' && sessionStartedAt != null) {
      _sessionStartedAt = sessionStartedAt;
      final elapsed =
          DateTime.now().difference(sessionStartedAt).inSeconds;
      if (elapsed >= kCountdownSeconds) {
        // Passed 5 min while app was killed/backgrounded
        _countdownEndedAt =
            sessionStartedAt.add(const Duration(seconds: kCountdownSeconds));
        _phase = TimerPhase.countup;
      } else {
        _phase = TimerPhase.countdown;
      }
      _startTicker();
    } else if (phaseName == 'countup' &&
        sessionStartedAt != null &&
        countdownEndedAt != null) {
      _sessionStartedAt = sessionStartedAt;
      _countdownEndedAt = countdownEndedAt;
      _phase = TimerPhase.countup;
      _startTicker();
    }
  }

  // ── Disposal ─────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _stopTicker();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
