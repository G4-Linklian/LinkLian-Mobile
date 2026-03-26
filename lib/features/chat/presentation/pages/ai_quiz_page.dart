import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/features/chat/presentation/pages/quiz_attempt_store.dart';
import 'package:LinkLian/features/chat/presentation/pages/quiz_result_page.dart';
import 'package:LinkLian/features/shared/repositories/ai_chat_repository.dart';
import 'package:flutter/material.dart';

class AIQuizPage extends StatefulWidget {
  final Map<String, dynamic> quiz;
  final int storeKey;

  const AIQuizPage({super.key, required this.quiz, required this.storeKey});

  @override
  State<AIQuizPage> createState() => _AIQuizPageState();
}

class _AIQuizPageState extends State<AIQuizPage> {
  int currentIndex = 0;
  final Map<int, String> userAnswers = <int, String>{};
  int correctCount = 0;
  int wrongCount = 0;
  bool _isOpeningResult = false;
  bool _showExamReview = false;

  static const List<String> _thaiLabels = [
    'ก',
    'ข',
    'ค',
    'ง',
    'จ',
    'ฉ',
    'ช',
    'ซ',
    'ญ',
    'ฎ',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedAnswers();
    _loadAttemptFromServer();
  }

  void _loadSavedAnswers() {
    final result = QuizAttemptStore.getResult(widget.storeKey);
    final saved = (result != null && result.userAnswers.isNotEmpty)
        ? result.userAnswers
        : QuizAttemptStore.getProgress(widget.storeKey);
    if (saved == null || saved.isEmpty) return;
    final qs = questions;
    userAnswers.addAll(saved);
    _recalculateCounts();

    if (mode == 'exam' && result != null && saved.length >= qs.length) {
      _showExamReview = true;
    }
  }

  Future<void> _loadAttemptFromServer() async {
    final repo = AIChatRepository();

    final attempt = await repo.getQuizAttempt(quizId);

    if (attempt == null) return;

    final answers = Map<String, dynamic>.from(attempt["answers"] ?? {});

    setState(() {
      userAnswers.clear();

      userAnswers.addAll(
        answers.map((k, v) => MapEntry(int.parse(k), v.toString())),
      );
      _recalculateCounts();
      if (mode == 'exam' && userAnswers.length >= questions.length) {
        _showExamReview = true;
      }
    });
  }

