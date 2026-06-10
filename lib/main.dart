import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'features/auth/state/auth_state.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'widgets/bottom_nav.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/vocab_screen.dart';
import 'screens/flashcard_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/result_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'features/speaking/screens/speaking_practice_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[STARTUP] Step 1: Flutter binding initialized');

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[FLUTTER_ERROR] ${details.exceptionAsString()}');
  };

  try {
    await dotenv.load(fileName: ".env");
    debugPrint('[STARTUP] Step 2: dotenv loaded — keys: ${dotenv.env.keys}');
  } catch (e, st) {
    debugPrint('[STARTUP] Step 2: dotenv FAILED — $e');
    debugPrint('$st');
    // Continue without .env — the app can still function using --dart-define
    // values or hardcoded defaults. Do NOT block the entire UI.
  }

  debugPrint('[STARTUP] Step 3: runApp');
  runApp(const ProviderScope(child: SakuraApp()));
}

class SakuraApp extends ConsumerWidget {
  const SakuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Sakura',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: SplashScreen(
        onDone: () => _openInitialRoute(ref),
      ),
      navigatorKey: _GlobalKey.navKey,
      routes: {
        '/onboarding': (c) =>
            OnboardingScreen(onDone: () => _nav(c, '/login', replace: true)),
        '/login': (c) => LoginScreen(
              onLogin: () => _nav(c, '/main', clearStack: true),
              onRegister: () => _nav(c, '/register'),
              onForgotPassword: () => _nav(c, '/forgot-password'),
            ),
        '/register': (c) => RegisterScreen(
              onDone: () => _nav(c, '/main', clearStack: true),
              onLogin: () => Navigator.pop(c),
            ),
        '/forgot-password': (c) => ForgotPasswordScreen(
              onBack: () => Navigator.pop(c),
            ),
        '/main': (_) => const MainShell(),
        '/flashcard': (_) => const FlashcardScreen(),
        '/quiz': (c) => QuizScreen(
            onDone: (score) =>
                Navigator.pushReplacementNamed(c, '/result', arguments: score)),
        '/result': (c) {
          final score = (ModalRoute.of(c)!.settings.arguments as int?) ?? 8;
          return ResultScreen(
            score: score,
            total: 10,
            onRetry: () => _nav(c, '/quiz', replace: true),
            onContinue: () => _nav(c, '/main', replace: true),
          );
        },
        '/settings': (c) => SettingsScreen(onLogout: () async {
              await ref.read(authControllerProvider.notifier).logout();
              _navFromRoot('/login', clearStack: true);
            }),
        '/speaking': (_) => const SpeakingPracticeScreen(),
      },
    );
  }

  Future<void> _openInitialRoute(WidgetRef ref) async {
    debugPrint('[NAV] _openInitialRoute start');
    bool isAuthenticated = false;
    try {
      isAuthenticated = await ref
          .read(authControllerProvider.notifier)
          .restoreSession()
          .timeout(const Duration(seconds: 5));
      debugPrint('[NAV] restoreSession result: $isAuthenticated');
    } catch (e) {
      debugPrint('[NAV] restoreSession failed/timed out: $e');
      // On failure or timeout, treat as unauthenticated — show onboarding.
    }
    final route = isAuthenticated ? '/main' : '/onboarding';
    debugPrint('[NAV] navigating to: $route');
    _navFromRoot(route, clearStack: true);
  }

  void _navFromRoot(String route, {bool clearStack = false}) {
    final navigator = _GlobalKey.navKey.currentState;
    if (navigator == null) return;
    if (clearStack) {
      navigator.pushNamedAndRemoveUntil(route, (_) => false);
      return;
    }
    navigator.pushNamed(route);
  }

  void _nav(
    BuildContext c,
    String route, {
    bool replace = false,
    bool clearStack = false,
  }) {
    if (clearStack) {
      Navigator.pushNamedAndRemoveUntil(c, route, (_) => false);
      return;
    }
    if (replace) {
      Navigator.pushReplacementNamed(c, route);
      return;
    }
    Navigator.pushNamed(c, route);
  }
}

class _GlobalKey {
  static final navKey = GlobalKey<NavigatorState>();
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onStartLesson: () => Navigator.pushNamed(context, '/flashcard'),
        onSeeAllPractice: () => setState(() => _index = 1),
        onStartQuiz: () => Navigator.pushNamed(context, '/quiz'),
        onStartSpeaking: () => Navigator.pushNamed(context, '/speaking'),
        onOpenSaved: () => setState(() => _index = 2),
      ),
      CategoriesScreen(
          onPick: (_) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: AppColors.bg,
                    body: VocabScreen(
                        onStart: () =>
                            Navigator.pushNamed(context, '/flashcard')),
                  ),
                ),
              )),
      SavedScreen(onReview: () => Navigator.pushNamed(context, '/flashcard')),
      ProfileScreen(
          onSettings: () => Navigator.pushNamed(context, '/settings')),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: pages[_index],
      bottomNavigationBar:
          AppBottomNav(index: _index, onTap: (i) => setState(() => _index = i)),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.psychology_rounded, color: Colors.white),
              label: const Text('Quiz',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              onPressed: () => Navigator.pushNamed(context, '/quiz'),
            )
          : null,
    );
  }
}
