import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/constants/linklian-icon.dart';
import 'package:LinkLian/features/chat/presentation/pages/ai_quiz_page.dart';
import 'package:LinkLian/features/chat/presentation/pages/quiz_attempt_store.dart';
import 'package:LinkLian/features/chat/presentation/widgets/ai_quiz_popup.widget.dart';
import 'package:LinkLian/features/shared/repositories/ai_chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AIQuizCollectionPage extends StatefulWidget {
  final int aiChatId;
  final Map<String, dynamic>? initialQuiz;

  const AIQuizCollectionPage({
    super.key,
    required this.aiChatId,
    this.initialQuiz,
  });

  @override
  State<AIQuizCollectionPage> createState() => _AIQuizCollectionPageState();
}

class _AIQuizCollectionPageState extends State<AIQuizCollectionPage> {
  final AIChatRepository _repo = AIChatRepository();
  final List<Map<String, dynamic>> _quizzes = <Map<String, dynamic>>[];
  final Set<int> _quizIds = <int>{};

  bool _isLoading = true;
  bool _autoOpened = false;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  int _quizId(Map<String, dynamic> quiz) {
    final raw = quiz['quiz_id'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  int _storeKey(Map<String, dynamic> quiz) {
    final id = _quizId(quiz);
    if (id > 0) return id;

    // Stable fallback key for quizzes without quiz_id.
    final questions = List.from(quiz['questions'] ?? const []);
    final seed = <String>[
      quiz['title']?.toString() ?? '',
      quiz['difficulty']?.toString() ?? '',
      questions.isNotEmpty ? questions.first['question']?.toString() ?? '' : '',
      questions.length.toString(),
    ].join('|');
    return -(seed.hashCode.abs() + 1);
  }

  String _difficultyLabel(String? difficulty) {
    switch ((difficulty ?? '').toLowerCase()) {
      case 'easy':
        return 'ง่าย';
      case 'hard':
        return 'ยาก';
      case 'medium':
      default:
        return 'ปานกลาง';
    }
  }

  DateTime? _parseCreatedAt(Map<String, dynamic> quiz) {
    final raw = quiz['created_at'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  void _sortQuizzesNewestFirst() {
    _quizzes.sort((left, right) {
      final rightCreatedAt = _parseCreatedAt(right);
      final leftCreatedAt = _parseCreatedAt(left);

      if (rightCreatedAt != null && leftCreatedAt != null) {
        final byCreatedAt = rightCreatedAt.compareTo(leftCreatedAt);
        if (byCreatedAt != 0) return byCreatedAt;
      } else if (rightCreatedAt != null) {
        return 1;
      } else if (leftCreatedAt != null) {
        return -1;
      }

      return _quizId(right).compareTo(_quizId(left));
    });
  }

  String _buildQuizMetaText(
    Map<String, dynamic> quiz,
    int questionCount,
    QuizAttemptResult? result,
  ) {
    final parts = <String>[
      '$questionCount คำถาม',
      _difficultyLabel(quiz['difficulty']?.toString()),
    ];

    if (result != null) {
      parts.add('ได้ ${result.correct}/${result.total}');
    }

    return parts.join(' • ');
  }

  String? _formatCreatedAt(Map<String, dynamic> quiz) {
    final createdAt = _parseCreatedAt(quiz);
    if (createdAt == null) return null;
    return DateFormat('HH:mm • dd/MM/yyyy').format(createdAt);
  }

  int _effectiveTotal(int questionCount, QuizAttemptResult? result) {
    if (result != null && result.total > 0) return result.total;
    return questionCount;
  }

  int _effectiveCorrect(QuizAttemptResult? result) {
    if (result == null) return 0;
    return result.correct < 0 ? 0 : result.correct;
  }

  double _progressValue(int questionCount, QuizAttemptResult? result) {
    final total = _effectiveTotal(questionCount, result);
    if (total <= 0) return 0;
    final correct = _effectiveCorrect(result).clamp(0, total);
    return correct / total;
  }

  Widget _buildMetaPill({
    IconData? icon,
    required String label,
    Color? textColor,
    Color? backgroundColor,
  }) {
    final fg = textColor ?? AppColors.black.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.buttonPalette[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  void _appendQuiz(Map<String, dynamic> quiz) {
    final map = Map<String, dynamic>.from(quiz);
    final id = _quizId(map);

    if (id > 0) {
      if (_quizIds.contains(id)) return;
      _quizIds.add(id);
    }

    _quizzes.add(map);
    _sortQuizzesNewestFirst();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _quizzes.clear();
      _quizIds.clear();
    });

    if (widget.initialQuiz != null) {
      _appendQuiz(widget.initialQuiz!);
    }

    try {
      final fetched = await _repo.getQuiz(widget.aiChatId);
      for (final quiz in fetched) {
        _appendQuiz(quiz);
      }
    } catch (_) {
      // Show whatever data we currently have.
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Fetch attempts from backend for quizzes not already cached in the store.
    _loadAttemptsFromServer();

    if (!_autoOpened && widget.initialQuiz != null && _quizzes.isNotEmpty) {
      _autoOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openQuiz(_quizzes.first, _storeKey(_quizzes.first));
      });
    }
  }

  Future<void> _loadAttemptsFromServer() async {
    final toFetch = _quizzes.where((quiz) {
      final id = _quizId(quiz);
      if (id <= 0) return false;
      return QuizAttemptStore.getResult(_storeKey(quiz)) == null;
    }).toList();

    if (toFetch.isEmpty) return;

    await Future.wait(toFetch.map((quiz) async {
      final id = _quizId(quiz);
      try {
        final attempt = await _repo.getQuizAttempt(id);
        if (attempt == null) return;
        final rawScore = attempt['score'];
        final rawTotal = attempt['total'];
        if (rawScore == null || rawTotal == null) return;
        final score = rawScore is int ? rawScore : int.tryParse(rawScore.toString()) ?? 0;
        final total = rawTotal is int ? rawTotal : int.tryParse(rawTotal.toString()) ?? 0;
        final answers = <int, String>{};
        final rawAnswers = attempt['answers'];
        if (rawAnswers is Map) {
          rawAnswers.forEach((k, v) {
            final idx = int.tryParse(k.toString());
            if (idx != null) answers[idx] = v.toString();
          });
        }
        QuizAttemptStore.saveResult(
          storeKey: _storeKey(quiz),
          correct: score,
          total: total,
          userAnswers: answers,
        );
      } catch (_) {}
    }));

    if (!mounted) return;
    setState(() {});
  }

  void _openQuiz(Map<String, dynamic> quiz, int storeKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIQuizPage(
          quiz: Map<String, dynamic>.from(quiz),
          storeKey: storeKey,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _showGeneratePopup() {
    showDialog(
      context: context,
      builder: (_) {
        return AIQuizPopup(
          onGenerate: (difficulty, questionCount) {
            Navigator.pop(context);
            Navigator.pop(context, {
              'action': 'generate',
              'difficulty': difficulty,
              'questionCount': questionCount,
            });
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SizedBox.expand(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Icon(
                LinkLianIcon.fileTextSpark,
                size: 60,
                color: AppColors.primaryPalette[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ยังไม่มีแบบทดสอบ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryPalette[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'กดปุ่มด้านล่างเพื่อสร้างแบบทดสอบแรกของคุณ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.primaryPalette[500],
              ),
            ),
            const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: _showGeneratePopup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPalette[100],
                    foregroundColor: AppColors.primaryPalette[700],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.primaryPalette[200]!),
                    ),
                  ),
                  child: const Text(
                    'สร้างแบบทดสอบ',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizTile(Map<String, dynamic> quiz, int index) {
    final id = _quizId(quiz);
    final storeKey = _storeKey(quiz);
    final questions = List.from(quiz['questions'] ?? const []);
    final result = QuizAttemptStore.getResult(storeKey);
    final createdAtText = _formatCreatedAt(quiz);
    final total = _effectiveTotal(questions.length, result);
    final correct = _effectiveCorrect(result).clamp(0, total);
    final progress = _progressValue(questions.length, result);
    final difficulty = _difficultyLabel(quiz['difficulty']?.toString());

    Color difficultyColor;
    Color difficultyBg;
    if (difficulty == 'ง่าย') {
      difficultyColor = AppColors.successPalette[800]!;
      difficultyBg = AppColors.successPalette[100]!;
    } else if (difficulty == 'ยาก') {
      difficultyColor = AppColors.dangerPalette[500]!;
      difficultyBg = AppColors.dangerPalette[100]!;
    } else {
      difficultyColor = AppColors.warningPalette[700]!;
      difficultyBg = AppColors.warningPalette[100]!;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openQuiz(quiz, storeKey),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    id > 0 ? 'แบบทดสอบ #$id' : 'แบบทดสอบ',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        _buildMetaPill(
                          label: difficulty,
                          textColor: difficultyColor,
                          backgroundColor: difficultyBg,
                        ),
                        _buildMetaPill(
                          label: '${questions.length} คำถาม',
                          textColor: AppColors.primaryPalette[700],
                          backgroundColor: AppColors.primaryPalette[100],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.track_changes,
                  size: 16,
                  color: AppColors.primaryPalette[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '$correct/$total',
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.primaryPalette[100],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryPalette[500]!.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (createdAtText != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 15,
                    color: AppColors.black.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    createdAtText,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'แบบทดสอบ',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: (!_isLoading && _quizzes.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: _showGeneratePopup,
              backgroundColor: AppColors.primaryPalette[400],
              foregroundColor: AppColors.primaryPalette[800],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.primaryPalette[200]!),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'สร้างแบบทดสอบ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 86),
              itemCount: _quizzes.length,
              itemBuilder: (_, index) => _buildQuizTile(_quizzes[index], index),
            ),
    );
  }
}
