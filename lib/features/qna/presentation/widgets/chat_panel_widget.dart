import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/features/qna/data/models/qa_question_model.dart';
import 'package:LinkLian/features/qna/presentation/controllers/live_controller.dart';
import 'package:LinkLian/features/qna/presentation/widgets/anonymous_toggle_widget.dart';
import 'package:LinkLian/features/qna/presentation/widgets/question_item_widget.dart';
import 'package:LinkLian/features/qna/presentation/widgets/send_question_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatPanelWidget extends StatefulWidget {
  final LiveController controller;
  final TextEditingController textController;
  final ScrollController scrollController;
  final bool inlineMode;
  final bool readOnly;
  final bool draggable;
  final bool blockInput;
  final Function(double, double)? onHeaderDragUpdate;
  final VoidCallback? onHeaderDragEnd;
  final VoidCallback? onClose;
  final Function(int?)? onReply;

  const ChatPanelWidget({
    super.key,
    required this.controller,
    required this.textController,
    required this.scrollController,
    this.inlineMode = false,
    this.readOnly = false,
    this.draggable = true,
    this.blockInput = false,
    this.onHeaderDragUpdate,
    this.onHeaderDragEnd,
    this.onClose,
    this.onReply,
  });

  @override
  State<ChatPanelWidget> createState() => _ChatPanelWidgetState();
}

class _ChatPanelWidgetState extends State<ChatPanelWidget> {
  final Set<String> _optimisticUpvotedQuestionKeys = <String>{};

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  bool _isQuestionUpvoted(dynamic questionId, dynamic question) {
    final key = _questionUpvoteKey(questionId, question);
    if (key != null && _optimisticUpvotedQuestionKeys.contains(key)) {
      return true;
    }

    if (widget.controller.isPersistedUpvotedQuestion(questionId)) {
      return true;
    }

    return _isTruthy(question['is_upvoted']) ||
        _isTruthy(question['has_upvoted']) ||
        _isTruthy(question['voted_by_me']) ||
        _isTruthy(question['user_has_upvoted']);
  }

  String? _questionUpvoteKey(dynamic questionId, dynamic question) {
    final id = _toInt(questionId);
    if (id != null) {
      return id.toString();
    }

    final fallbackId = _toInt(question['qa_question_id']);
    return fallbackId?.toString();
  }

