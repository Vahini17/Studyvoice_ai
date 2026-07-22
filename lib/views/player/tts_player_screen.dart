import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_voice_ai/core/theme/app_theme.dart';
import 'package:study_voice_ai/core/widgets/custom_button.dart';
import 'package:study_voice_ai/core/widgets/glass_card.dart';
import 'package:study_voice_ai/viewmodels/library_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/player_viewmodel.dart';
import 'package:study_voice_ai/viewmodels/stats_viewmodel.dart';
import 'package:study_voice_ai/services/tts_service.dart';

class TtsPlayerScreen extends StatefulWidget {
  const TtsPlayerScreen({Key? key}) : super(key: key);

  @override
  State<TtsPlayerScreen> createState() => _TtsPlayerScreenState();
}

class _TtsPlayerScreenState extends State<TtsPlayerScreen> {
  final _noteController = TextEditingController();
  final _bookmarkController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    _bookmarkController.dispose();
    super.dispose();
  }

  void _showVoiceSettings(BuildContext context, PlayerViewModel playerVM) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Voice Customization 🎙️",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    
                    // Language Selection
                    const Text("SELECT STUDY LANGUAGE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildLanguageChip(context, "English", "en-US", playerVM, setModalState),
                        const SizedBox(width: 8),
                        _buildLanguageChip(context, "Hindi", "hi-IN", playerVM, setModalState),
                        const SizedBox(width: 8),
                        _buildLanguageChip(context, "Tamil", "ta-IN", playerVM, setModalState),
                        const SizedBox(width: 8),
                        _buildLanguageChip(context, "Telugu", "te-IN", playerVM, setModalState),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pitch slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("SPEECH PITCH", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        Text("${playerVM.pitch.toStringAsFixed(1)}x", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: playerVM.pitch,
                      min: 0.5,
                      max: 1.5,
                      divisions: 10,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) async {
                        await playerVM.setPitch(val);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    // System Voices drawer
                    const Text("SELECT VOICE TYPE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCardColor : Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: playerVM.availableVoices.isEmpty
                          ? const Center(child: Text("Defaulting to native text-to-speech voice"))
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: playerVM.availableVoices
                                  .where((v) => v['locale']?.startsWith(playerVM.language) ?? false)
                                  .length,
                              itemBuilder: (context, idx) {
                                final matchingVoices = playerVM.availableVoices
                                    .where((v) => v['locale']?.startsWith(playerVM.language) ?? false)
                                    .toList();
                                final voice = matchingVoices[idx];
                                final isSelected = playerVM.selectedVoice?['name'] == voice['name'];
                                final voiceName = voice['name'] ?? "Voice $idx";

                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    voiceName.split('/').last.replaceAll('-', ' '),
                                    style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                  ),
                                  leading: Icon(
                                    Icons.record_voice_over_rounded,
                                    color: isSelected ? AppTheme.primaryColor : Colors.grey,
                                  ),
                                  trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                                  onTap: () async {
                                    await playerVM.changeVoice(voice);
                                    setModalState(() {});
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAiSummary(BuildContext context, String summary) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      "AI Smart Summary 🤖",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  summary,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Got it, Close"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageChip(
      BuildContext context, String name, String code, PlayerViewModel playerVM, StateSetter setModalState) {
    final isSelected = playerVM.language == code;
    return GestureDetector(
      onTap: () async {
        await playerVM.changeLanguage(code);
        setModalState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _addBookmarkDialog(BuildContext context, PlayerViewModel playerVM) async {
    _bookmarkController.clear();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Audio Bookmark 🏷️"),
        content: TextField(
          controller: _bookmarkController,
          decoration: const InputDecoration(
            hintText: "Enter a quick note for this bookmark (optional)...",
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Bookmark"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await playerVM.addBookmark(_bookmarkController.text.trim());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Audio position bookmarked successfully!"), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _addNoteDialog(BuildContext context, PlayerViewModel playerVM) async {
    _noteController.clear();
    String selectedColor = '#FF6366F1'; // Default Indigo
    final colorsList = [
      {'name': 'Indigo', 'value': '#FF6366F1'},
      {'name': 'Pink', 'value': '#FFEC4899'},
      {'name': 'Cyan', 'value': '#FF06B6D4'},
      {'name': 'Amber', 'value': '#FFF59E0B'},
    ];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Study Note ✍️"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Write down key formulas, definitions, or custom explanations...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("HIGHLIGHT COLOR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: colorsList.map((c) {
                      final isSel = selectedColor == c['value'];
                      final cVal = Color(int.parse(c['value']!.replaceFirst('#', '0xff')));
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColor = c['value']!;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: cVal,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSel
                                ? [BoxShadow(color: cVal.withOpacity(0.6), blurRadius: 8)]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm == true && _noteController.text.trim().isNotEmpty) {
      await playerVM.addNote(_noteController.text.trim(), colorHex: selectedColor);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Study note recorded!"), backgroundColor: Colors.green),
      );
    }
  }

  void _triggerQuiz(BuildContext context, PlayerViewModel playerVM) async {
    if (playerVM.currentPdf == null) return;
    
    // Stop playback while taking quiz
    await playerVM.stop();
    
    if (!context.mounted) return;
    Navigator.pushNamed(context, '/quiz');
  }

  @override
  Widget build(BuildContext context) {
    final playerVM = Provider.of<PlayerViewModel>(context);
    final statsVM = Provider.of<StatsViewModel>(context);
    final libraryVM = Provider.of<LibraryViewModel>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (playerVM.currentPdf == null) {
      return const Scaffold(body: Center(child: Text("No PDF loaded. Please pick one from your library.")));
    }

    final pdf = playerVM.currentPdf!;
    final pagesText = pdf.extractedPagesText;
    final activeText = playerVM.currentPageText;

    // Track real time study ticking
    if (playerVM.isPlaying) {
      statsVM.startListeningTracker();
    } else {
      statsVM.stopListeningTracker();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
          onPressed: () async {
            await playerVM.stop();
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Playing: ${pdf.subject}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded, size: 28),
            onPressed: () => _showVoiceSettings(context, playerVM),
          ),
          const SizedBox(width: 8),
        ],
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Text Board container (scrollable with glowing highlights)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "PAGE ${playerVM.currentPageIndex + 1} OF ${pdf.pageCount}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5, color: AppTheme.primaryColor),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pdf.fileSize,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Text reader body
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildHighlightedText(activeText, playerVM.highlightStart, playerVM.highlightEnd, isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Linear slider position gauge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Page ${playerVM.currentPageIndex + 1}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: playerVM.currentPageIndex.toDouble(),
                        min: 0,
                        max: (pdf.pageCount - 1).toDouble() > 0 ? (pdf.pageCount - 1).toDouble() : 1.0,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) async {
                          await playerVM.loadPdf(pdf, startPage: val.toInt());
                        },
                      ),
                    ),
                    Text(
                      "Total ${pdf.pageCount}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // 3. Circular player gauge / control decks
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, size: 36),
                          onPressed: playerVM.currentPageIndex > 0 ? playerVM.previousPage : null,
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => playerVM.isPlaying ? playerVM.pause() : playerVM.play(),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor,
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              playerVM.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 36),
                          onPressed: playerVM.currentPageIndex < pdf.pageCount - 1 ? playerVM.nextPage : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick speeds row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [0.5, 1.0, 1.5, 2.0].map((speed) {
                        final isSel = playerVM.playbackSpeed == speed;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: GestureDetector(
                            onTap: () => playerVM.setSpeed(speed),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? AppTheme.primaryColor : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${speed}x",
                                style: TextStyle(
                                  color: isSel ? Colors.white : null,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // 4. Bottom utility tab bar
              Container(
                height: 72,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCardColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildUtilityButton(context, Icons.auto_awesome_rounded, "AI Summary", () {
                      _showAiSummary(context, pdf.summary);
                    }),
                    _buildUtilityButton(context, Icons.bookmark_add_rounded, "Bookmark", () {
                      _addBookmarkDialog(context, playerVM);
                    }),
                    _buildUtilityButton(context, Icons.edit_note_rounded, "Add Note", () {
                      _addNoteDialog(context, playerVM);
                    }),
                    _buildUtilityButton(context, Icons.quiz_rounded, "AI Quiz", () {
                      _triggerQuiz(context, playerVM);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Builds a RichText representation of the reading panel highlighting spoken sentences
  Widget _buildHighlightedText(String text, int start, int end, bool isDark) {
    if (text.isEmpty) {
      return const Text("No content on this page.");
    }
    
    // Check bounds safety
    if (start < 0 || end > text.length || start > end) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
      );
    }

    final before = text.substring(0, start);
    final highlight = text.substring(start, end);
    final after = text.substring(end);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          fontWeight: FontWeight.w500,
          fontFamily: 'Outfit',
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: highlight,
            style: TextStyle(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.35),
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
