import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_voice_ai/core/theme/app_theme.dart';
import 'package:study_voice_ai/core/widgets/custom_button.dart';
import 'package:study_voice_ai/core/widgets/glass_card.dart';
import 'package:study_voice_ai/viewmodels/player_viewmodel.dart';
import 'package:study_voice_ai/services/ai_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final AiService _aiService = AiService();
  
  List<QuizQuestion> _questions = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  int _score = 0;
  bool _quizFinished = false;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  Future<void> _generateQuiz() async {
    final playerVM = Provider.of<PlayerViewModel>(context, listen: false);
    if (playerVM.currentPdf == null) return;

    final fullText = playerVM.currentPdf!.extractedPagesText.join("\n");
    final generated = await _aiService.generateQuiz(fullText, questionCount: 4);

    setState(() {
      _questions = generated;
      _isLoading = false;
    });
  }

  void _handleOptionSelect(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedOptionIndex = index;
      _isAnswered = true;
      
      if (index == _questions[_currentQuestionIndex].correctAnswerIndex) {
        _score++;
      }
    });
  }

  void _handleNext() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _isAnswered = false;
      });
    } else {
      setState(() {
        _quizFinished = true;
      });
    }
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOptionIndex = null;
      _isAnswered = false;
      _score = 0;
      _quizFinished = false;
      _isLoading = true;
    });
    _generateQuiz();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playerVM = Provider.of<PlayerViewModel>(context);
    final pdfName = playerVM.currentPdf?.fileName ?? "Study File";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "AI Recall Quiz: $pdfName",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
          child: _isLoading
              ? _buildLoader()
              : _quizFinished
                  ? _buildFinishedDashboard()
                  : _buildQuizDeck(),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3.5),
          ),
          const SizedBox(height: 24),
          Text(
            "AI Reading Textbook Contents...",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Generating custom multiple choice conceptual questions...",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizDeck() {
    final q = _questions[_currentQuestionIndex];
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step Counter progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "QUESTION ${_currentQuestionIndex + 1} OF ${_questions.length}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5, color: AppTheme.primaryColor),
              ),
              Text(
                "Score: $_score/${_questions.length}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),

          // Question Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Text(
              q.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
          const SizedBox(height: 24),

          // Option cards
          Expanded(
            child: ListView.separated(
              itemCount: q.options.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final option = q.options[idx];
                return _buildOptionCard(option, idx, q.correctAnswerIndex);
              },
            ),
          ),

          // Rationale explanation card (fades in when answered)
          if (_isAnswered) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              color: q.correctAnswerIndex == _selectedOptionIndex ? Colors.green : Colors.red,
              backgroundOpacity: 0.05,
              borderOpacity: 0.2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        q.correctAnswerIndex == _selectedOptionIndex 
                            ? Icons.check_circle_outline_rounded 
                            : Icons.error_outline_rounded,
                        color: q.correctAnswerIndex == _selectedOptionIndex ? Colors.green : Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        q.correctAnswerIndex == _selectedOptionIndex ? "Correct Answer!" : "Incorrect Answer",
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: q.correctAnswerIndex == _selectedOptionIndex ? Colors.green : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.explanation,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          CustomButton(
            text: _currentQuestionIndex == _questions.length - 1 ? "Finish Quiz" : "Next Question",
            onPressed: _isAnswered ? _handleNext : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String optionText, int optionIdx, int correctIdx) {
    final isSel = _selectedOptionIndex == optionIdx;
    final isCorrect = correctIdx == optionIdx;
    
    Color borderCol = Colors.transparent;
    Color bgCol = Theme.of(context).cardColor;
    Color textCol = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    if (_isAnswered) {
      if (isCorrect) {
        borderCol = Colors.green;
        bgCol = Colors.green.withOpacity(0.12);
        textCol = Colors.green;
      } else if (isSel) {
        borderCol = Colors.redAccent;
        bgCol = Colors.redAccent.withOpacity(0.12);
        textCol = Colors.redAccent;
      }
    } else if (isSel) {
      borderCol = AppTheme.primaryColor;
      bgCol = AppTheme.primaryColor.withOpacity(0.08);
      textCol = AppTheme.primaryColor;
    }

    return GestureDetector(
      onTap: () => _handleOptionSelect(optionIdx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderCol != Colors.transparent 
                ? borderCol 
                : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.06),
            width: borderCol != Colors.transparent ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textCol,
                ),
              ),
            ),
            if (_isAnswered && isCorrect)
              const Icon(Icons.check_circle_rounded, color: Colors.green)
            else if (_isAnswered && isSel)
              const Icon(Icons.cancel_rounded, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishedDashboard() {
    final ratio = _score / _questions.length;
    String streakComment = "Let's Review Again!";
    IconData visualIcon = Icons.stars_rounded;
    Color streakColor = Colors.orangeAccent;

    if (ratio >= 0.8) {
      streakComment = "Masterful Active Recall!";
      visualIcon = Icons.workspace_premium_rounded;
      streakColor = Colors.green;
    } else if (ratio >= 0.5) {
      streakComment = "Solid Progress! Keep listening.";
      visualIcon = Icons.thumb_up_alt_rounded;
      streakColor = AppTheme.primaryColor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(visualIcon, size: 90, color: streakColor),
          const SizedBox(height: 24),
          Text(
            "Quiz Completed! 🎉",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            streakComment,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: streakColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 36),

          // Score card details
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text("TOTAL SCORE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Text(
                  "$_score / ${_questions.length}",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 48,
                        color: AppTheme.primaryColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You got ${(ratio * 100).toInt()}% correct!",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          CustomButton(
            text: "Re-Attempt Quiz",
            isSecondary: true,
            onPressed: _resetQuiz,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: "Back to Player",
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
