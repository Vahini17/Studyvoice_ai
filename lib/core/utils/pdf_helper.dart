import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfHelper {
  /// Extracts text page-by-page from a local PDF file path
  static Future<List<String>> extractTextPageByPage(String filePath) async {
    try {
      final File file = File(filePath);
      final Uint8List bytes = await file.readAsBytes();
      return extractTextPageByPageFromBytes(bytes);
    } catch (e) {
      debugPrint("Error reading PDF file path: $e");
      throw Exception("Failed to read PDF file: $e");
    }
  }

  /// Extracts text page-by-page from raw PDF bytes — fully crash-safe
  static Future<List<String>> extractTextPageByPageFromBytes(Uint8List bytes) async {
    final List<String> pagesText = [];
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;
      final PdfTextExtractor extractor = PdfTextExtractor(document);

      for (int i = 0; i < pageCount; i++) {
        try {
          // Extract each page individually with its own try-catch
          final String pageText = extractor.extractText(
            startPageIndex: i,
            endPageIndex: i,
          );
          pagesText.add(pageText.trim().isNotEmpty ? pageText.trim() : '[Page ${i + 1} has no readable text]');
        } catch (pageError) {
          debugPrint("Could not extract text from page $i: $pageError");
          pagesText.add('[Page ${i + 1} could not be read]');
        }
      }

      // Make sure we always return at least 1 page
      if (pagesText.isEmpty) {
        pagesText.add('No readable text found in this PDF.');
      }

      return pagesText;
    } catch (e) {
      debugPrint("Error parsing PDF via Syncfusion: $e");
      // Don't throw — return a placeholder so the rest of the upload still works
      return ['This PDF could not be parsed. It may be scanned or encrypted.'];
    } finally {
      document?.dispose();
    }
  }

  /// Formats bytes into a human readable file size (e.g. 2.4 MB)
  static String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    // Use dart:math for the correct logarithm calculation
    final int i = (math.log(bytes) / math.log(1024)).floor().clamp(0, suffixes.length - 1);
    final double size = bytes / math.pow(1024, i);
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
