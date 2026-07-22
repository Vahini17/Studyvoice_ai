import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_voice_ai/core/theme/app_theme.dart';
import 'package:study_voice_ai/core/widgets/glass_card.dart';
import 'package:study_voice_ai/viewmodels/auth_viewmodel.dart';
import 'package:study_voice_ai/services/notification_service.dart';

// Standalone Theme Notifier to control Light/Dark mode state dynamically
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showLanguageSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("App Interface Language"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ListTile(title: Text("English (US)"), trailing: Icon(Icons.check, color: AppTheme.primaryColor)),
              ListTile(title: Text("Hindi (हिंदी)"), enabled: false),
              ListTile(title: Text("Tamil (தமிழ்)"), enabled: false),
              ListTile(title: Text("Telugu (తెలుగు)"), enabled: false),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showAboutApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("About Study Voice AI"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Text(
                "Study Voice AI v1.0.0",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Transforming Study PDFs into Smart Audio Learning.\n\nBuilt with Flutter, Google Text-to-Speech Engine, and Firebase Firestore/Storage. Designed to enable students to study smarter anywhere, anytime.",
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Privacy & Security"),
          content: const SingleChildScrollView(
            child: Text(
              "Your security is our priority:\n\n1. Authenticated Access: All user profiles are locked via secure Firebase Authentication.\n\n2. Private Document Storage: Textbooks uploaded by you are isolated under your private Firebase storage reference, inaccessible to other learners.\n\n3. Local Fallback Cache: PDF extractions remain stored under the sandbox cache directory of your device, minimizing external exposures.\n\n4. Strict Permissions: File storage access is queried only during picking times.",
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Log Out?"),
          content: const Text("Are you sure you want to log out from Study Voice AI? Your offline caches will be preserved on this device."),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Log Out", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      await authVM.signOut();
      if (!context.mounted) return;
      
      // Wipe routing structures back to SplashScreen / login
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings & Preferences ⚙️",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.backgroundGradientDark : null,
          color: isDark ? null : AppTheme.lightBgColor,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Theme Section
              _buildSettingsHeader("APPEARANCE"),
              _buildSettingsCard(
                context,
                [
                  ListTile(
                    title: const Text("Dark Theme Mode"),
                    subtitle: const Text("Enable pitch dark background glow"),
                    leading: const Icon(Icons.dark_mode_rounded, color: AppTheme.primaryColor),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        themeProvider.toggleTheme(val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Preferences Section
              _buildSettingsHeader("STUDY PREFERENCES"),
              _buildSettingsCard(
                context,
                [
                  ListTile(
                    title: const Text("System Language"),
                    subtitle: const Text("English (US)"),
                    leading: const Icon(Icons.language_rounded, color: AppTheme.accentColor),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () => _showLanguageSettings(context),
                  ),
                  const Divider(indent: 56, height: 1),
                  ListTile(
                    title: const Text("Daily Study Reminders"),
                    subtitle: const Text("Remind me to study daily at 9:00 AM"),
                    leading: const Icon(Icons.notifications_active_rounded, color: AppTheme.secondaryColor),
                    trailing: Switch(
                      value: notificationService.isEnabled,
                      activeColor: AppTheme.secondaryColor,
                      onChanged: (val) {
                        notificationService.setNotificationsEnabled(val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Policy Section
              _buildSettingsHeader("ABOUT & POLICIES"),
              _buildSettingsCard(
                context,
                [
                  ListTile(
                    title: const Text("About App"),
                    leading: const Icon(Icons.info_outline_rounded, color: Colors.grey),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () => _showAboutApp(context),
                  ),
                  const Divider(indent: 56, height: 1),
                  ListTile(
                    title: const Text("Privacy & Security Rules"),
                    leading: const Icon(Icons.security_rounded, color: Colors.grey),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text(
                  "Log Out Session",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 6,
                  shadowColor: Colors.redAccent.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
