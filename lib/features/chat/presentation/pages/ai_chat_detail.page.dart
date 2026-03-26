import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/features/chat/presentation/pages/ai_quiz_collection_page.dart';
import 'package:LinkLian/features/chat/presentation/pages/ai_quiz_page.dart';
import 'package:LinkLian/features/chat/presentation/pages/quiz_attempt_store.dart';
import 'package:LinkLian/features/chat/presentation/widgets/ai_link_preview_card.dart';
import 'package:LinkLian/features/shared/repositories/ai_chat_repository.dart';
import 'package:LinkLian/core/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:LinkLian/features/chat/presentation/widgets/ai_quiz_popup.widget.dart';
import 'package:LinkLian/features/chat/presentation/widgets/chat_attachment_widget.dart';
import 'package:LinkLian/features/chat/presentation/widgets/ai_chat_input_bar.widget.dart';
import 'package:LinkLian/features/chat/presentation/services/ai_summary_notification_service.dart';
import 'package:hugeicons/hugeicons.dart';

class AIChatDetailPage extends StatefulWidget {
  final String title;
  final String documentTitle;
  final int aiChatId;
  final String summary;
  final String content;
  final List attachments;
  final int postContentId;
  final Future<Map<String, dynamic>>? initialSummaryFuture;
  // final String className;

  const AIChatDetailPage({
    super.key,
    required this.title,
    this.documentTitle = '',
    required this.aiChatId,
    required this.summary,
    required this.content,
    required this.attachments,
    required this.postContentId,
    this.initialSummaryFuture,
    // required this.className,
  });

  @override
  State<AIChatDetailPage> createState() => _AIChatDetailPageState();
}

class _AIChatDetailPageState extends State<AIChatDetailPage> {
  static const String _aiAvatarUrl =
      //'https://linklianstorage.blob.core.windows.net/chat/logo/Logo-black-sq.png';
      'https://linklianstorage.blob.core.windows.net/chat/logo/IMG_3422.png';
  //'https://linklianstorage.blob.core.windows.net/chat/logo/IMG_3420.png';

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  final Set<int> _loadedQuizIds = <int>{};

  int _activeAiChatId = 0;
  bool _isSummaryGenerating = false;
  bool _isQuizGenerating = false;
  bool _isAiResponding = false;
  bool _isHistoryLoading = false;
  bool _shouldAnimateInitialHistory = false;
  bool _showScrollToLatestButton = false;
  bool _suppressScrollToLatestButton = true;
  String _currentDocumentTitle = '';
  String _currentPostTitle = '';

  String get _appBarTitle {
    final title = _currentDocumentTitle.trim();
    if (title.isNotEmpty) return title;
    return 'AI Chat';
  }

  String get _appBarSubtitle => _currentPostTitle.trim();

  String get _postCardTitle => _currentPostTitle.trim();

  bool get hasText => _textController.text.trim().isNotEmpty;

