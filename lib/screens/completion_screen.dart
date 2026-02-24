import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../widgets/flip_timer.dart';
import '../models/session.dart';
import '../routes.dart';
import '../services/storage_service.dart';
import '../services/timer_controller.dart';
import 'home_screen.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  final _taskController = TextEditingController();
  late AnimationController _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _taskController.dispose();
    _fadeIn.dispose();
    super.dispose();
  }

  Future<void> _done(BuildContext context) async {
    final controller = context.read<TimerController>();
    final storage = context.read<StorageService>();

    final startedAt = controller.sessionStartedAt ?? DateTime.now();
    final endedAt = controller.stoppedAt ?? DateTime.now();
    final durationSeconds = controller.totalDurationSeconds;
    final taskName = _taskController.text.trim().isEmpty
        ? AppStrings.untitled
        : _taskController.text.trim();

    final session = Session(
      id: const Uuid().v4(),
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: durationSeconds,
      taskName: taskName,
      createdAt: DateTime.now(),
    );

    await storage.saveSession(session);
    controller.reset();

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      AppRoute(page: const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TimerController>();
    final totalTime = TimerController.formatSeconds(
      controller.totalDurationSeconds,
    );

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    const double doneButtonHeight = 80;
    const double bottomPadding = 44;
    const double fixedStripHeight = doneButtonHeight + bottomPadding;

    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: AppColors.background,
          // Keyboard must never shift the clock or the Done button.
          resizeToAvoidBottomInset: false,
          body: FadeTransition(
            opacity: _fadeIn,
            child: SafeArea(
              child: Stack(
                children: [
                  // ── Clock + label — clock at true geometric center ────────────
                  Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                      offset: const Offset(0, 21),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FlipTimerDisplay(
                            timeString: totalTime,
                            style: AppTextStyles.timerHuge,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            AppStrings.youBegan,
                            style: AppTextStyles.subheading,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Task name input — rises with keyboard, stays above Done ──
                  Positioned(
                    bottom: fixedStripHeight + keyboardHeight,
                    left: 40,
                    right: 40,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.whatWasThis.toUpperCase(),
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _taskController,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primaryText,
                            fontSize: 15,
                          ),
                          cursorColor: AppColors.accent,
                          maxLength: 80,
                          decoration: InputDecoration(
                            hintText: AppStrings.taskHint,
                            hintStyle: AppTextStyles.body,
                            counterText: '',
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.divider,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.accent,
                                width: 1,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _done(context),
                        ),
                      ],
                    ),
                  ),

                  // ── Done button — fixed at bottom, never moves ───────────────
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => _done(context),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: AppColors.buttonBackground,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              AppStrings.doneButton,
                              style: AppTextStyles.buttonPrimary,
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
        ),
      ),
    );
  }
}
