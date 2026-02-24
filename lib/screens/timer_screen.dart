import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../routes.dart';
import '../services/timer_controller.dart';
import '../widgets/flip_timer.dart';
import '../widgets/breathing_timer.dart';
import 'completion_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late TimerController _controller;
  bool _showTransition = false;
  // Initialised in initState from current phase so background-restores
  // mid-countup don't incorrectly trigger the transition animation.
  bool _wasCountup = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<TimerController>();
    _wasCountup = _controller.phase == TimerPhase.countup;
    _controller.addListener(_onPhaseChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onPhaseChange);
    super.dispose();
  }

  void _onPhaseChange() {
    if (!mounted) return;
    final phase = _controller.phase;

    // Detect the exact moment countdown → countup.
    if (phase == TimerPhase.countup && !_wasCountup) {
      _wasCountup = true;
      setState(() => _showTransition = true);
      // Clear the flag after the flip animation completes (340 ms + buffer).
      Future.delayed(const Duration(milliseconds: 420), () {
        if (mounted) setState(() => _showTransition = false);
      });
    }

    if (phase == TimerPhase.complete) {
      Navigator.of(context).pushReplacement(
        AppRoute(page: const CompletionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TimerController>();
    final isCountdown = controller.phase == TimerPhase.countdown;
    final isCountup = controller.phase == TimerPhase.countup;
    // "You crossed it." shows for the first 4 s of count-up, then gives way
    // to "Now you're moving." — both in plain secondary text.
    final inTransitionWindow =
        isCountup && controller.countupElapsed < 4;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        // Timer must never shift — keyboard, buttons, nothing.
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Timer — true geometric center, never moves ─────────────────
              Align(
                alignment: Alignment.center,
                child: BreathingTimer(
                  active: isCountdown,
                  child: FlipTimerDisplay(
                    timeString: controller.displayTime,
                    style: AppTextStyles.timerHuge,
                    colonAnimate: isCountdown,
                    isTransition: _showTransition,
                  ),
                ),
              ),

              // ── Bottom control zone ────────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 40,
                right: 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Microcopy — fixed height so layout never shifts
                    SizedBox(
                      height: 20,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        child: inTransitionWindow
                            ? const Text(
                                AppStrings.youCrossedIt,
                                key: ValueKey('crossed'),
                                style: AppTextStyles.crossedIt,
                                textAlign: TextAlign.center,
                              )
                            : isCountup
                                ? const Text(
                                    AppStrings.nowYoureMoving,
                                    key: ValueKey('moving'),
                                    style: AppTextStyles.microcopy,
                                    textAlign: TextAlign.center,
                                  )
                                : const Text(
                                    AppStrings.countdownSubtext,
                                    key: ValueKey('chose'),
                                    style: AppTextStyles.microcopy,
                                    textAlign: TextAlign.center,
                                  ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stop button — fades in/out without causing any layout shift
                    AnimatedOpacity(
                      opacity: isCountup ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: IgnorePointer(
                        ignoring: !isCountup,
                        child: _StopButton(
                          onTap: () => controller.stop(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 44),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StopButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.stopButton,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.stopButtonText.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            AppStrings.stopButton,
            style: AppTextStyles.buttonPrimary.copyWith(
              color: AppColors.stopButtonText,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
