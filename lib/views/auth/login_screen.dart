import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_voice_ai/core/theme/app_theme.dart';
import 'package:study_voice_ai/core/widgets/custom_button.dart';
import 'package:study_voice_ai/core/widgets/custom_textfield.dart';
import 'package:study_voice_ai/core/widgets/glass_card.dart';
import 'package:study_voice_ai/viewmodels/auth_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/stats_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final statsVM = Provider.of<StatsViewModel>(context, listen: false);

    final success = await authVM.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _rememberMe,
    );

    if (success && mounted) {
      // Navigate immediately — don't wait for stats to load
      Navigator.pushReplacementNamed(context, '/home');
      // Load stats in background after navigation
      if (authVM.user != null) {
        statsVM.initStats(authVM.user!).catchError((e) {
          debugPrint('Stats init error (non-blocking): $e');
        });
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage ?? "Sign in failed. Please check your credentials."),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final statsVM = Provider.of<StatsViewModel>(context, listen: false);

    final success = await authVM.signInWithGoogle();

    if (success && mounted) {
      // Navigate immediately — don't wait for stats to load
      Navigator.pushReplacementNamed(context, '/home');
      // Load stats in background
      if (authVM.user != null) {
        statsVM.initStats(authVM.user!).catchError((e) {
          debugPrint('Stats init error (non-blocking): $e');
        });
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage ?? "Google Sign-In failed"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.backgroundGradientDark : null,
          color: isDark ? null : AppTheme.lightBgColor,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            height: size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Heading
                Text(
                  "Welcome Back! 👋",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Log in to resume converting PDFs into audio",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Form details inside GlassCard
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _emailController,
                          labelText: "Email Address",
                          hintText: "Enter your email",
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.isEmpty) return "Email is required";
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                              return "Enter a valid email address";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _passwordController,
                          labelText: "Password",
                          hintText: "Enter your password",
                          prefixIcon: Icons.lock_outlined,
                          isPassword: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) return "Password is required";
                            if (val.length < 6) return "Password must be at least 6 characters";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Remember Me and Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppTheme.primaryColor,
                                    onChanged: (val) {
                                      setState(() {
                                        _rememberMe = val ?? true;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Remember Me",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/forgot-pw');
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Login button
                        Consumer<AuthViewModel>(
                          builder: (context, authVM, _) {
                            return CustomButton(
                              text: "Sign In",
                              isLoading: authVM.isLoading,
                              onPressed: _handleLogin,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OR CONTINUE WITH",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),

                // Google sign in button
                ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: Image.network(
                    'https://image.pngaaa.com/835/2233835-middle.png',
                    height: 20,
                    width: 20,
                    errorBuilder: (context, e, s) => const Icon(Icons.g_mobiledata, size: 28),
                  ),
                  label: Text(
                    "Sign in with Google",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.darkCardColor : Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                        color: Colors.grey.withOpacity(isDark ? 0.2 : 0.3),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 36),
                
                // Sign Up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
