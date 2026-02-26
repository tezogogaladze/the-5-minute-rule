# App Store review readiness: Timer, lifecycle, edge cases

**App:** The 5-Minute Rule (Flutter iOS)  
**Goal:** Verify timer behavior, lifecycle, and edge cases are App Store review–safe.

---

## 1. Confirmations needed from you

Please confirm (or correct) these so the checklist and fixes match your intent:

| # | Question | Inferred from code | Your answer |
|---|----------|--------------------|-------------|
| **A** | **iOS minimum version** | **13.0** (from `ios/Runner.xcodeproj` and Podfile) | Confirm or state different. |
| **B** | **Local notifications for timer completion?** | **No** — no notification code or permissions. Timer completion is in-app only (countdown → countup; user taps Stop → Completion screen). | Confirm. |
| **C** | **Background behavior** | **Restore on return.** No background execution; timer truth is from stored `sessionStartedAt` / `countdownEndedAt` + `DateTime.now()` on resume. No “running” UI in background. | Confirm: “restore state on return” only, no background visuals. |

---

## 2. Codebase audit: where timer state can break

### 2.1 App lifecycle (background / foreground / terminated)

| Location | Current behavior | Risk / note |
|----------|------------------|-------------|
| `lib/services/timer_controller.dart` | `WidgetsBindingObserver.didChangeAppLifecycleState`: on **paused** or **inactive** → `_persistState()`. On **resumed** → `_onResume()` (restart ticker, snap countdown→countup if elapsed). | **Good.** Persist on pause/inactive; recompute from timestamps on resume. |
| `TimerController` ctor | Registers as `WidgetsBindingObserver`; calls `_restoreFromStorage()`. | **Good.** Restore only on process start (cold start). |
| `_restoreFromStorage()` | Restores `countdown` or `countup` from SharedPreferences; if countdown and `elapsed >= 300`, snaps to countup; starts ticker. | **Good.** Handles “app killed during countdown/countup” and “backgrounded past 5 min.” |
| `_onResume()` | Restarts ticker; if countdown and `countdownRemaining <= 0`, sets `_countdownEndedAt = _sessionStartedAt! + 5min`, switches to countup, persists. | **Good.** Boundary is exact (based on timestamps). |

**Gap:** If the app is **killed while in Completion screen** (before user taps Done), we restore phase `complete` and treat as idle (no TimerScreen). User loses the “just finished” session unless they had already triggered save — but save happens on Done. So “kill on Completion before Done” = session not saved, state correctly reset to idle. Document as intended.

---

### 2.2 Screen lock / unlock

| Item | Behavior | Risk |
|------|----------|------|
| Lock | App goes **inactive** then **paused**. We persist and (when suspended) ticker stops. | OK. |
| Unlock | App **resumed**. We run `_onResume()`: ticker restarts, time from timestamps. | OK. No special handling needed. |

---

### 2.3 Interruptions (call, notification banner, Siri, Control Center)

| Item | Behavior | Risk |
|------|----------|------|
| Incoming call (full-screen) | Typically **inactive** (and possibly **paused**). We persist; on return we resume from timestamps. | OK. |
| Notification banner / Control Center swipe | Often **inactive** only; may not go to **paused**. We persist on **inactive**. | OK. |
| Siri | Same as above. | OK. |

No audio session or “now playing” — no audio focus handling needed.

---

### 2.4 Low power mode

| Item | Behavior | Risk |
|------|----------|------|
| Timer.periodic(250ms) | May be throttled when app is backgrounded; we don’t rely on it for truth. | **OK.** Elapsed time is always from `DateTime.now()` minus stored timestamps. |
| Wakelock | `WakelockPlus.enable()` during session; screen may still dim/lock per system. | Document: we prevent sleep during active session where supported; if OS suspends, we restore on resume. |

---

### 2.5 Time changes (manual clock change, DST, timezone)

| Item | Behavior | Risk |
|------|----------|------|
| **Stored values** | We persist `sessionStartedAt` and `countdownEndedAt` as **epoch milliseconds** (`SharedPreferences`). Restore with `DateTime.fromMillisecondsSinceEpoch()`. | Epoch is unambiguous; DST/timezone don’t change stored meaning. |
| **Elapsed / remaining** | `DateTime.now().difference(_sessionStartedAt!).inSeconds` (and same for countup). | **Risk:** If the user **sets the device clock backward**, `difference` can be negative. |
| **countdownRemaining** | `(kCountdownSeconds - elapsed).clamp(0, kCountdownSeconds)`. | **Safe:** clamped. |
| **countupElapsed** | No clamp. If `now < _countdownEndedAt` (e.g. clock set back), returns **negative** seconds. | **Bug:** Can show negative or wrong countup. **Fix:** Clamp to >= 0. |
| **totalDurationSeconds** | `_stoppedAt ?? DateTime.now()` minus `_sessionStartedAt`. | Can go negative if clock set back before stop; edge case. Clamp to >= 0 for display. |