  List<Map<String, dynamic>> get questions {
    final raw = widget.quiz['questions'];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int get quizId {
    final raw = widget.quiz['quiz_id'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  String get mode => widget.quiz['mode'] ?? 'exam';
  bool get hasAnsweredCurrent => userAnswers.containsKey(currentIndex);
  bool get _allAnswered => userAnswers.length >= questions.length;

  void _recalculateCounts() {
    int correct = 0;
    int wrong = 0;

    for (final entry in userAnswers.entries) {
      if (entry.key >= questions.length) continue;
      final answer = questions[entry.key]['answer']?.toString() ?? '';
      if (entry.value == answer) {
        correct++;
      } else {
        wrong++;
      }
    }

    correctCount = correct;
    wrongCount = wrong;
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('ไม่พบคำถาม')));
    }

    final question = questions[currentIndex];
    final total = questions.length;
    final choices = List<String>.from(question['choices'] ?? const <String>[]);
    final isLastQuestion = currentIndex == total - 1;
    final canPrimaryAction =
        hasAnsweredCurrent &&
        !_isOpeningResult &&
        (mode != 'exam' || !isLastQuestion || _allAnswered);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // appBar: AppBar(
      //   title: Text(mode == 'learning' ? 'แบบการเรียนรู้' : 'แบบทดสอบ'),
      //   backgroundColor: Colors.white,
      //   foregroundColor: Colors.black,
      //   elevation: 0.5,
      //   shadowColor: Colors.black.withValues(alpha: 0.1),
      //   scrolledUnderElevation: 0,
      //   surfaceTintColor: Colors.white,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      // ),
      appBar: AppBar(
        title: Text(
          widget.quiz['quiz_title'] ?? 'แบบฝึก',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.black,),
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildProgressBar(total)),
                const SizedBox(width: 10),
                Text(
                  '${currentIndex + 1} / $total',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (mode == "learning") ...[
                  const SizedBox(width: 10),
                  _scoreBadge(
                    icon: Icons.close,
                    count: wrongCount,
                    iconColor: AppColors.dangerPalette[500]!,
                    bgColor: AppColors.dangerPalette[200]!,
                  ),
                  const SizedBox(width: 6),
                  _scoreBadge(
                    icon: Icons.check,
                    count: correctCount,
                    iconColor: AppColors.successPalette[700]!,
                    bgColor: AppColors.successPalette[100]!,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            Text(
              '${currentIndex + 1}. ${question['question'] ?? ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: choices.length,
                itemBuilder: (_, i) => _buildChoiceTile(
                  choiceIndex: i,
                  choice: choices[i],
                  question: question,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primaryPalette[500]!),
                        foregroundColor: AppColors.primaryPalette[600],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      onPressed: currentIndex == 0
                          ? null
                          : () => setState(() => currentIndex--),
                      child: const Text('กลับ'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPalette[500],
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primaryPalette[200],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      onPressed: !canPrimaryAction
                          ? null
                          : () {
                              if (mode == "exam") {
                                if (currentIndex < total - 1) {
                                  setState(() => currentIndex++);
                                  return;
                                }
                                _submitExam(total);
                              } else {
                                if (currentIndex < total - 1) {
                                  setState(() => currentIndex++);
                                  return;
                                }
                                _openResult(total);
                              }
                            },
                      child: Text(
                        currentIndex < total - 1
                            ? 'ถัดไป'
                            : (mode == 'exam' ? 'ดูผลคะแนน' : 'ดูผลลัพธ์'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitExam(int total) async {
    _recalculateCounts();

    final repo = AIChatRepository();

    await repo.saveQuizAttempt(
      quizId: quizId,
      score: correctCount,
      total: total,
      answers: userAnswers,
    );

    _showExamReview = true;

    _openResult(total);
  }

  Widget _scoreBadge({
    required IconData icon,
    required int count,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int total) {
    return Row(
      children: List.generate(total, (index) {
        final answered = userAnswers.containsKey(index);
        final active = index == currentIndex;

        Color barColor;
        if (active) {
          barColor = AppColors.primaryPalette[500]!;
        } else if (answered) {
          barColor = AppColors.primaryPalette[300]!;
        } else {
          barColor = AppColors.primaryPalette[100]!;
        }

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => currentIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 6,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildChoiceTile({
    required int choiceIndex,
    required String choice,
    required Map<String, dynamic> question,
  }) {
    final answer = question['answer']?.toString() ?? '';
    final explanation = question['explanation']?.toString() ?? '';
    final selected = userAnswers[currentIndex];
    final hasAnswered = selected != null;

    final isCorrect = choice == answer;
    final isSelected = choice == selected;
    final showExamReveal = mode == 'exam' && _showExamReview;

    // Background color
    Color bg = Colors.white;
    if ((mode == "learning" && hasAnswered && isCorrect) ||
        (showExamReveal && isCorrect)) {
      bg = AppColors.successPalette[100]!;
    } else if ((mode == "learning" &&
            hasAnswered &&
            isSelected &&
            !isCorrect) ||
        (showExamReveal && isSelected && !isCorrect)) {
      bg = AppColors.dangerPalette[200]!;
    } else if (mode == 'exam' && isSelected) {
      bg = AppColors.primaryPalette[100]!;
    }

    // final borderColor = isSelected
    //     ? AppColors.primaryPalette[400]!
    //     : AppColors.primaryPalette[100]!;
    Color borderColor;

    if (mode == "learning" && hasAnswered) {
      if (isCorrect) {
        borderColor = AppColors.successPalette[500]!;
      } else if (isSelected && !isCorrect) {
        borderColor = AppColors.dangerPalette[500]!;
      } else {
        borderColor = AppColors.primaryPalette[100]!;
      }
    } else if (showExamReveal) {
      if (isCorrect) {
        borderColor = AppColors.successPalette[500]!;
      } else if (isSelected && !isCorrect) {
        borderColor = AppColors.dangerPalette[500]!;
      } else {
        borderColor = AppColors.primaryPalette[100]!;
      }
    } else {
      borderColor = isSelected
          ? AppColors.primaryPalette[400]!
          : AppColors.primaryPalette[100]!;
    }

    final label = choiceIndex < _thaiLabels.length
        ? _thaiLabels[choiceIndex]
        : '${choiceIndex + 1}';

    return GestureDetector(
      // onTap: () {
      //   if (hasAnswered) return;
      //   setState(() {
      //     userAnswers[currentIndex] = choice;
      //     if (choice == answer) {
      //       correctCount++;
      //     } else {
      //       wrongCount++;
      //     }
      //   });
      //   QuizAttemptStore.saveProgress(widget.storeKey, userAnswers);
      // },
      onTap: () async {
        if (mode == "exam" && _showExamReview) return;

        if (mode == "learning") {
          setState(() {
            userAnswers[currentIndex] = choice;
            _recalculateCounts();
          });

          QuizAttemptStore.saveProgress(widget.storeKey, userAnswers);

          try {
            final repo = AIChatRepository();
            await repo.checkAnswer(
              quizId: quizId,
              questionIndex: currentIndex,
              selected: choice,
            );
          } catch (_) {}
        } else {
          setState(() {
            userAnswers[currentIndex] = choice;
            _recalculateCounts();
          });

          QuizAttemptStore.saveProgress(widget.storeKey, userAnswers);
        }
      },

      // onTap: () async {
      //   if (mode == "learning") {
      //     setState(() {
      //       userAnswers[currentIndex] = choice;
      //       _recalculateCounts();
      //     });

      //     QuizAttemptStore.saveProgress(widget.storeKey, userAnswers);

      //     // Keep backend validation as best-effort so learning mode always
      //     // reveals immediately even if the network request fails.
      //     try {
      //       final repo = AIChatRepository();
      //       await repo.checkAnswer(
      //         quizId: quizId,
      //         questionIndex: currentIndex,
      //         selected: choice,
      //       );
      //     } catch (_) {}
      //   } else {
      //     setState(() {
      //       userAnswers[currentIndex] = choice;
      //       _recalculateCounts();
      //     });

      //     QuizAttemptStore.saveProgress(widget.storeKey, userAnswers);
      //   }
      // },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Choice label + text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label. ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Text(choice, style: const TextStyle(fontSize: 15)),
                ),
              ],
            ),

            // Wrong feedback
            if ((mode == "learning" || showExamReveal) &&
                hasAnswered &&
                isSelected &&
                !isCorrect) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.dangerPalette[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ยังไม่ใช่',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dangerPalette[500],
                    ),
                  ),
                ],
              ),
            ],

            // Correct feedback
            if ((mode == "learning" || showExamReveal) &&
                hasAnswered &&
                isCorrect) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.successPalette[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'คำตอบถูกต้อง',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.successPalette[700],
                    ),
                  ),
                ],
              ),
              if (explanation.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.black.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _openResult(int total) async {
    if (_isOpeningResult) return;

    setState(() {
      _isOpeningResult = true;
    });

    final repo = AIChatRepository();
    final alreadyCompleted =
        QuizAttemptStore.getResult(widget.storeKey) != null;

    if (!alreadyCompleted && quizId > 0) {
      try {
        await repo.saveQuizAttempt(
          quizId: quizId,
          score: correctCount,
          total: total,
          answers: userAnswers,
        );
      } catch (_) {}
    }

    QuizAttemptStore.saveResult(
      storeKey: widget.storeKey,
      correct: correctCount,
      total: total,
      userAnswers: Map<int, String>.from(userAnswers),
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPage(
          correct: correctCount,
          total: total,
          mode: mode,
          onReview: () {
            Navigator.pop(context);
            setState(() {
              currentIndex = 0;
              if (mode == 'exam') {
                _showExamReview = true;
              }
            });
          },
          onBackToList: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _isOpeningResult = false;
    });
  }
}
