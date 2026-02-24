import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';

class StorageService {
  static const String _sessionsBoxName = 'sessions';
  static const String _onboardingKey = 'onboarding_complete';

  // Timer state persistence keys
  static const String _timerPhaseKey = 'timer_phase';
  static const String _sessionStartedAtKey = 'session_started_at';
  static const String _countdownEndedAtKey = 'countdown_ended_at';

  late final Box<Session> _sessionsBox;
  late final SharedPreferences _prefs;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SessionAdapter());
    _sessionsBox = await Hive.openBox<Session>(_sessionsBoxName);
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Onboarding ──────────────────────────────────────────────────────────────

  bool get hasCompletedOnboarding =>
      _prefs.getBool(_onboardingKey) ?? false;

  Future<void> markOnboardingComplete() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  // ── Sessions ─────────────────────────────────────────────────────────────────

  Future<void> saveSession(Session session) async {
    await _sessionsBox.put(session.id, session);
  }

  List<Session> getSessions() {
    final sessions = _sessionsBox.values.toList();
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  // ── Timer state (for background restoration) ─────────────────────────────────

  Future<void> saveTimerState({
    required String phase,
    required DateTime? sessionStartedAt,
    required DateTime? countdownEndedAt,
  }) async {
    await _prefs.setString(_timerPhaseKey, phase);
    if (sessionStartedAt != null) {
      await _prefs.setInt(
        _sessionStartedAtKey,
        sessionStartedAt.millisecondsSinceEpoch,
      );
    } else {
      await _prefs.remove(_sessionStartedAtKey);
    }
    if (countdownEndedAt != null) {
      await _prefs.setInt(
        _countdownEndedAtKey,
        countdownEndedAt.millisecondsSinceEpoch,
      );
    } else {
      await _prefs.remove(_countdownEndedAtKey);
    }
  }

  Map<String, dynamic> loadTimerState() {
    final phase = _prefs.getString(_timerPhaseKey) ?? 'idle';
    final startedAtMs = _prefs.getInt(_sessionStartedAtKey);
    final endedAtMs = _prefs.getInt(_countdownEndedAtKey);
    return {
      'phase': phase,
      'sessionStartedAt': startedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(startedAtMs)
          : null,
      'countdownEndedAt': endedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(endedAtMs)
          : null,
    };
  }

  Future<void> clearTimerState() async {
    await _prefs.remove(_timerPhaseKey);
    await _prefs.remove(_sessionStartedAtKey);
    await _prefs.remove(_countdownEndedAtKey);
  }
}