**Recommendation:** Clamp `countupElapsed` to `>= 0` and (if used for display) ensure total duration is never negative.

---

### 2.6 Audio focus / session

No audio playback or recording in the app. No audio focus or session handling required.

---

### 2.7 Device rotation / Dynamic Type / accessibility

| Item | Current | Risk |
|------|---------|------|
| **Rotation** | `SystemChrome.setPreferredOrientations([portraitUp, portraitDown])`; iPad Info.plist has all four for multitasking. | Portrait-only on phone; no layout jump from rotation on phone. |
| **Dynamic Type** | No explicit scaling; fixed font sizes in `AppTextStyles`. | Acceptable for minimal app; no timer layout dependency on text size. |
| **Accessibility** | No specific audit in this doc. | Suggest basic VoiceOver pass; no change to timer logic. |

---

### 2.8 Hot reload / dev-only

Timer state is in a `ChangeNotifier` backed by SharedPreferences. Hot reload can leave phase/ticker out of sync with UI; **production builds don’t hot reload.** No change needed for release.

---

## 3. Timer implementation correctness

| Requirement | Status | Detail |
|-------------|--------|--------|
| **Do not rely on Timer drift for truth** | **Met.** | Elapsed time is always `DateTime.now() - _sessionStartedAt` (countdown) or `DateTime.now() - _countdownEndedAt` (countup). The 250ms ticker only triggers UI updates and transition check. |
| **Monotonic / stored start + delta** | **Met.** | We use wall-clock timestamps (`DateTime`) stored at start and at countdown→countup; deltas on each tick and on resume. (Dart has no monotonic API; wall clock + clamp handles normal use; time-change edge case above.) |
| **Background time** | **Met.** | On resume we don’t add “background duration” separately; we recompute from the same stored timestamps and current `DateTime.now()`, so background duration is included. |
| **Countdown → countup boundary** | **Exact.** | Transition happens in `_onTick()` when `countdownRemaining <= 0`; remaining is derived from `DateTime.now() - _sessionStartedAt`. So boundary is exact at 5:00. |

**Single code fix recommended:** Clamp `countupElapsed` (and optionally total duration) to avoid negative values when the system clock is set backward.

---

## 4. Release checklist — manual test cases

Execute on a **physical device** (iOS 13+), Release or TestFlight build. Optional: enable debug logging (Section 5) and watch console.

### 4.1 Lifecycle

| # | Test | Steps | Expected | What to check |
|---|------|--------|----------|----------------|
| L1 | Background during countdown | Start timer → wait ~1 min → Home button (or swipe up) → wait 2 min → reopen app. | Timer shows ~3 min remaining (or 0:00 and then countup if you waited 5+ min). | No jump; time matches wall clock. |
| L2 | Background past 5 min | Start → background immediately → wait 5+ min → reopen. | Timer shows countup (e.g. 05:00, 05:01, …). | No longer in countdown; countup reflects elapsed time since 5 min. |
| L3 | Kill during countdown | Start → wait ~1 min → force-quit app → reopen. | Timer screen shows with ~4 min remaining (or correct remaining). | Restored from storage; no crash. |
| L4 | Kill during countup | Start → wait 5:30 (or use time change for speed) → force-quit → reopen. | Timer screen in countup, time consistent. | Restored countup; display correct. |
| L5 | Kill on Completion before Done | Run to Completion screen → force-quit before tapping Done. | Reopen → Home (idle). Session not in History. | State reset to idle; no orphan “complete” state. |

### 4.2 Interruptions

| # | Test | Steps | Expected |
|---|------|--------|----------|
| I1 | Incoming call | Start timer → receive call → answer → hang up. | App in foreground; timer still correct (recomputed from timestamps). |
| I2 | Notification banner | Start → pull notification banner (or have one appear). | Dismiss → timer unchanged. |
| I3 | Control Center | Start → open Control Center → close. | Timer unchanged. |

### 4.3 Lock / unlock

| # | Test | Steps | Expected |
|---|------|--------|----------|
| U1 | Lock during countdown | Start → lock device → wait 1 min → unlock. | Timer shows 1 min less remaining. |
| U2 | Lock during countup | Be in countup → lock → wait 30 s → unlock. | Countup increased by ~30 s. |

### 4.4 Time change (manual)

| # | Test | Steps | Expected |
|---|------|--------|----------|
| T1 | Clock set backward in countdown | Start → wait 1 min → Settings → set time back 2 min → return to app. | Remaining can show > 4 min (or clamp); no crash. After fix: countup never negative. |
| T2 | Clock set forward past 5 min | Start → set clock forward 10 min → return. | Timer in countup; time reasonable (or clamped). |

### 4.5 UI / layout

| # | Test | Steps | Expected |
|---|------|--------|----------|
| V1 | Clock position | Home → Start → Timer → Completion. | Clock does not jump; same vertical position on all three. |
| V2 | Keyboard on Completion | Completion screen → tap task field → keyboard opens. | Field sits just above keyboard; Done button fixed; tap outside dismisses keyboard. |
| V3 | No resize on timer | On Timer screen, pull down notification center or trigger keyboard (if any). | Clock and layout don’t shift (resizeToAvoidBottomInset: false). |

