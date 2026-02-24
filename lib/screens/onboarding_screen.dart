import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../constants/text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;

  void _next() {
    if (_page == 0) {
      setState(() => _page = 1);
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _page == 0
              ? _OnboardingPage(
                  key: const ValueKey(0),
                  title: AppStrings.onboarding1Title,
                  body: AppStrings.onboarding1Body,
                  ctaLabel: AppStrings.onboarding1Cta,
                  onCta: _next,
                )
              : _OnboardingPage(
                  key: const ValueKey(1),
                  title: AppStrings.onboarding2Title,
                  body: AppStrings.onboarding2Body,
                  ctaLabel: AppStrings.onboarding2Cta,
                  onCta: _next,
                ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;

  const _OnboardingPage({
    super.key,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        // Stretch forces the Column to fill the available width even when
        // AnimatedSwitcher passes loose constraints via its internal Stack.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 3),
          Text(
            title,
            style: AppTextStyles.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            body,
            style: AppTextStyles.subheading,
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 4),
          // Center keeps the circular button at mid-width despite stretch.
          Center(child: _PrimaryButton(label: ctaLabel, onTap: onCta)),
          const SizedBox(height: 44),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.buttonBackground,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.buttonPrimary,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
