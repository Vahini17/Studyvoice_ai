import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_voice_ai/core/theme/app_theme.dart';
import 'package:study_voice_ai/core/widgets/glass_card.dart';
import 'package:study_voice_ai/viewmodels/auth_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/library_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/player_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/stats_viewmodel.dart';
import 'package:study_voice_ai/models/pdf_model.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  void _resumePdfPlayback(BuildContext context, PdfModel pdf) async {
    final playerVM = Provider.of<PlayerViewModel>(context, listen: false);
    await playerVM.loadPdf(pdf, startPage: pdf.lastReadPage);
    if (!context.mounted) return;
    Navigator.pushNamed(context, '/player');
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final statsVM = Provider.of<StatsViewModel>(context);
    final libraryVM = Provider.of<LibraryViewModel>(context);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = authVM.user?.displayName ?? "Student";

    // Grab recently read or uploaded PDF
    final PdfModel? recentPdf = libraryVM.pdfs.isNotEmpty ? libraryVM.pdfs.first : null;

    final categories = ['All', 'Science', 'History', 'Technology', 'Literature', 'Business'];

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
                // Welcome row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, $userName! 👋",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Ready to listen and learn today?",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: authVM.user?.photoUrl.isNotEmpty == true
                            ? NetworkImage(authVM.user!.photoUrl)
                            : null,
                        child: authVM.user?.photoUrl.isEmpty == true || authVM.user == null
                            ? const Icon(Icons.person, size: 24)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Streak Banner (glowing glass card)
                GestureDetector(
                  onTap: () {
                    // navigate to profile to inspect tracker
                  },
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${statsVM.streakDays}-Day Study Streak!",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                statsVM.streakDays > 0 
                                    ? "Awesome job! Keep listening daily to lock your streak." 
                                    : "Upload your first study PDF to launch a streak!",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCardColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    onChanged: (val) {
                      libraryVM.setSearchQuery(val);
                    },
                    decoration: InputDecoration(
                      hintText: "Search your study PDFs...",
                      hintStyle: TextStyle(
                        color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary).withOpacity(0.6),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Stats Dashboard Section
                Row(
                  children: [
                    Expanded(
                      child: _buildStatMiniCard(
                        context,
                        "${statsVM.totalListeningMinutes}m",
                        "Study Time",
                        Icons.hourglass_empty_rounded,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatMiniCard(
                        context,
                        "${statsVM.totalPdfsUploaded}",
                        "PDF Files",
                        Icons.picture_as_pdf_rounded,
                        AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Continue Listening section (if any)
                if (recentPdf != null) ...[
                  Text(
                    "Continue Listening 🎧",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: AppTheme.accentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _resumePdfPlayback(context, recentPdf),
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      recentPdf.subject.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.volume_up_rounded, color: Colors.white),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                recentPdf.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Page ${recentPdf.lastReadPage + 1} of ${recentPdf.pageCount} • Size: ${recentPdf.fileSize}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: recentPdf.pageCount > 0 
                                            ? (recentPdf.lastReadPage + 1) / recentPdf.pageCount 
                                            : 0,
                                        backgroundColor: Colors.white.withOpacity(0.25),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Subject tags header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Explore Subjects 📚",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                
                // Categories Horizontal Scroll List
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, idx) {
                      final catName = categories[idx];
                      final isSelected = libraryVM.selectedCategory == catName;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: GestureDetector(
                          onTap: () {
                            libraryVM.setSelectedCategory(catName);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppTheme.primaryGradient : null,
                              color: isSelected 
                                  ? null 
                                  : (isDark ? AppTheme.darkCardColor : Colors.white),
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.transparent 
                                    : (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                catName,
                                style: TextStyle(
                                  color: isSelected 
                                      ? Colors.white 
                                      : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Recently Uploaded PDFs List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recently Uploaded 📑",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (libraryVM.pdfs.length > 3)
                      TextButton(
                        onPressed: () {
                          // Jump to Library Tab by notifying parent or similar index change
                        },
                        child: const Text("View All"),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                if (libraryVM.pdfs.isEmpty) ...[
                  // Empty state
                  GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 48,
                          color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary).withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No study files yet",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap the '+' button below to upload your first study PDF material!",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // List of PDFs
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: libraryVM.pdfs.length > 3 ? 3 : libraryVM.pdfs.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final pdf = libraryVM.pdfs[idx];
                      return _buildPdfTile(context, pdf, isDark);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatMiniCard(
      BuildContext context, String value, String label, IconData icon, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfTile(BuildContext context, PdfModel pdf, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _resumePdfPlayback(context, pdf),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // PDF gradient thumbnail icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Icon(
                    Icons.library_music_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pdf.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pdf.subject,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${pdf.pageCount} pages • ${pdf.fileSize}",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
