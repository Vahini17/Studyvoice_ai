import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:study_voice_ai/models/pdf_model.dart';
import 'package:study_voice_ai/services/database_service.dart';
import 'package:study_voice_ai/services/storage_service.dart';
import 'package:study_voice_ai/services/ai_service.dart';
import 'package:study_voice_ai/core/utils/pdf_helper.dart';

class LibraryViewModel extends ChangeNotifier {
  final DatabaseService _dbService;
  final StorageService _storageService;
  final AiService _aiService;

  List<PdfModel> _pdfs = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'recent'; // 'recent', 'title', 'size'

  LibraryViewModel({
    required DatabaseService dbService,
    required StorageService storageService,
    required AiService aiService,
  })  : _dbService = dbService,
        _storageService = storageService,
        _aiService = aiService;

  List<PdfModel> get pdfs => _pdfs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  /// Retrieves filtered and sorted list of PDFs
  List<PdfModel> get filteredPdfs {
    List<PdfModel> list = List.from(_pdfs);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((p) => p.fileName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                       p.topic.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply category subject filter
    if (_selectedCategory != 'All') {
      list = list.where((p) => p.subject == _selectedCategory).toList();
    }

    // Apply sorting
    if (_sortBy == 'recent') {
      list.sort((a, b) => b.uploadTimestamp.compareTo(a.uploadTimestamp));
    } else if (_sortBy == 'title') {
      list.sort((a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
    } else if (_sortBy == 'size') {
      list.sort((a, b) => _parseSize(b.fileSize).compareTo(_parseSize(a.fileSize)));
    }

    return list;
  }

  double _parseSize(String sizeStr) {
    try {
      final parts = sizeStr.split(' ');
      final val = double.parse(parts[0]);
      if (parts[1] == 'MB') return val * 1024;
      if (parts[1] == 'GB') return val * 1024 * 1024;
      return val; // KB or bytes
    } catch (e) {
      return 0.0;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  Future<void> fetchPdfs(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pdfs = await _dbService.getPdfs(userId);
    } catch (e) {
      _errorMessage = "Failed to load study files: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Launches native file picker, extracts text page-by-page, generates AI markers, and saves
  Future<PdfModel?> pickAndUploadPdf(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Pick PDF file
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final String filePath = result.files.single.path!;
      final File file = File(filePath);
      final String fileName = result.files.single.name;
      final int rawBytesSize = result.files.single.size;
      final String fileSize = PdfHelper.formatBytes(rawBytesSize, 1);

      // Step 2: Extract text (crash-safe — never throws now)
      final List<String> extractedTextPages =
          await PdfHelper.extractTextPageByPage(filePath);
      final int pageCount = extractedTextPages.length;

      // Step 3: AI analysis (safe fallback if AI unavailable)
      final String sampleTextForAi = extractedTextPages.take(3).join(' ');
      final String topicName =
          fileName.replaceAll('.pdf', '').replaceAll('_', ' ');

      String detectedSubject = 'General';
      List<String> keywords = [];
      String summary = 'Summary not available.';

      try {
        detectedSubject = await _aiService.detectSubject(sampleTextForAi);
      } catch (e) {
        debugPrint('AI subject detection failed (non-fatal): $e');
      }
      try {
        keywords = await _aiService.extractKeywords(sampleTextForAi);
      } catch (e) {
        debugPrint('AI keyword extraction failed (non-fatal): $e');
      }
      try {
        summary = await _aiService.generateSummary(extractedTextPages.join('\n'));
      } catch (e) {
        debugPrint('AI summary failed (non-fatal): $e');
      }

      // Step 4: Upload file — fall back to local path if Firebase Storage fails
      String storageUrl = filePath;
      try {
        storageUrl = await _storageService.uploadPdf(userId, file, fileName);
      } catch (e) {
        debugPrint('Storage upload failed, using local path (non-fatal): $e');
        storageUrl = filePath; // Use local path as fallback
      }

      // Step 5: Generate a unique ID without external package
      final String pdfId = _generateId();

      final newPdf = PdfModel(
        id: pdfId,
        userId: userId,
        fileName: fileName,
        fileSize: fileSize,
        localPath: filePath,
        storageUrl: storageUrl,
        pageCount: pageCount,
        uploadTimestamp: DateTime.now().millisecondsSinceEpoch,
        topic: topicName,
        subject: detectedSubject,
        summary: summary,
        keywords: keywords,
        extractedPagesText: extractedTextPages,
      );

      // Step 6: Save metadata to DB
      await _dbService.savePdf(newPdf);

      _pdfs.insert(0, newPdf);
      _isLoading = false;
      notifyListeners();

      return newPdf;
    } catch (e) {
      _errorMessage = "Upload failed: ${e.toString().replaceAll('Exception: ', '')}";
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Generates a simple random unique ID (no external package needed)
  String _generateId() {
    final rng = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = List.generate(8, (_) => rng.nextInt(256)
        .toRadixString(16)
        .padLeft(2, '0'))
        .join();
    return '$timestamp-$randomPart';
  }

  Future<void> toggleFavorite(String userId, PdfModel pdf) async {
    final updatedPdf = pdf.copyWith(isFavorite: !pdf.isFavorite);
    try {
      await _dbService.savePdf(updatedPdf);
      final idx = _pdfs.indexWhere((p) => p.id == pdf.id);
      if (idx >= 0) {
        _pdfs[idx] = updatedPdf;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  Future<void> deletePdf(String userId, String pdfId) async {
    try {
      await _dbService.deletePdf(userId, pdfId);
      _pdfs.removeWhere((p) => p.id == pdfId);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Failed to delete file: $e";
      notifyListeners();
    }
  }

  /// Increments or tracks reading progress within PDF model
  Future<void> updateReadingProgress(String userId, PdfModel pdf, int pageIndex, int position) async {
    final updatedPdf = pdf.copyWith(lastReadPage: pageIndex, lastReadPosition: position);
    try {
      await _dbService.savePdf(updatedPdf);
      final idx = _pdfs.indexWhere((p) => p.id == pdf.id);
      if (idx >= 0) {
        _pdfs[idx] = updatedPdf;
      }
    } catch (e) {
      debugPrint("Error updating reading progress: $e");
    }
  }
}
