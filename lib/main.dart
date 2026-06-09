import 'package:flutter/material.dart';
import 'core/network/auth_api.dart';
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

void main() => runApp(const SakuraApp());

class SakuraApp extends StatelessWidget {
  const SakuraApp({super.key});

  static final _authApi = AuthApi();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sakura',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: SplashScreen(
        onDone: _openInitialRoute,
      ),
      navigatorKey: _GlobalKey.navKey,
      routes: {
        '/onboarding': (c) =>
            OnboardingScreen(onDone: () => _nav(c, '/login', replace: true)),
        '/login': (c) => LoginScreen(
              onLogin: () => _nav(c, '/main', clearStack: true),
              onRegister: () => _nav(c, '/register'),
            ),
        '/register': (c) => RegisterScreen(
              onDone: () => _nav(c, '/main', clearStack: true),
              onLogin: () => Navigator.pop(c),
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
              await _authApi.logout();
              _navFromRoot('/login', clearStack: true);
            }),
        '/speaking': (_) => const SpeakingPracticeScreen(),
      },
    );
  }

  Future<void> _openInitialRoute() async {
    final hasToken = await _authApi.hasSavedToken();
    _navFromRoot(hasToken ? '/main' : '/onboarding', clearStack: true);
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
