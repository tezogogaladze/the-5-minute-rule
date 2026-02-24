import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';
import 'services/timer_controller.dart';
import 'constants/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Dark status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final storage = StorageService();
  await storage.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider(
          create: (_) => TimerController(storage),
        ),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The 5-Minute Rule',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: _RootRouter(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        primary: AppColors.accent,
        onPrimary: AppColors.primaryText,
        onSurface: AppColors.primaryText,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.primaryText),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final onboardingDone = storage.hasCompletedOnboarding;

    if (!onboardingDone) {
      return OnboardingScreen(
        onComplete: () async {
          await storage.markOnboardingComplete();
          // Rebuild so Navigator shows HomeScreen
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              AppRoute(page: const HomeScreen()),
            );
          }
        },
      );
    }

    return const HomeScreen();
  }
}
