import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:study_voice_ai/models/pdf_model.dart';
import 'package:study_voice_ai/models/bookmark_model.dart';
import 'package:study_voice_ai/models/note_model.dart';
import 'package:study_voice_ai/services/tts_service.dart';
import 'package:study_voice_ai/services/database_service.dart';

class PlayerViewModel extends ChangeNotifier {
  final TtsService _ttsService;
  final DatabaseService _dbService;

  PdfModel? _currentPdf;
  int _currentPageIndex = 0;
  
  TtsState _playerState = TtsState.stopped;
  
  // Highlight offsets
  int _highlightStart = 0;
  int _highlightEnd = 0;
  String _activeWord = '';

  // Configs
  double _playbackSpeed = 1.0;
  double _pitch = 1.0;
  String _language = 'en-US';
  Map<String, String>? _selectedVoice;
  List<Map<String, String>> _availableVoices = [];

  // Bookmarks and Notes lists
  List<BookmarkModel> _bookmarks = [];
  List<NoteModel> _notes = [];

  PlayerViewModel({
    required TtsService ttsService,
    required DatabaseService dbService,
  })  : _ttsService = ttsService,
        _dbService = dbService {
    // Listen to native speech states
    _ttsService.stateStream.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    // Listen to word highlights
    _ttsService.progressStream.listen((progress) {
      _highlightStart = progress['start'] ?? 0;
      _highlightEnd = progress['end'] ?? 0;
      _activeWord = progress['word'] ?? '';
      notifyListeners();
    });

    _loadVoices();
  }

  PdfModel? get currentPdf => _currentPdf;
  int get currentPageIndex => _currentPageIndex;
  TtsState get playerState => _playerState;
  bool get isPlaying => _playerState == TtsState.playing;
  
  int get highlightStart => _highlightStart;
  int get highlightEnd => _highlightEnd;
  String get activeWord => _activeWord;

  double get playbackSpeed => _playbackSpeed;
  double get pitch => _pitch;
  String get language => _language;
  Map<String, String>? get selectedVoice => _selectedVoice;
  List<Map<String, String>> get availableVoices => _availableVoices;

  List<BookmarkModel> get bookmarks => _bookmarks;
  List<NoteModel> get notes => _notes;

  String get currentPageText {
    if (_currentPdf == null || _currentPdf!.extractedPagesText.isEmpty) {
      return "No text content available.";
    }
    if (_currentPageIndex >= _currentPdf!.extractedPagesText.length) {
      return "End of document reached.";
    }
    return _currentPdf!.extractedPagesText[_currentPageIndex];
  }

  Future<void> _loadVoices() async {
    _availableVoices = await _ttsService.getAvailableVoices();
    notifyListeners();
  }

  /// Initial entry point for loading a study file into the active player dashboard
  Future<void> loadPdf(PdfModel pdf, {int startPage = 0}) async {
    await stop();
    _currentPdf = pdf;
    _currentPageIndex = startPage < pdf.pageCount ? startPage : 0;
    _playbackSpeed = pdf.playbackSpeed;
    
    // Set config values
    await _ttsService.setSpeed(_playbackSpeed);
    
    // Load accompanying bookmarks and notes
    await loadBookmarksAndNotes();
    
    notifyListeners();
  }

  Future<void> loadBookmarksAndNotes() async {
    if (_currentPdf == null) return;
    _bookmarks = await _dbService.getBookmarks(_currentPdf!.id);
    _notes = await _dbService.getNotes(_currentPdf!.id);
    notifyListeners();
  }

  Future<void> play() async {
    if (_currentPdf == null) return;
    final text = currentPageText;
    if (text.isEmpty) return;
    
    await _ttsService.speak(text);
  }

  Future<void> pause() async {
    await _ttsService.pause();
  }

  Future<void> stop() async {
    await _ttsService.stop();
    _highlightStart = 0;
    _highlightEnd = 0;
    _activeWord = '';
    notifyListeners();
  }

  Future<void> nextPage() async {
    if (_currentPdf == null || _currentPageIndex >= _currentPdf!.pageCount - 1) return;
    await stop();
    _currentPageIndex++;
    notifyListeners();
    await play();
  }

  Future<void> previousPage() async {
    if (_currentPageIndex <= 0) return;
    await stop();
    _currentPageIndex--;
    notifyListeners();
    await play();
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    await _ttsService.setSpeed(speed);
    
    if (_currentPdf != null) {
      // Sync speed setting to DB metadata
      final updated = _currentPdf!.copyWith(playbackSpeed: speed);
      await _dbService.savePdf(updated);
    }
    
    notifyListeners();
    if (isPlaying) {
      await play(); // restarts engine with fresh rates
    }
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _ttsService.setPitch(pitch);
    notifyListeners();
    if (isPlaying) {
      await play();
    }
  }

  Future<void> changeLanguage(String langCode) async {
    _language = langCode;
    await _ttsService.setLanguage(langCode);
    
    // Pick first matching voice from cached locales
    final matchingVoices = _availableVoices.where((v) => v['locale']?.startsWith(langCode) ?? false).toList();
    if (matchingVoices.isNotEmpty) {
      _selectedVoice = matchingVoices.first;
      await _ttsService.setVoice(_selectedVoice!);
    } else {
      _selectedVoice = null;
    }
    
    notifyListeners();
    if (isPlaying) {
      await play();
    }
  }

  Future<void> changeVoice(Map<String, String> voice) async {
    _selectedVoice = voice;
    await _ttsService.setVoice(voice);
    notifyListeners();
    if (isPlaying) {
      await play();
    }
  }

  // --- Bookmark interactions ---
  Future<void> addBookmark(String note) async {
    if (_currentPdf == null) return;
    
    final b = BookmarkModel(
      id: const Uuid().v4(),
      pdfId: _currentPdf!.id,
      pageIndex: _currentPageIndex,
      textPosition: _highlightStart,
      noteText: note,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    
    await _dbService.saveBookmark(b);
    _bookmarks.insert(0, b);
    notifyListeners();
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    if (_currentPdf == null) return;
    await _dbService.deleteBookmark(_currentPdf!.id, bookmarkId);
    _bookmarks.removeWhere((b) => b.id == bookmarkId);
    notifyListeners();
  }

  // --- Notes interactions ---
  Future<void> addNote(String content, {String colorHex = '#FF6366F1'}) async {
    if (_currentPdf == null) return;
    
    final n = NoteModel(
      id: const Uuid().v4(),
      pdfId: _currentPdf!.id,
      pageIndex: _currentPageIndex,
      content: content,
      colorHex: colorHex,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _dbService.saveNote(n);
    _notes.insert(0, n);
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    if (_currentPdf == null) return;
    await _dbService.deleteNote(_currentPdf!.id, noteId);
    _notes.removeWhere((n) => n.id == noteId);
    notifyListeners();
  }

  // Jumps backward by roughly 150 characters
  Future<void> skipBackward() async {
    // In local TTS, we can stop speech and start from an offset or just speak from the page again
    // For a robust implementation: restart speech of active page
    await stop();
    await play();
  }

  // Jumps forward
  Future<void> skipForward() async {
    await stop();
    await play();
  }
}
