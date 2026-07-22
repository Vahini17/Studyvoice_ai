import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_voice_ai/core/theme/app_theme.dart';
import 'package:study_voice_ai/core/widgets/glass_card.dart';
import 'package:study_voice_ai/viewmodels/auth_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/library_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/player_viewmodel.dart';
import 'package:study_voice_ai/models/bookmark_model.dart';
import 'package:study_voice_ai/models/note_model.dart';
import 'package:study_voice_ai/models/pdf_model.dart';

class BookmarksTab extends StatefulWidget {
  const BookmarksTab({Key? key}) : super(key: key);

  @override
  State<BookmarksTab> createState() => _BookmarksTabState();
}

class _BookmarksTabState extends State<BookmarksTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _resumeFromBookmark(BuildContext context, String pdfId, int pageIndex) async {
    final libraryVM = Provider.of<LibraryViewModel>(context, listen: false);
    final playerVM = Provider.of<PlayerViewModel>(context, listen: false);

    // Find PDF object
    final pdfIdx = libraryVM.pdfs.indexWhere((p) => p.id == pdfId);
    if (pdfIdx >= 0) {
      final pdf = libraryVM.pdfs[pdfIdx];
      await playerVM.loadPdf(pdf, startPage: pageIndex);
      if (!context.mounted) return;
      Navigator.pushNamed(context, '/player');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Study file not found. It may have been deleted."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _exportNote(BuildContext context, NoteModel note, String pdfTitle) async {
    // Show a premium dialog showcasing note details ready for copying/exporting
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.share_rounded, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text("Export Study Note"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Source: $pdfTitle (Page ${note.pageIndex + 1})",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    note.content,
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Tip: You can highlight and copy the text block above to share with classmates or add to Notion!",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNote(BuildContext context, PlayerViewModel playerVM, NoteModel note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Note?"),
        content: const Text("Are you sure you want to delete this study note? This cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await playerVM.deleteNote(note.id);
    }
  }

  Future<void> _deleteBookmark(BuildContext context, PlayerViewModel playerVM, BookmarkModel bookmark) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Bookmark?"),
        content: const Text("Are you sure you want to remove this bookmark marker?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await playerVM.deleteBookmark(bookmark.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryVM = Provider.of<LibraryViewModel>(context);
    final playerVM = Provider.of<PlayerViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Collect all bookmarks and notes dynamically across PDFs to show central archives
    final allBookmarks = libraryVM.pdfs.expand((pdf) => playerVM.bookmarks.where((b) => b.pdfId == pdf.id)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final allNotes = libraryVM.pdfs.expand((pdf) => playerVM.notes.where((n) => n.pdfId == pdf.id)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

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
              // Header title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                child: Text(
                  "Bookmarks & Notes 🏷️",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              // Custom Segment Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCardColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppTheme.primaryGradient,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(text: "Bookmarks"),
                    Tab(text: "Notes"),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tab contents
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Bookmarks sub-tab
                    _buildBookmarksList(context, libraryVM, playerVM, allBookmarks),
                    // Notes sub-tab
                    _buildNotesList(context, libraryVM, playerVM, allNotes),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksList(
      BuildContext context, LibraryViewModel libraryVM, PlayerViewModel playerVM, List<BookmarkModel> list) {
    if (list.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.bookmark_border_rounded,
        "No Bookmarks Saved",
        "While playing study audio textbooks, tap the bookmark button to record key listening timestamps and resume easily!",
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      itemCount: list.length,
      separatorBuilder: (context, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final b = list[idx];
        final pdf = libraryVM.pdfs.firstWhere((p) => p.id == b.pdfId);
        
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.06),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_added_rounded, color: AppTheme.primaryColor, size: 22),
            ),
            title: Text(
              pdf.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "Bookmarked Page: ${b.pageIndex + 1}\nDetail: ${b.noteText.isNotEmpty ? b.noteText : 'General save-point'}",
                style: const TextStyle(fontSize: 12, height: 1.3),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
              onPressed: () => _deleteBookmark(context, playerVM, b),
            ),
            onTap: () => _resumeFromBookmark(context, b.pdfId, b.pageIndex),
          ),
        );
      },
    );
  }

  Widget _buildNotesList(
      BuildContext context, LibraryViewModel libraryVM, PlayerViewModel playerVM, List<NoteModel> list) {
    if (list.isEmpty) {
      return _buildEmptyState(
        context,
        Icons.note_alt_outlined,
        "No Custom Notes",
        "Add personal remarks during key paragraphs inside the audio player panel. You can easily view, search, and export them here!",
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      itemCount: list.length,
      separatorBuilder: (context, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final n = list[idx];
        final pdf = libraryVM.pdfs.firstWhere((p) => p.id == n.pdfId);
        
        // Parse hex color safely
        Color noteColor = AppTheme.primaryColor;
        try {
          noteColor = Color(int.parse(n.colorHex.replaceFirst('#', '0xff')));
        } catch (e) {
          noteColor = AppTheme.primaryColor;
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: noteColor.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: noteColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Page ${n.pageIndex + 1}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: noteColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share_rounded, size: 20, color: Colors.grey),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _exportNote(context, n, pdf.fileName),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _deleteNote(context, playerVM, n),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  n.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey.withOpacity(0.1)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _resumeFromBookmark(context, n.pdfId, n.pageIndex),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pdf.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String title, String description) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary).withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
