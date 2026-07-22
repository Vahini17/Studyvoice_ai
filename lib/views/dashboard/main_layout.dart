import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_voice_ai/core/theme/app_theme.dart';
import 'package:study_voice_ai/viewmodels/auth_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/library_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/stats_viewmodel.dart';
import 'package:study_voice_ai/views/dashboard/home_tab.dart';
import 'package:study_voice_ai/views/dashboard/library_tab.dart';
import 'package:study_voice_ai/views/dashboard/bookmarks_tab.dart';
import 'package:study_voice_ai/views/dashboard/profile_tab.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const HomeTab(),
      const LibraryTab(),
      const BookmarksTab(),
      const ProfileTab(),
    ];
    
    // Proactively fetch documents for current user session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      if (authVM.user != null) {
        Provider.of<LibraryViewModel>(context, listen: false).fetchPdfs(authVM.user!.uid);
      }
    });
  }

  Future<void> _handleQuickUpload() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final libraryVM = Provider.of<LibraryViewModel>(context, listen: false);
    final statsVM = Provider.of<StatsViewModel>(context, listen: false);

    if (authVM.user == null) return;

    final newPdf = await libraryVM.pickAndUploadPdf(authVM.user!.uid);
    if (newPdf != null) {
      await statsVM.incrementPdfCount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully uploaded ${newPdf.fileName}! Parsing complete."),
          backgroundColor: Colors.green,
        ),
      );
    } else if (libraryVM.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(libraryVM.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // allows background to flow behind glass navigation bar
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardColor.withOpacity(0.85) : Colors.white.withOpacity(0.9),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded, size: 24),
                  activeIcon: Icon(Icons.dashboard_rounded, size: 28),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.my_library_books_rounded, size: 24),
                  activeIcon: Icon(Icons.my_library_books_rounded, size: 28),
                  label: "Library",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_added_rounded, size: 24),
                  activeIcon: Icon(Icons.bookmark_added_rounded, size: 28),
                  label: "Bookmarks",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_pin_rounded, size: 24),
                  activeIcon: Icon(Icons.person_pin_rounded, size: 28),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleQuickUpload,
        shape: const CircleBorder(),
        elevation: 8,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
          ),
          child: Consumer<LibraryViewModel>(
            builder: (context, libVM, _) {
              return libVM.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : const Icon(Icons.add_rounded, size: 36, color: Colors.white);
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