  Future<void> _handleQuestionUpvote(dynamic question) async {
    final questionId = _toInt(question['qa_question_id']);
    final questionKey = _questionUpvoteKey(questionId, question);
    if (questionId == null) {
      return;
    }

    if (_isQuestionUpvoted(questionId, question)) {
      return;
    }

    final previousCount = _toInt(question['upvote_count']) ?? 0;
    final previousUpvoted =
        _isTruthy(question['is_upvoted']) ||
        _isTruthy(question['has_upvoted']) ||
        _isTruthy(question['voted_by_me']) ||
        _isTruthy(question['user_has_upvoted']);

    if (mounted) {
      setState(() {
        if (questionKey != null) {
          _optimisticUpvotedQuestionKeys.add(questionKey);
        }
      });
    }

    // Handle both Map and QaQuestion
    if (question is QaQuestion) {
      final updatedQuestion = question.copyWith(
        isUpvoted: true,
        upvoteCount: previousCount + 1,
      );
      final questionIndex = widget.controller.questions.indexWhere(
        (q) => q.qaQuestionId == question.qaQuestionId,
      );
      if (questionIndex >= 0) {
        widget.controller.questions[questionIndex] = updatedQuestion;
        widget.controller.questions.refresh();
      }
    } else {
      question['is_upvoted'] = true;
      question['upvote_count'] = previousCount + 1;
      widget.controller.questions.refresh();
    }

    final success = await widget.controller.upvote(questionId);
    if (success) {
      return;
    }

    if (questionKey != null) {
      _optimisticUpvotedQuestionKeys.remove(questionKey);
    }

    // Revert changes
    if (question is QaQuestion) {
      final revertedQuestion = question.copyWith(
        isUpvoted: previousUpvoted,
        upvoteCount: previousCount,
      );
      final questionIndex = widget.controller.questions.indexWhere(
        (q) => q.qaQuestionId == question.qaQuestionId,
      );
      if (questionIndex >= 0) {
        widget.controller.questions[questionIndex] = revertedQuestion;
        widget.controller.questions.refresh();
      }
    } else {
      question['is_upvoted'] = previousUpvoted;
      question['upvote_count'] = previousCount;
      widget.controller.questions.refresh();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โหวตไม่สำเร็จ กรุณาลองใหม่')),
      );
    }
  }

  Future<void> _submitQuestion() async {
    final text = widget.textController.text.trim();
    if (text.isEmpty || widget.controller.isSendingQuestion.value) return;

    final sent = await widget.controller.sendQuestion(text);
    if (sent) {
      widget.textController.clear();
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งคำถามไม่สำเร็จ กรุณาลองใหม่')),
      );
    }
  }

  int _getFilteredQuestionsCount(dynamic source) {
    var items = <dynamic>[];

    // Handle both RxList<QaQuestion> and List<QaQuestion>
    if (source is RxList) {
      items = List.from(source);
    } else if (source is List) {
      items = List.from(source);
    } else {
      return 0;
    }

    if (items.isEmpty) return 0;

    // Filter by selected attachment (file)
    final selectedAttachment = widget.controller.selectedAttachment.value;
    final selectedAttachmentId = selectedAttachment != null
        ? _toInt(selectedAttachment['attachment_id'])
        : null;

    if (selectedAttachmentId != null) {
      items = items.where((q) {
        final attachmentId = q is Map
            ? (_toInt(q['attachment_id']) ?? -1)
            : (q.attachmentId ?? -1);
        return attachmentId == selectedAttachmentId;
      }).toList();
    }

    return items.length;
  }

  List<dynamic> _buildFilteredQuestions(dynamic source) {
    var items = <dynamic>[];

    // Handle both RxList<QaQuestion> and List<QaQuestion>
    if (source is RxList) {
      items = List.from(source);
    } else if (source is List) {
      items = List.from(source);
    } else {
      return [];
    }

    if (items.isEmpty) return [];

    // Filter by selected attachment (file)
    final selectedAttachment = widget.controller.selectedAttachment.value;
    final selectedAttachmentId = selectedAttachment != null
        ? _toInt(selectedAttachment['attachment_id'])
        : null;

    if (selectedAttachmentId != null) {
      items = items.where((q) {
        final attachmentId = q is Map
            ? (_toInt(q['attachment_id']) ?? -1)
            : (q.attachmentId ?? -1);
        return attachmentId == selectedAttachmentId;
      }).toList();
    }

    if (items.isEmpty) return [];

    // Sort by topVoted: โหวตเยอะสุดขึ้นบน, ถ้าโหวตเท่ากันให้เรียงตามเวลาส่ง
    items.sort((a, b) {
      final aVote = a is Map ? (_toInt(a['upvote_count']) ?? 0) : a.upvoteCount;
      final bVote = b is Map ? (_toInt(b['upvote_count']) ?? 0) : b.upvoteCount;

      // เอกสารระหว่าง vote count
      if (aVote != bVote) {
        return bVote.compareTo(aVote); // โหวตมากขึ้นบน
      }

      // ถ้าโหวตเท่ากัน เรียงตามเวลาส่ง (ส่งก่อนขึ้นบน)
      final aTime = a is Map
          ? (DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0))
          : a.createdAt;
      final bTime = b is Map
          ? (DateTime.tryParse(b['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0))
          : b.createdAt;
      return bTime.compareTo(aTime); // ส่งหลังขึ้นบน (จากหลังไปหน้า)
    });

    return items;
  }

  bool _isTruthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      elevation: 12,
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryPalette[100],
            borderRadius: widget.inlineMode
                ? BorderRadius.zero
                : const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Header - drag to resize popup
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: widget.draggable
                    ? (details) {
                        final delta = details.primaryDelta ?? 0;
                        widget.onHeaderDragUpdate?.call(delta, screenHeight);
                      }
                    : null,
                onVerticalDragEnd: widget.draggable
                    ? (_) => widget.onHeaderDragEnd?.call()
                    : null,
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      if (widget.draggable)
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 6),
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPalette[300],
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.question_answer_outlined,
                              size: 18,
                              color: AppColors.primaryPalette[700],
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'คำถามและความคิดเห็น',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Obx(() {
                              final count = _getFilteredQuestionsCount(
                                widget.controller.questions,
                              );
                              if (count == 0) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPalette[200],
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.primaryPalette[800],
                                  ),
                                ),
                              );
                            }),
                            const Spacer(),
                            if (!widget.readOnly)
                              IconButton(
                                onPressed: () {
                                  widget.controller.isChatOpen.value = false;
                                  widget.onClose?.call();
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: AppColors.primaryPalette[700],
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ),
              // Questions List
              Expanded(
                child: AbsorbPointer(
                  absorbing: widget.blockInput,
                  child: Obx(() {
                    final displayedQuestions = _buildFilteredQuestions(
                      widget.controller.questions,
                    );

                    if (displayedQuestions.isEmpty) {
                      return Center(
                        child: widget.readOnly
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: AppColors.primaryPalette[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'ไม่มีคำถามและความคิดเห็นในไฟล์นี้',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.primaryPalette[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      );
                    }

                    return Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
                        itemCount: displayedQuestions.length,
                        itemBuilder: (_, i) {
                          final q = displayedQuestions[i];
                          final questionId = q['qa_question_id'];
                          final isLocalPending = q['is_local_pending'] == true;
                          final upvoteCount = _toInt(q['upvote_count']) ?? 0;
                          final isUpvoted = _isQuestionUpvoted(questionId, q);

                          return QuestionItemWidget(
                            question: q,
                            isUpvoted: isUpvoted,
                            upvoteCount: upvoteCount,
                            isLocalPending: isLocalPending,
                            readOnly: widget.readOnly,
                            onUpvote: () => _handleQuestionUpvote(q),
                            onReply: widget.onReply,
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),
              // Input Section
              if (!widget.readOnly)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                  color: AppColors.primaryPalette[100],
                  child: Obx(
                    () => Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(width: 8),
                        AnonymousToggleWidget(
                          value: widget.controller.isAnonymous.value,
                          onChanged: (v) =>
                              widget.controller.isAnonymous.value = v,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: widget.textController,
                              enabled:
                                  !widget.controller.isSendingQuestion.value,
                              onSubmitted: (_) => _submitQuestion(),
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              decoration: InputDecoration(
                                hintText: widget.controller.isAnonymous.value
                                    ? 'ถามแบบไม่ระบุตัวตน...'
                                    : 'ถามแบบระบุตัวตน... ',
                                hintStyle: TextStyle(
                                  color: AppColors.primaryPalette[400],
                                  fontSize: 14,
                                ),
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SendQuestionButtonWidget(
                          textController: widget.textController,
                          isLoading: widget.controller.isSendingQuestion.value,
                          onPressed: _submitQuestion,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
