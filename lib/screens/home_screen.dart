import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';
import '../routes.dart';
import '../services/timer_controller.dart';
import 'timer_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final phase = context.read<TimerController>().phase;
      if (phase == TimerPhase.countdown || phase == TimerPhase.countup) {
        Navigator.of(context).pushReplacement(AppRoute(page: const TimerScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Header bar (56 px, matches HistoryScreen exactly) ────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        padding: const EdgeInsets.all(8),
                        icon: SvgPicture.asset(
                          'assets/menu.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            AppColors.secondaryText,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          AppRoute(page: const HistoryScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Timer — true geometric center, never moves ───────────────────
            const Align(
              alignment: Alignment.center,
              child: Text(
                AppStrings.idleTime,
                style: AppTextStyles.timerHuge,
              ),
            ),

            // ── Bottom control zone — fixed, doesn't shift the timer ─────────
            Positioned(
              bottom: 0,
              left: 40,
              right: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StartButton(
                    onTap: () {
                      context.read<TimerController>().startCountdown();
                      Navigator.of(context)
                          .push(AppRoute(page: const TimerScreen()));
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.homeSubtext,
                    style: AppTextStyles.microcopy,
                  ),
                  const SizedBox(height: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.buttonBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: const Text(
            AppStrings.startButton,
            style: AppTextStyles.buttonPrimary,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
