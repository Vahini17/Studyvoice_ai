import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }
}

class AiService {
  // User provided API Key
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  late GenerativeModel _model;

  AiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  // Simple list of stop words to filter out for keyword extraction
  static final Set<String> _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'but', 'if', 'then', 'else', 'when', 'at', 'by',
    'from', 'for', 'in', 'out', 'on', 'off', 'over', 'under', 'to', 'into', 'with',
    'about', 'against', 'between', 'through', 'during', 'before', 'after',
    'above', 'below', 'of', 'as', 'until', 'while', 'is', 'am', 'are',
    'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did',
    'will', 'would', 'shall', 'should', 'can', 'could', 'may', 'might', 'must', 'that',
    'this', 'these', 'those', 'their', 'them', 'they', 'your', 'ours', 'mine', 'more',
    'some', 'such', 'very', 'same', 'both', 'each', 'few', 'than', 'thus',
    'what', 'which', 'who', 'whom',
  };

  // Dynamic Subject Detector keywords
  static const Map<String, List<String>> _subjectKeywords = {
    'Science': ['science', 'physics', 'chemistry', 'biology', 'gravity', 'photosynthesis', 'energy', 'atom', 'molecule', 'plant', 'cell', 'organism', 'earth', 'space', 'galaxy'],
    'History': ['history', 'king', 'queen', 'war', 'emperor', 'empire', 'century', 'battle', 'revolution', 'treaty', 'ancient', 'medieval', 'civilization', 'government', 'independence'],
    'Technology': ['technology', 'computer', 'software', 'hardware', 'code', 'programming', 'network', 'internet', 'data', 'algorithm', 'system', 'database', 'ai', 'digital', 'security'],
    'Literature': ['literature', 'poetry', 'novel', 'author', 'writer', 'drama', 'metaphor', 'tragedy', 'comedy', 'prose', 'fiction', 'narrative', 'theme', 'character', 'book'],
    'Business': ['business', 'finance', 'economics', 'market', 'money', 'investment', 'capital', 'revenue', 'profit', 'management', 'marketing', 'corporate', 'startup', 'strategy']
  };

  /// Generates a summary from the PDF text using Gemini AI
  Future<String> generateSummary(String text) async {
    if (text.isEmpty) return 'No content available to summarize.';

    // Truncate to avoid sending huge payloads (max ~2000 chars for speed)
    final truncated = text.length > 2000 ? text.substring(0, 2000) : text;

    try {
      final prompt =
          'Summarize this study material using bullet points for a student:\n\n$truncated';
      final response = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 10));

      if (response.text != null && response.text!.isNotEmpty) {
        return '✨ AI Study Summary\n\n${response.text}';
      }
    } catch (e) {
      debugPrint('AI summary skipped (timeout or error): $e');
    }

    // Fast local fallback
    final sentences = _splitIntoSentences(text);
    if (sentences.isEmpty) return 'This document contains no readable sentences.';
    final List<String> summarySentences = [sentences.first];
    final emphasisRegex = RegExp(
        r'\b(therefore|consequently|importantly|conclusion|essential|significant|key|main|primary|focus)\b',
        caseSensitive: false);
    for (int i = 1; i < sentences.length; i++) {
      final s = sentences[i].trim();
      if (s.length > 30 && s.length < 150 && emphasisRegex.hasMatch(s)) {
        summarySentences.add(s);
        if (summarySentences.length >= 5) break;
      }
    }
    if (summarySentences.length < 3 && sentences.length > 2) {
      summarySentences.add(sentences[sentences.length ~/ 2]);
    }
    final sb = StringBuffer();
    sb.writeln('✨ Study Summary (Local)\n');
    for (var sentence in summarySentences) {
      sb.writeln('• ${sentence.trim()}');
    }
    return sb.toString();
  }

  /// Extracts keywords using Gemini AI with fallback to local NLP
  Future<List<String>> extractKeywords(String text) async {
    if (text.isEmpty) return [];

    // Truncate to avoid huge payloads
    final truncated = text.length > 1500 ? text.substring(0, 1500) : text;

    try {
      final prompt =
          'Extract 6 important keywords from this text. Return ONLY a comma-separated list:\n\n$truncated';
      final response = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 10));

      if (response.text != null && response.text!.isNotEmpty) {
        final List<String> aiKeywords = response.text!
            .split(',')
            .map((s) => s.trim().replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ''))
            .where((s) => s.isNotEmpty)
            .take(6)
            .toList();
        if (aiKeywords.isNotEmpty) return aiKeywords;
      }
    } catch (e) {
      debugPrint('AI keywords skipped (timeout or error): $e');
    }

    // Fast local NLP fallback
    final cleanText = text.replaceAll(RegExp(r'[^\w\s]'), ' ').toLowerCase();
    final words = cleanText.split(RegExp(r'\s+'));
    final Map<String, int> frequencies = {};
    for (var word in words) {
      if (word.length > 3 &&
          !_stopWords.contains(word) &&
          !RegExp(r'^\d+$').hasMatch(word)) {
        frequencies[word] = (frequencies[word] ?? 0) + 1;
      }
    }
    final sortedKeywords = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedKeywords
        .take(6)
        .map((e) => e.key[0].toUpperCase() + e.key.substring(1))
        .toList();
  }

  /// Auto detects subject using local dictionary mapping (fastest)
  Future<String> detectSubject(String text) async {
    if (text.isEmpty) return 'Custom';
    final lowerText = text.toLowerCase();
    String bestSubject = 'Custom';
    int maxMatches = 0;
    _subjectKeywords.forEach((subject, keywords) {
      int matches = 0;
      for (var kw in keywords) {
        if (lowerText.contains(kw)) {
          matches++;
        }
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        bestSubject = subject;
      }
    });
    return bestSubject;
  }

  /// Generates a Quiz with Gemini AI fallback to local rules
  Future<List<QuizQuestion>> generateQuiz(String text, {int questionCount = 4}) async {
    if (text.isEmpty || text.length < 100) {
      return _generateDefaultQuiz();
    }

    try {
      final prompt = '''
Generate a $questionCount-question multiple choice quiz based on this text.
Format EXACTLY like this for each question, with a blank line between questions:
Q: [Question text]
O1: [Option 1]
O2: [Option 2]
O3: [Option 3]
O4: [Option 4]
A: [Correct Option Number 1-4]
E: [Explanation]

Text:
$text
''';
      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text != null && response.text!.isNotEmpty) {
        return _parseAiQuiz(response.text!);
      }
    } catch (e) {
      debugPrint("AI API Error: $e");
    }

    // Fallback local logic
    final sentences = _splitIntoSentences(text);
    final keywords = await extractKeywords(text);
    if (sentences.length < 5 || keywords.isEmpty) {
      return _generateDefaultQuiz();
    }
    final List<QuizQuestion> generatedQuestions = [];
    for (var keyword in keywords) {
      if (generatedQuestions.length >= questionCount) break;
      String? matchingSentence;
      for (var sentence in sentences) {
        final cleanSentence = sentence.trim();
        if (cleanSentence.toLowerCase().contains(keyword.toLowerCase()) && 
            cleanSentence.length > 40 && cleanSentence.length < 160) {
          matchingSentence = cleanSentence;
          break;
        }
      }
      if (matchingSentence != null) {
        final escapedKeyword = RegExp.escape(keyword);
        final maskRegex = RegExp('\\b$escapedKeyword\\b', caseSensitive: false);
        final maskedQuestionText = matchingSentence.replaceAll(maskRegex, '_______');
        final Set<String> options = {keyword};
        final otherKeywords = keywords.where((kw) => kw != keyword).toList();
        otherKeywords.shuffle();
        for (var distractor in otherKeywords) {
          if (options.length < 4) options.add(distractor);
        }
        final backupDistractors = ['Evaluation', 'Analysis', 'Development', 'Synthesis', 'Hypothesis', 'Correlation'];
        backupDistractors.shuffle();
        for (var dist in backupDistractors) {
          if (options.length < 4) options.add(dist);
        }
        final optionsList = options.toList();
        optionsList.shuffle();
        final correctIdx = optionsList.indexOf(keyword);
        generatedQuestions.add(QuizQuestion(
          question: "Fill in the blank:\n\n\"$maskedQuestionText\"",
          options: optionsList,
          correctAnswerIndex: correctIdx,
          explanation: "In this textbook section, '$keyword' is the critical concept identified: \"$matchingSentence\"",
        ));
      }
    }
    if (generatedQuestions.isEmpty) return _generateDefaultQuiz();
    return generatedQuestions;
  }

  List<QuizQuestion> _parseAiQuiz(String rawAiText) {
    final List<QuizQuestion> questions = [];
    final blocks = rawAiText.split('\n\n');
    for (var block in blocks) {
      try {
        final lines = block.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        if (lines.length >= 7) {
          final q = lines.firstWhere((l) => l.startsWith('Q:')).substring(2).trim();
          final o1 = lines.firstWhere((l) => l.startsWith('O1:')).substring(3).trim();
          final o2 = lines.firstWhere((l) => l.startsWith('O2:')).substring(3).trim();
          final o3 = lines.firstWhere((l) => l.startsWith('O3:')).substring(3).trim();
          final o4 = lines.firstWhere((l) => l.startsWith('O4:')).substring(3).trim();
          final aLine = lines.firstWhere((l) => l.startsWith('A:')).substring(2).trim();
          final e = lines.firstWhere((l) => l.startsWith('E:')).substring(2).trim();
          
          final correctIdx = int.parse(aLine) - 1;
          questions.add(QuizQuestion(
            question: q,
            options: [o1, o2, o3, o4],
            correctAnswerIndex: correctIdx,
            explanation: e,
          ));
        }
      } catch (e) {
        debugPrint("Error parsing AI quiz block: $e");
      }
    }
    if (questions.isEmpty) return _generateDefaultQuiz();
    return questions;
  }

  List<String> _splitIntoSentences(String text) {
    final sentencePattern = RegExp(r'(?<=[.!?])\s+(?=[A-Z\d])|(?<=[.!?])\n');
    return text.split(sentencePattern).where((s) => s.trim().length > 15).toList();
  }

  List<QuizQuestion> _generateDefaultQuiz() {
    return [
      QuizQuestion(
        question: "What is the primary benefit of converting study text into AI speech?",
        options: ["Multitasking and audio learning", "It prints physical papers", "It deletes old folders", "It speeds up device charging"],
        correctAnswerIndex: 0,
        explanation: "Converting text to speech allows students to study on the go, utilizing auditory memory channels while walking, traveling, or resting.",
      ),
      QuizQuestion(
        question: "Which studying technique benefits most from listening to compressed AI summaries?",
        options: ["Passive scrolling", "Spaced repetition & Active recall", "Copying word-for-word", "Midnight cramming without sleep"],
        correctAnswerIndex: 1,
        explanation: "Spaced repetition is optimized by fast, repeated listening to summarized conceptual summaries to audit knowledge recall.",
      ),
    ];
  }

  Future<List<String>> generateRecommendations(List<String> subjects) async {
    final List<String> recs = [];
    if (subjects.isEmpty) {
      return [
        "📚 Upload your first PDF to begin AI subject analysis!",
        "⏱️ Try setting a daily study reminder in Settings for consistent habits.",
      ];
    }
    if (subjects.contains('Science')) {
      recs.add("🔬 Your science documents contain dense vocabulary. Try listening at 1.0x speed and pause to write bookmarks on diagrams.");
    }
    if (subjects.contains('History')) {
      recs.add("⏳ History relies on chronology. Try summarizing chapters page-by-page to link historical sequences together.");
    }
    if (subjects.contains('Technology')) {
      recs.add("💻 Computer science concepts are best retained by taking mock quizzes. Test yourself with our AI Quiz generator!");
    }
    if (subjects.contains('Literature')) {
      recs.add("✍️ Enhance literature analysis by highlighting important character descriptions and adding annotations.");
    }
    recs.add("🌟 Remember to take a 5-minute break for every 25 minutes of audio learning (Pomodoro Audio rule)!");
    return recs;
  }
}
