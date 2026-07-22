import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_voice_ai/core/theme/app_theme.dart';
import 'package:study_voice_ai/core/widgets/glass_card.dart';
import 'package:study_voice_ai/viewmodels/auth_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/library_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/player_viewmodel.dart';
import 'package:study_voice_ai/models/pdf_model.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({Key? key}) : super(key: key);

  void _openPdfPlayer(BuildContext context, PdfModel pdf) async {
    final playerVM = Provider.of<PlayerViewModel>(context, listen: false);
    await playerVM.loadPdf(pdf, startPage: pdf.lastReadPage);
    if (!context.mounted) return;
    Navigator.pushNamed(context, '/player');
  }

  void _showSortOptions(BuildContext context, LibraryViewModel libraryVM) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Sort Library By",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildSortOption(context, "Upload Date (Newest First)", "recent", libraryVM),
              const SizedBox(height: 12),
              _buildSortOption(context, "Alphabetical (Title A-Z)", "title", libraryVM),
              const SizedBox(height: 12),
              _buildSortOption(context, "File Size (Largest First)", "size", libraryVM),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
      BuildContext context, String title, String code, LibraryViewModel libraryVM) {
    final isSelected = libraryVM.sortBy == code;
    return InkWell(
      onTap: () {
        libraryVM.setSortBy(code);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.08) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : null,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, LibraryViewModel libraryVM, PdfModel pdf) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Study File?"),
          content: Text("Are you sure you want to delete '${pdf.fileName}'? All summaries, quizzes, bookmarks, and notes will be permanently erased."),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      await libraryVM.deletePdf(authVM.user!.uid, pdf.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Study file deleted successfully."),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryVM = Provider.of<LibraryViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Study Library 📚",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort_rounded, size: 28),
                      onPressed: () => _showSortOptions(context, libraryVM),
                    ),
                  ],
                ),
              ),

              // Search Bar inside tab
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
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
                      hintText: "Search files by name or topic...",
                      hintStyle: TextStyle(
                        color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary).withOpacity(0.6),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Categories selection reel
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
              const SizedBox(height: 20),

              // Content List
              Expanded(
                child: libraryVM.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : libraryVM.filteredPdfs.isEmpty
                        ? _buildEmptyState(context, libraryVM.searchQuery, libraryVM.selectedCategory)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                            itemCount: libraryVM.filteredPdfs.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final pdf = libraryVM.filteredPdfs[idx];
                              return _buildLibraryCard(context, libraryVM, pdf, isDark);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String query, String cat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.manage_search_rounded,
              size: 72,
              color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary).withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty || cat != 'All' ? "No matches found" : "Your library is empty",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              query.isNotEmpty || cat != 'All'
                  ? "Try resetting filters or checking your spelling."
                  : "Tap the quick-upload '+' button to add your textbooks and start study voice streaming!",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryCard(
      BuildContext context, LibraryViewModel libraryVM, PdfModel pdf, bool isDark) {
    final date = DateTime.fromMillisecondsSinceEpoch(pdf.uploadTimestamp);
    final dateFormatted = "${date.day}/${date.month}/${date.year}";

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPdfPlayer(context, pdf),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppTheme.accentGradient,
                  ),
                  child: const Icon(
                    Icons.audiotrack_rounded,
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
                      const SizedBox(height: 6),
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
                          Expanded(
                            child: Text(
                              "${pdf.pageCount} pgs • ${pdf.fileSize}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Added on $dateFormatted",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                      ),
                    ],
                  ),
                ),

                // Actions row
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        pdf.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: pdf.isFavorite ? Colors.pinkAccent : Colors.grey,
                      ),
                      onPressed: () {
                        final authVM = Provider.of<AuthViewModel>(context, listen: false);
                        libraryVM.toggleFavorite(authVM.user!.uid, pdf);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                      onPressed: () => _handleDelete(context, libraryVM, pdf),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
