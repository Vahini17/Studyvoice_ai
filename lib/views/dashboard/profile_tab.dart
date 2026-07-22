import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_voice_ai/core/theme/app_theme.dart';
import 'package:study_voice_ai/core/widgets/glass_card.dart';
import 'package:study_voice_ai/viewmodels/auth_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/stats_viewmodel.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final statsVM = Provider.of<StatsViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = authVM.user?.displayName ?? "Student Scholar";
    final email = authVM.user?.email ?? "student@studyvoiceai.com";

    // Double precision listening hours calculation
    final listeningHours = (statsVM.totalListeningMinutes / 60).toStringAsFixed(1);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.backgroundGradientDark : null,
          color: isDark ? null : AppTheme.lightBgColor,
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with settings button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Study Tracker 📊",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded, size: 28),
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profile card details
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryColor, width: 2.5),
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundImage: authVM.user?.photoUrl.isNotEmpty == true
                              ? NetworkImage(authVM.user!.photoUrl)
                              : null,
                          child: authVM.user?.photoUrl.isEmpty == true || authVM.user == null
                              ? const Icon(Icons.person, size: 36)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "PREMIUM LEARNER",
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stat counters block
                Row(
                  children: [
                    Expanded(
                      child: _buildCounterTile(context, listeningHours, "Hours Read", Icons.headset_rounded, AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCounterTile(context, "${statsVM.streakDays} days", "Active Streak", Icons.local_fire_department_rounded, AppTheme.secondaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCounterTile(context, "${statsVM.totalPdfsUploaded}", "PDFs Synced", Icons.cloud_done_rounded, AppTheme.accentColor),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Weekly analytics vertical bar chart
                Text(
                  "Weekly Study Analytics (Minutes)",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                
                GlassCard(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    children: [
                      _buildWeeklyCustomChart(context, statsVM.weeklyAnalytics),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 8),
                          const Text("Study Listening Duration (mins)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Achievements List
                Text(
                  "Milestone Badges 🏆",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                _buildAchievementTile(
                  context,
                  "Speech Scholar",
                  "Listen to more than 2 hours of converted textbooks.",
                  double.parse(listeningHours) >= 2.0,
                  Icons.school_rounded,
                ),
                const SizedBox(height: 12),
                _buildAchievementTile(
                  context,
                  "Active Recaller",
                  "Score perfect marks on any Dynamic AI Quiz.",
                  statsVM.totalPdfsUploaded > 0, // Mock activator
                  Icons.insights_rounded,
                ),
                const SizedBox(height: 12),
                _buildAchievementTile(
                  context,
                  "Streaker Club",
                  "Maintain a study streak of 3 days or more.",
                  statsVM.streakDays >= 3,
                  Icons.workspace_premium_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterTile(
      BuildContext context, String count, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            count,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Builds a fully custom, responsive, beautiful rounded vertical bar chart using standard widgets
  Widget _buildWeeklyCustomChart(BuildContext context, Map<String, double> data) {
    final maxMins = data.values.fold<double>(10.0, (prev, element) => element > prev ? element : prev);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.entries.map((entry) {
        final day = entry.key;
        final minutes = entry.value;
        
        // Calculate height proportion (bounded max height 140)
        final double barHeight = maxMins > 0 ? (minutes / maxMins) * 120 : 0.0;
        final isToday = _isToday(day);

        return Column(
          children: [
            // Minutes tag on top
            Text(
              "${minutes.toInt()}m",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isToday ? AppTheme.primaryColor : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            
            // The Bar
            Container(
              width: 18,
              height: barHeight < 5 ? 5 : barHeight, // ensure minimum height for styling
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: isToday 
                    ? AppTheme.primaryGradient 
                    : LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.4),
                          AppTheme.accentColor.withOpacity(0.4),
                        ],
                      ),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            
            // Day label
            Text(
              day,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                color: isToday ? AppTheme.primaryColor : null,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  bool _isToday(String dayCode) {
    final date = DateTime.now();
    String code = 'Mon';
    switch (date.weekday) {
      case DateTime.monday: code = 'Mon'; break;
      case DateTime.tuesday: code = 'Tue'; break;
      case DateTime.wednesday: code = 'Wed'; break;
      case DateTime.thursday: code = 'Thu'; break;
      case DateTime.friday: code = 'Fri'; break;
      case DateTime.saturday: code = 'Sat'; break;
      case DateTime.sunday: code = 'Sun'; break;
    }
    return dayCode == code;
  }

  Widget _buildAchievementTile(
      BuildContext context, String title, String subtitle, bool isUnlocked, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked 
              ? AppTheme.primaryColor.withOpacity(0.3) 
              : (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          width: isUnlocked ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Icon ring
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked ? AppTheme.primaryColor.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isUnlocked ? AppTheme.primaryColor : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Text details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Checkbox badge
          Icon(
            isUnlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
            color: isUnlocked ? AppTheme.primaryColor : Colors.grey,
            size: 24,
          ),
        ],
      ),
    );
  }
}
