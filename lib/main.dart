import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/theme_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/developer_provider.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';
import 'widgets/hacker_splash_screen.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  tz.initializeTimeZones();
  await initializeNotifications();
  await authService.init();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ProfileProvider(prefs)),
        ChangeNotifierProvider(create: (_) => DeveloperProvider(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: '我的私人助理',
          theme: themeProvider.theme,
          home: _splashDone
              ? const _AppHome()
              : HackerSplashScreen(
                  onComplete: () {
                    setState(() => _splashDone = true);
                  },
                ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    try {
      final versionInfo = await updateService.checkForUpdate();
      if (versionInfo != null && mounted) {
        showUpdateDialog(context, versionInfo);
      }
    } catch (e) {
      debugPrint('检查更新异常: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
