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

  @override
  void initState() {
    super.initState();
    _controller = context.read<TimerController>();
    _controller.addListener(_onPhaseChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onPhaseChange);
    super.dispose();
  }

  void _onPhaseChange() {
    if (!mounted) return;
    if (_controller.phase == TimerPhase.complete) {
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
              // ── Timer — same band as Home/Completion (top 56, bottom 164) ───
              Positioned(
                top: 56, // reserve header height so clock doesn't shift from Home
                bottom: 164, // microcopy 20 + 20 + 80 + 44
                left: 0,
                right: 0,
                child: Center(
                  child: BreathingTimer(
                    active: isCountdown,
                    child: FlipTimerDisplay(
                      timeString: controller.displayTime,
                      style: AppTextStyles.timerHuge,
                      scrollDown: isCountup,
                    ),
                  ),
                ),
              ),

              // ── Bottom control zone ────────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.stopButton,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          AppStrings.stopButton,
          style: AppTextStyles.buttonPrimary.copyWith(
            color: AppColors.stopButtonText,
          ),
        ),
      ),
    );
  }
}
