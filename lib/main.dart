import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/habit_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/notifications_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationsHelper.init();

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: HabitosApp(showOnboarding: !onboardingCompleted),
    ),
  );
}

class HabitosApp extends StatelessWidget {
  final bool showOnboarding;

  const HabitosApp({Key? key, this.showOnboarding = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Hábitos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: showOnboarding ? const OnboardingScreen() : const MainNavigationScreen(),
    );
  }
}
