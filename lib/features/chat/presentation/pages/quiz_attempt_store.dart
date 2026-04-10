class QuizAttemptResult {
  final int correct;
  final int total;
  final DateTime completedAt;
  final Map<int, String> userAnswers;

  const QuizAttemptResult({
    required this.correct,
    required this.total,
    required this.completedAt,
    this.userAnswers = const <int, String>{},
  });
}

class QuizAttemptStore {
  static final Map<int, QuizAttemptResult> _results = <int, QuizAttemptResult>{};
  static final Map<int, Map<int, String>> _progress = <int, Map<int, String>>{};

  static void saveResult({
    required int storeKey,
    required int correct,
    required int total,
    Map<int, String>? userAnswers,
  }) {
    if (storeKey == 0) return;
    _results[storeKey] = QuizAttemptResult(
      correct: correct,
      total: total,
      completedAt: DateTime.now(),
      userAnswers: userAnswers != null
          ? Map<int, String>.from(userAnswers)
          : const <int, String>{},
    );
    _progress.remove(storeKey);
  }

  static QuizAttemptResult? getResult(int storeKey) {
    if (storeKey == 0) return null;
    return _results[storeKey];
  }

  static void saveProgress(int storeKey, Map<int, String> answers) {
    if (storeKey == 0) return;
    _progress[storeKey] = Map<int, String>.from(answers);
  }

  static Map<int, String>? getProgress(int storeKey) {
    if (storeKey == 0) return null;
    return _progress[storeKey];
  }
}
