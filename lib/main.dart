import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// Themes
import 'package:study_voice_ai/core/theme/app_theme.dart';

// Services
import 'package:study_voice_ai/services/auth_service.dart';
import 'package:study_voice_ai/services/database_service.dart';
import 'package:study_voice_ai/services/storage_service.dart';
import 'package:study_voice_ai/services/tts_service.dart';
import 'package:study_voice_ai/services/ai_service.dart';
import 'package:study_voice_ai/services/notification_service.dart';

// ViewModels
import 'package:study_voice_ai/viewmodels/auth_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/library_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/player_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/stats_viewmodel.dart';
import 'package:study_voice_ai/views/settings/settings_screen.dart'; // contains ThemeProvider

// Screens
import 'package:study_voice_ai/views/auth/splash_screen.dart';
import 'package:study_voice_ai/views/auth/login_screen.dart';
import 'package:study_voice_ai/views/auth/signup_screen.dart';
import 'package:study_voice_ai/views/auth/forgot_pw_screen.dart';
import 'package:study_voice_ai/views/dashboard/main_layout.dart';
import 'package:study_voice_ai/views/player/tts_player_screen.dart';
import 'package:study_voice_ai/views/quiz/quiz_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase Initialization
  try {
    await Firebase.initializeApp();
    debugPrint("Firebase successfully initialized cloud services!");
  } catch (e) {
    debugPrint("------------------------------------------------------------------");
    debugPrint("Firebase core not initialized. Running in Local Sync Fallback Mode!");
    debugPrint("To enable cloud sync, download your 'google-services.json' file");
    debugPrint("and place it inside the 'android/app/' directory.");
    debugPrint("------------------------------------------------------------------");
  }

  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<TtsService>(create: (_) => TtsService()),
        Provider<AiService>(create: (_) => AiService()),
        Provider<NotificationService>(create: (_) => NotificationService()),

        // Global Notifier for Theme
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),

        // ViewModels binding services
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<LibraryViewModel>(
          create: (context) => LibraryViewModel(
            dbService: context.read<DatabaseService>(),
            storageService: context.read<StorageService>(),
            aiService: context.read<AiService>(),
          ),
        ),
        ChangeNotifierProvider<PlayerViewModel>(
          create: (context) => PlayerViewModel(
            ttsService: context.read<TtsService>(),
            dbService: context.read<DatabaseService>(),
          ),
        ),
        ChangeNotifierProvider<StatsViewModel>(
          create: (context) => StatsViewModel(
            dbService: context.read<DatabaseService>(),
          ),
        ),
      ],
      child: const StudyVoiceAiApp(),
    ),
  );
}

class StudyVoiceAiApp extends StatelessWidget {
  const StudyVoiceAiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'StudyVoice',
      debugShowCheckedModeBanner: false,
      
      // Themes binding
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      // Routing Map
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-pw': (context) => const ForgotPwScreen(),
        '/home': (context) => const MainLayout(),
        '/player': (context) => const TtsPlayerScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