### 4.6 Boundaries

| # | Test | Steps | Expected |
|---|------|--------|----------|
| B1 | Exactly 5:00 | Start and wait 5:00 (or mock time). | At 0:00, one transition to countup; haptic; no double transition. |
| B2 | Stop and Done | Countup → Stop → name task → Done. | Session in History; Home (or History if you change navigation). |

---

## 5. Lightweight instrumentation (optional, debug-only)

Add only if you need to **prove** behavior during review or debugging.

- **Gate:** `kDebugMode` (from `package:flutter/foundation.dart`) so nothing runs in release unless you add a separate flag.
- **Log (no analytics, no permissions):**
  - Lifecycle: `didChangeAppLifecycleState` (state name).
  - Timer: on `startCountdown`, `_transitionToCountup`, `stop`, `reset`: log phase + key timestamps (e.g. `sessionStartedAt`, `countdownEndedAt`).
  - On `_onResume` and `_restoreFromStorage`: log restored phase and computed remaining/elapsed.
- **Format:** `debugPrint('[Timer] ...')` or a small `if (kDebugMode) log(...)` helper.

Suggested location: `lib/services/timer_controller.dart` — a few lines at lifecycle and transition points. No new dependencies.

---

## 6. Actionable code changes

### 6.1 Clamp countupElapsed (and total duration) for time-change robustness

**File:** `lib/services/timer_controller.dart`

**1) countupElapsed (line ~46–49):** Clamp so it’s never negative (e.g. user set clock back).

```dart
  int get countupElapsed {
    if (_countdownEndedAt == null) return 0;
    final secs = DateTime.now().difference(_countdownEndedAt!).inSeconds;
    return secs < 0 ? 0 : secs;
  }
```

**2) totalDurationSeconds (line ~64–68):** Clamp to avoid negative duration if clock was set back before stop.

```dart
  int get totalDurationSeconds {
    if (_sessionStartedAt == null) return 0;
    final end = _stoppedAt ?? DateTime.now();
    final secs = end.difference(_sessionStartedAt!).inSeconds;
    return secs < 0 ? 0 : secs;
  }
```

### 6.2 (Optional) Done → History

You previously discussed sending user to History after Done. Currently completion navigates to Home. If you want History:

**File:** `lib/screens/completion_screen.dart`  
**Line ~66–68:** Replace `HomeScreen()` with `HistoryScreen()` and use a navigation that replaces the stack so Back doesn’t return to Completion (e.g. `pushAndRemoveUntil` with route predicate to leave History or Home as root).

---

## 7. Reviewer attack plan: 10 likely attempts and defenses

| # | Reviewer move | Defense |
|---|----------------|----------|
| 1 | Background app during countdown, wait 5+ min, reopen | We persist on pause/inactive; on resume we recompute from `_sessionStartedAt` and snap to countup if elapsed ≥ 5 min. Timer shows countup. |
| 2 | Force-quit during countdown, reopen | We restore from SharedPreferences in `_restoreFromStorage()` and show Timer with correct remaining time. |
| 3 | Force-quit during countup, reopen | Same; we restore countup and `_countdownEndedAt`; countup time is recomputed from now. |
| 4 | Answer phone call during timer | App goes inactive/paused; we persist. On return we resume from timestamps. No crash, correct time. |
| 5 | Lock device during countdown, unlock after a while | Resume runs; ticker restarts; time from timestamps. |
| 6 | Change device time backward during countup | After fix: `countupElapsed` clamped to ≥ 0; no negative display. |
| 7 | Start timer, open Control Center / notification | Inactive triggers persist; no timer logic depending on foreground-only. |
| 8 | Kill app on Completion screen before tapping Done | We treat restored phase `complete` as idle; user lands on Home. Session not saved (by design). |
| 9 | Rapidly Start / leave / return / force-quit | Multiple persist/restore cycles; state should stay consistent (timestamps + phase). Manual test L3/L4. |
| 10 | Check that timer doesn’t “jump” or show wrong time after background | All displayed time is derived from `DateTime.now()` and stored timestamps; no accumulation of periodic tick drift. |

---

## 8. Summary

- **Timer truth:** Correct. Based on stored timestamps + `DateTime.now()`; 250ms ticker is for UI only; countdown→countup is exact.
- **Lifecycle:** Persist on pause/inactive; restore on process start; on resume recompute and optionally snap countdown→countup. No background execution; “restore on return” only.
- **Recommended code change:** Clamp `countupElapsed` and `totalDurationSeconds` to non-negative for clock-change edge cases.
- **Optional:** Debug-only logging for lifecycle and key timer events; Done → History if you want that flow.
- **Checklist:** Run manual cases in Section 4 (lifecycle, interruptions, lock, time change, UI, boundaries) on a device before submit.

After you confirm **A**, **B**, and **C** from Section 1, you can treat this as the release checklist and apply the small code changes above.