  Widget _buildAiAvatar({double size = 32}) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Image.network(
        _aiAvatarUrl,
        fit: BoxFit.cover,
        //errorBuilder: (_, __, ___) => Container(
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.primaryPalette[100],
          child: Icon(
            Icons.auto_awesome,
            size: size * 0.5,
            color: AppColors.primaryPalette[600],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    AISummaryNotificationService.setAIChatDetailVisible(
      true,
      aiChatId: widget.aiChatId,
    );

    _activeAiChatId = widget.aiChatId;
    _currentDocumentTitle = widget.documentTitle;
    _currentPostTitle = widget.title;

    if (_activeAiChatId > 0) {
      // Animate from first message to latest only on initial open.
      _shouldAnimateInitialHistory = true;
    }

    // Show summary immediately without waiting for API
    if (widget.summary.trim().isNotEmpty) {
      messages.add({"isMe": false, "text": widget.summary.trim()});
    }

    _loadMessages();

    if (widget.initialSummaryFuture != null) {
      _handleIncomingSummary(
        widget.initialSummaryFuture!,
        userTriggerText: "สรุปเนื้อหา",
      );
    } else if (_activeAiChatId == 0 && widget.postContentId > 0) {
      final repo = AIChatRepository();
      _handleIncomingSummary(
        repo.generateSummary(widget.postContentId),
        userTriggerText: "สรุปเนื้อหา",
      );
    }
    _textController.addListener(() {
      setState(() {});
    });

    _scrollController.addListener(_onScrollChanged);
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;

    if (_suppressScrollToLatestButton) {
      if (_showScrollToLatestButton) {
        setState(() {
          _showScrollToLatestButton = false;
        });
      }
      return;
    }

    final distanceFromBottom =
        _scrollController.position.maxScrollExtent - _scrollController.offset;
    final shouldShow = distanceFromBottom > 220;

    if (shouldShow != _showScrollToLatestButton) {
      setState(() {
        _showScrollToLatestButton = shouldShow;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AIChatDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.documentTitle != widget.documentTitle ||
        oldWidget.title != widget.title) {
      _currentDocumentTitle = widget.documentTitle;
      _currentPostTitle = widget.title;
    }

    if (oldWidget.summary != widget.summary) {
      setState(() {
        final trimmed = widget.summary.trim();
        if (trimmed.isNotEmpty) {
          messages.add({"isMe": false, "text": trimmed});
        }
      });

      _scrollToBottom();
    }

    if (oldWidget.initialSummaryFuture != widget.initialSummaryFuture &&
        widget.initialSummaryFuture != null) {
      _handleIncomingSummary(widget.initialSummaryFuture!);
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(max);
      } else {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      if (_showScrollToLatestButton) {
        setState(() {
          _showScrollToLatestButton = false;
        });
      }
    });
  }

  void _releaseScrollButtonSuppression() {
    if (!_suppressScrollToLatestButton) return;
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted || !_suppressScrollToLatestButton) return;
      setState(() {
        _suppressScrollToLatestButton = false;
      });
    });
  }

  String _extractSummary(Map<String, dynamic> result) {
    return (result["summary"] ??
            result["data"]?["final_summary"] ??
            result["final_summary"] ??
            "")
        .toString();
  }

  String _extractDocumentTitle(Map<String, dynamic> result) {
    return (result['document_title'] ??
            result['chat_title'] ??
            result['title'] ??
            '')
        .toString()
        .trim();
  }

  String _extractPostTitle(Map<String, dynamic> result) {
    return (result['post_title'] ?? result['postTitle'] ?? '')
        .toString()
        .trim();
  }

  int _extractAiChatId(Map<String, dynamic> result) {
    final raw = result["ai_chat_id"];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  int _extractQuizId(Map<String, dynamic> quiz) {
    final raw = quiz["quiz_id"];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  int _storeKeyForQuiz(Map<String, dynamic> quiz) {
    final quizId = _extractQuizId(quiz);
    if (quizId > 0) return quizId;

    final questions = List.from(quiz['questions'] ?? const []);
    final seed = <String>[
      quiz['title']?.toString() ?? '',
      quiz['difficulty']?.toString() ?? '',
      questions.isNotEmpty ? questions.first['question']?.toString() ?? '' : '',
      questions.length.toString(),
    ].join('|');
    return -(seed.hashCode.abs() + 1);
  }

  void _openQuizDirect(Map<String, dynamic> quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIQuizPage(
          quiz: Map<String, dynamic>.from(quiz),
          storeKey: _storeKeyForQuiz(quiz),
        ),
      ),
    );
  }

  Future<void> _handleIncomingSummary(
    Future<Map<String, dynamic>> summaryFuture, {
    String? userTriggerText,
  }) async {
    if (_isSummaryGenerating) return;

    setState(() {
      _isSummaryGenerating = true;
      if (userTriggerText != null && userTriggerText.trim().isNotEmpty) {
        messages.add({"isMe": true, "text": userTriggerText.trim()});
      }
      messages.add({
        "isMe": false,
        "type": "loading",
        "loadingKind": "summary",
        "text": "AI กำลังสรุปเนื้อหา...",
      });
    });
    _scrollToBottom(jump: true);

    try {
      final result = await summaryFuture;
      final newSummary = _extractSummary(result).trim();
      final newAiChatId = _extractAiChatId(result);
      final newDocumentTitle = _extractDocumentTitle(result);
      final newPostTitle = _extractPostTitle(result);
      final shouldLoadHistory = newAiChatId > 0;
      final targetAiChatId = newAiChatId > 0 ? newAiChatId : _activeAiChatId;
      final targetDocumentTitle = newDocumentTitle.isNotEmpty
          ? newDocumentTitle
          : _appBarTitle;
      final targetPostTitle = newPostTitle.isNotEmpty
          ? newPostTitle
          : _postCardTitle;

      if (userTriggerText != null &&
          userTriggerText.trim().isNotEmpty &&
          newSummary.isNotEmpty &&
          targetAiChatId > 0) {
        AISummaryNotificationService.notifySummaryCompleted(
          aiChatId: targetAiChatId,
          documentTitle: targetDocumentTitle,
          postTitle: targetPostTitle,
          summary: newSummary,
          content: widget.content,
          attachments: List<Map<String, dynamic>>.from(widget.attachments),
          postContentId: widget.postContentId,
        );
      }

      if (!mounted) return;

      setState(() {
        _isSummaryGenerating = false;
        messages.removeWhere(
          (msg) => msg["type"] == "loading" && msg["loadingKind"] == "summary",
        );

        if (!shouldLoadHistory) {
          if (newSummary.isEmpty) {
            messages.add({
              "isMe": false,
              "text": "ยังไม่สามารถสร้างสรุปได้ ลองอีกครั้ง",
            });
          } else {
            messages.add({"isMe": false, "text": newSummary});
          }
        }

        if (newAiChatId > 0) {
          _activeAiChatId = newAiChatId;
          AISummaryNotificationService.updateVisibleAiChatId(_activeAiChatId);
        }

        if (newDocumentTitle.isNotEmpty) {
          _currentDocumentTitle = newDocumentTitle;
        }

        if (newPostTitle.isNotEmpty) {
          _currentPostTitle = newPostTitle;
        }
      });

      if (shouldLoadHistory) {
        _shouldAnimateInitialHistory = true;
        await _loadMessages(fallbackSummary: newSummary);
      } else {
        await _loadExistingQuiz();
        _scrollToBottom();
      }

      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSummaryGenerating = false;
        messages.removeWhere(
          (msg) => msg["type"] == "loading" && msg["loadingKind"] == "summary",
        );
        messages.add({
          "isMe": false,
          "text": "เกิดข้อผิดพลาดในการสรุป ลองอีกครั้ง",
        });
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isAiResponding) return;

    setState(() {
      _isAiResponding = true;
      messages.add({"isMe": true, "text": text});
      messages.add({
        "isMe": false,
        "type": "loading",
        "loadingKind": "chat",
        "text": "AI กำลังค้นหาคำตอบ...",
      });
    });

    _textController.clear();
    _scrollToBottom();

    try {
      final repo = AIChatRepository();

      final res = await repo.sendMessage(
        aiChatId: _activeAiChatId,
        question: text,
        postContentId: widget.postContentId,
      );

      dynamic answer;

      if (res["data"] is String) {
        answer = res["data"];
      } else if (res["data"] is Map) {
        final data = Map<String, dynamic>.from(res["data"]);
        answer = data["result"];
      } else if (res["result"] != null) {
        answer = res["result"];
      }

      if (answer == null || answer.toString().trim().isEmpty) {
        throw Exception("No AI answer");
      }

      final responseAiChatId = _extractAiChatId(Map<String, dynamic>.from(res));
      if (responseAiChatId > 0 && responseAiChatId != _activeAiChatId) {
        _activeAiChatId = responseAiChatId;
        AISummaryNotificationService.updateVisibleAiChatId(_activeAiChatId);
      }

      final answerText = answer.toString().trim();

      if (!mounted) {
        AISummaryNotificationService.savePendingReply(
          _activeAiChatId,
          text,
          answerText,
        );
      }

      AISummaryNotificationService.notifyAiReply(
        aiChatId: _activeAiChatId,
        documentTitle: _appBarTitle,
        postTitle: _postCardTitle,
        summary: widget.summary,
        content: widget.content,
        attachments: List<Map<String, dynamic>>.from(widget.attachments),
        postContentId: widget.postContentId,
        question: text,
      );

      if (!mounted) return;

      setState(() {
        _isAiResponding = false;
        messages.removeWhere(
          (msg) => msg["type"] == "loading" && msg["loadingKind"] == "chat",
        );
        messages.add({"isMe": false, "text": answerText});
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isAiResponding = false;
        messages.removeWhere(
          (msg) => msg["type"] == "loading" && msg["loadingKind"] == "chat",
        );
        messages.add({"isMe": false, "text": "เกิดข้อผิดพลาด"});
      });
    }
  }

  Future<void> _generateQuizWithConfig({
    required String difficulty,
    required int questionCount,
    required String mode,
    bool addUserMessage = true,
  }) async {
    if (_isQuizGenerating || _activeAiChatId <= 0) return;

    setState(() {
      _isQuizGenerating = true;

      if (addUserMessage) {
        messages.add({
          "isMe": true,
          "text": mode == "learning" ? "สร้างแบบการเรียนรู้" : "สร้างแบบทดสอบ",
        });
      }

      messages.add({
        "isMe": false,
        "type": "loading",
        "loadingKind": "quiz",
        "text": mode == "learning"
            ? "กำลังสร้างแบบการเรียนรู้..."
            : "กำลังสร้างแบบทดสอบ...",
      });
    });
    _scrollToBottom();

    try {
      final repo = AIChatRepository();
      final quiz = await repo.generateQuiz(
        aiChatId: _activeAiChatId,
        difficulty: difficulty,
        questionCount: questionCount,
        mode: mode,
      );

      if (_activeAiChatId > 0) {
        AISummaryNotificationService.notifyQuizGenerated(
          aiChatId: _activeAiChatId,
          documentTitle: _appBarTitle,
          postTitle: _postCardTitle,
          summary: widget.summary,
          content: widget.content,
          attachments: List<Map<String, dynamic>>.from(widget.attachments),
          postContentId: widget.postContentId,
          mode: mode,
        );
      }

      if (!mounted) return;

      setState(() {
        _isQuizGenerating = false;

        messages.removeWhere(
          (msg) => msg["type"] == "loading" && msg["loadingKind"] == "quiz",
        );

        final quizId = _extractQuizId(quiz);
        if (quizId > 0) {
          _loadedQuizIds.add(quizId);
        }

        messages.add({"isMe": false, "type": "quiz", "quiz": quiz});
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;

      final repo = AIChatRepository();
      final existing = await repo.getQuiz(_activeAiChatId);

      Map<String, dynamic>? recoveredQuiz;
      for (final quiz in existing) {
        final quizMap = Map<String, dynamic>.from(quiz);
        final quizId = _extractQuizId(quizMap);
        if (quizId > 0 && !_loadedQuizIds.contains(quizId)) {
          recoveredQuiz = quizMap;
          _loadedQuizIds.add(quizId);
          break;
        }
      }

      setState(() {
        _isQuizGenerating = false;

        messages.removeWhere(
          (msg) => msg["type"] == "loading" && msg["loadingKind"] == "quiz",
        );

        if (recoveredQuiz != null) {
          messages.add({"isMe": false, "type": "quiz", "quiz": recoveredQuiz});
        } else {
          messages.add({
            "isMe": false,
            "text": "เกิดข้อผิดพลาดในการสร้างแบบฝึกหัด",
          });
        }
      });
      _scrollToBottom();
    }
  }

  Future<void> _openQuizCollection({Map<String, dynamic>? autoOpenQuiz}) async {
    if (_activeAiChatId <= 0) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIQuizCollectionPage(
          aiChatId: _activeAiChatId,
          initialQuiz: autoOpenQuiz,
        ),
      ),
    );

    if (!mounted || result is! Map<String, dynamic>) return;

    if (result["action"] == "generate") {
      final difficulty = (result["difficulty"] ?? "medium").toString();
      final mode = (result["mode"] ?? "exam").toString();
      final countRaw = result["questionCount"];
      final questionCount = countRaw is int
          ? countRaw
          : int.tryParse(countRaw?.toString() ?? "") ?? 5;

      await _generateQuizWithConfig(
        difficulty: difficulty,
        questionCount: questionCount,
        mode: mode,
        addUserMessage: true,
      );
    }
  }

  void _generateQuiz() {
    if (_isQuizGenerating || _activeAiChatId <= 0) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AIQuizPopup(
          onGenerate: (difficulty, questionCount, mode) async {
            Navigator.pop(context);
            await _generateQuizWithConfig(
              difficulty: difficulty,
              questionCount: questionCount,
              mode: mode,
              addUserMessage: true,
            );
          },
        );
      },
    );
  }

  Future<void> _loadExistingQuiz() async {
    if (_activeAiChatId <= 0) return;

    final repo = AIChatRepository();

    final quizzes = await repo.getQuiz(_activeAiChatId);

    if (quizzes.isEmpty) return;

    setState(() {
      for (final quiz in quizzes) {
        final quizMap = Map<String, dynamic>.from(quiz);
        final quizId = _extractQuizId(quizMap);

        if (quizId > 0 && _loadedQuizIds.contains(quizId)) {
          continue;
        }

        if (quizMap["questions"] != null) {
          if (quizId > 0) {
            _loadedQuizIds.add(quizId);
          }

          messages.add({
            "isMe": true,
            "text": quizMap['mode'] == 'learning'
                ? "สร้างแบบการเรียนรู้"
                : "สร้างแบบทดสอบ",
          });
          messages.add({"isMe": false, "type": "quiz", "quiz": quizMap});
        }
      }
    });
  }

  Widget _buildPostCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 80, right: 12, bottom: 18),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryPalette[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  " สวัสดี Link-Lian สรุปเนื้อหาเหล่านี้",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),

                /// INNER CARD
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPalette[300]!.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _postCardTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      if (widget.content.isNotEmpty)
                        Text(
                          widget.content,
                          style: const TextStyle(fontSize: 14),
                        ),

                      const SizedBox(height: 12),

                      if (widget.attachments.isNotEmpty)
                        ...widget.attachments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final file = entry.value;
                          final url = file["url"] ?? file["file_url"];
                          final type = file["type"] ?? file["file_type"];

                          final name =
                              file["original_name"] ??
                              file["file_name"] ??
                              file["name"] ??
                              url.split('/').last;

                          if (type == "link") {
                            return AILinkPreviewCard(url: url);
                          }

                          final attachment =
                              ChatAttachmentWidget.buildAttachment(context, {
                                "url": url,
                                "type": type,
                                "name": name,
                              });

                          final bool isLast =
                              index == widget.attachments.length - 1;

                          // Add white background for PDF files
                          if (type == "pdf" ||
                              url.toLowerCase().endsWith('.pdf')) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: attachment,
                              ),
                            );
                          }

                          return Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                            child: attachment,
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    if (message["type"] == "quiz") {
      return _buildQuizCard(Map<String, dynamic>.from(message["quiz"]));
    }
    if (message["type"] == "loading") {
      return _buildLoadingMessage(message);
    }
    final isMe = message["isMe"];
    final text = (message["text"] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildAiAvatar(),
            ),

          GestureDetector(
            onLongPress: text.trim().isEmpty
                ? null
                : () => _showMessageCopyMenu(text),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryPalette[100] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? AppColors.black : const Color(0xFF1A1A1A),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageCopyMenu(String text) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListTile(
            leading: Icon(Icons.copy, color: AppColors.primaryPalette[600]),
            title: const Text('คัดลอกข้อความ'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
              DialogHelper.showNotification(
                title: 'คัดลอกแล้ว',
                message: 'คัดลอกข้อความเรียบร้อยแล้ว',
                type: NotificationType.success,
                compact: true,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMessage(Map<String, dynamic> message) {
    final loadingKind = message["loadingKind"]?.toString() ?? "";
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: loadingKind == "chat"
                ? SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primaryPalette[500],
                          ),
                        ),
                        _buildAiAvatar(size: 28),
                      ],
                    ),
                  )
                : _buildAiAvatar(),
          ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryPalette[500],
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message["text"] ?? "กำลังประมวลผล...",
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    final storeKey = _storeKeyForQuiz(quiz);
    final isCompleted = QuizAttemptStore.getResult(storeKey) != null;
    final questions = List.from(quiz["questions"] ?? []);

    final rawDifficulty =
        quiz['difficulty']?.toString().toLowerCase() ?? 'medium';
    final String difficultyLabel;
    final Color difficultyColor;
    final Color difficultyBg;
    switch (rawDifficulty) {
      case 'easy':
        difficultyLabel = 'ง่าย';
        difficultyColor = AppColors.successPalette[800]!;
        difficultyBg = AppColors.successPalette[100]!;
        break;
      case 'hard':
        difficultyLabel = 'ยาก';
        difficultyColor = AppColors.dangerPalette[500]!;
        difficultyBg = AppColors.dangerPalette[100]!;
        break;
      default:
        difficultyLabel = 'ปานกลาง';
        difficultyColor = AppColors.warningPalette[700]!;
        difficultyBg = AppColors.warningPalette[100]!;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAiAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Text(
                        'สร้างแบบฝึกหัดเสร็จแล้ว!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPalette[100]!.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryPalette[100]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                TablerIcons.file_text_spark,
                                size: 20,
                                color: AppColors.primaryPalette[700],
                              ),
                              const SizedBox(width: 7),
                              Text(
                                quiz['mode'] == 'learning'
                                    ? 'แบบการเรียนรู้พร้อมแล้ว'
                                    : 'แบบทดสอบพร้อมแล้ว',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primaryPalette[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Wrap(
                          //   spacing: 8,
                          //   runSpacing: 8,
                          //   children: [
                          //     Container(
                          //       padding: const EdgeInsets.symmetric(
                          //         horizontal: 10,
                          //         vertical: 5,
                          //       ),
                          //       decoration: BoxDecoration(
                          //         color: Colors.blue.shade50,
                          //         borderRadius: BorderRadius.circular(20),
                          //       ),
                          //       child: Text(
                          //         quiz['mode'] == 'learning'
                          //             ? 'แบบการเรียนรู้'
                          //             : ' แบบทดสอบ',
                          //         style: TextStyle(
                          //           fontSize: 12,
                          //           fontWeight: FontWeight.w600,
                          //           color: Colors.blue.shade700,
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          // const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: difficultyBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  difficultyLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: difficultyColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPalette[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 4),
                                    Text(
                                      '${questions.length} คำถาม',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryPalette[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonPalette[100],
                                foregroundColor: AppColors.buttonPalette[700],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                elevation: 0,
                                side: BorderSide(
                                  color: AppColors.buttonPalette[300]!,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _openQuizDirect(quiz),
                              child: Text(
                                isCompleted
                                    ? 'เปิดชุดคำถาม'
                                    : (quiz['mode'] == 'learning'
                                          ? 'เริ่มแบบการเรียนรู้'
                                          : 'เริ่มทำแบบทดสอบ'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _appBarTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            if (_appBarSubtitle.isNotEmpty)
              Text(
                _appBarSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAiBook,
                  size: 26,
                  color: AppColors.primaryPalette[500],
                ),
              ],
            ),
            onPressed: _activeAiChatId > 0 ? _openQuizCollection : null,
            tooltip: "รวมแบบทดสอบ",
          ),
        ],
      ),

      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      children: [
                        _buildPostCard(),
                        const SizedBox(height: 10),
                        //...messages.map((msg) => _buildMessage(msg)).toList(),
                        ...messages.map((msg) => _buildMessage(msg)),
                      ],
                    ),
                    if (_showScrollToLatestButton)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Material(
                          elevation: 4,
                          color: AppColors.primaryPalette[500],
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _scrollToBottom,
                            child: const Padding(
                              padding: EdgeInsets.all(9),
                              child: Icon(
                                Icons.arrow_downward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // 1-frame transparent cover prevents visible scroll-from-top flash
                    if (_isHistoryLoading)
                      const Positioned.fill(
                        child: ColoredBox(color: Color(0xFFF8F9FA)),
                      ),
                  ],
                ),
              ),
              AIChatInputBarWidget(
                textController: _textController,
                hasText: hasText,
                isAiResponding: _isAiResponding,
                canGenerateQuiz: _activeAiChatId > 0 && !_isQuizGenerating,
                onGenerateQuiz: _generateQuiz,
                onSendMessage: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadMessages({String? fallbackSummary}) async {
    if (_activeAiChatId <= 0) {
      if (_isHistoryLoading && mounted) {
        setState(() {
          _isHistoryLoading = false;
        });
      }
      return;
    }

    final repo = AIChatRepository();

    try {
      final responses = await Future.wait([
        repo.getMessages(_activeAiChatId),
        repo.getQuiz(_activeAiChatId),
      ]);

      // final result = List<Map<String, dynamic>>.from(
      //   responses[0] as List<Map<String, dynamic>>,
      // );
      // final quizzes = List<Map<String, dynamic>>.from(
      //   responses[1] as List<Map<String, dynamic>>,
      // );
      final result = List<Map<String, dynamic>>.from(responses[0]);

      final quizzes = List<Map<String, dynamic>>.from(responses[1]);

      if (!mounted) return;

      final effectiveSummary =
          (fallbackSummary != null && fallbackSummary.isNotEmpty)
          ? fallbackSummary
          : widget.summary.trim();

      setState(() {
        messages.clear();
        _loadedQuizIds.clear();

        final firstMsgIsAi =
            result.isNotEmpty && result.first['role'] != 'user';
        if (!firstMsgIsAi && effectiveSummary.isNotEmpty) {
          messages.add({"isMe": false, "text": effectiveSummary});
        }

        for (final quiz in quizzes) {
          final quizMap = Map<String, dynamic>.from(quiz);
          final quizId = _extractQuizId(quizMap);

          if (quizMap["questions"] == null) {
            continue;
          }

          if (quizId > 0) {
            _loadedQuizIds.add(quizId);
          }

          messages.add({
            "isMe": true,
            "text": quizMap['mode'] == 'learning'
                ? "สร้างแบบการเรียนรู้"
                : "สร้างแบบทดสอบ",
          });
          messages.add({"isMe": false, "type": "quiz", "quiz": quizMap});
        }

        for (final msg in result) {
          messages.add({
            "isMe": msg["role"] == "user",
            "text": msg["content"] ?? "",
          });
        }

        final pending = AISummaryNotificationService.consumePendingReply(
          _activeAiChatId,
        );
        if (pending != null) {
          final pendingQ = pending['question']!;
          final alreadyInHistory = result.any(
            (msg) =>
                msg['role'] == 'user' && (msg['content'] ?? '') == pendingQ,
          );
          if (!alreadyInHistory) {
            messages.add({"isMe": true, "text": pendingQ});
            messages.add({"isMe": false, "text": pending['answer']!});
          }
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          final max = _scrollController.position.maxScrollExtent;
          if (_shouldAnimateInitialHistory) {
            _shouldAnimateInitialHistory = false;
            if (max > 0) {
              await _scrollController.animateTo(
                max,
                duration: const Duration(milliseconds: 620),
                curve: Curves.easeOut,
              );
              if (mounted && _scrollController.hasClients) {
                _scrollController.jumpTo(
                  _scrollController.position.maxScrollExtent,
                );
              }
            }
          } else {
            _scrollController.jumpTo(max);
          }
        }
        _releaseScrollButtonSuppression();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    AISummaryNotificationService.setAIChatDetailVisible(false);
    _scrollController.removeListener(_onScrollChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
