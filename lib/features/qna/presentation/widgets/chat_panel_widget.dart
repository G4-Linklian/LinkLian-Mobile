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
  bool _showAllLogQuestions = false;

  bool get _isHistoryMode => widget.controller.isHistoryMode.value;

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

  String _sanitizeLabel(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null' || text == '-') {
      return '';
    }
    return text;
  }

  String _resolveFileLabel(Map<String, dynamic> file) {
    final attachmentId = _toInt(file['attachment_id']);

    final directName = _sanitizeLabel(file['original_name']);
    if (directName.isNotEmpty) {
      return attachmentId != null ? '$directName (#$attachmentId)' : directName;
    }

    final nestedAttachment = file['attachment'];
    if (nestedAttachment is Map) {
      final attachmentMap = Map<String, dynamic>.from(nestedAttachment);
      final nestedName = _sanitizeLabel(attachmentMap['original_name']);
      if (nestedName.isNotEmpty) {
        return attachmentId != null
            ? '$nestedName (#$attachmentId)'
            : nestedName;
      }

      final nestedFileName = _sanitizeLabel(attachmentMap['file_name']);
      if (nestedFileName.isNotEmpty) {
        return attachmentId != null
            ? '$nestedFileName (#$attachmentId)'
            : nestedFileName;
      }
    }

    final fileName = _sanitizeLabel(file['file_name']);
    if (fileName.isNotEmpty) {
      return attachmentId != null ? '$fileName (#$attachmentId)' : fileName;
    }

    return attachmentId != null ? 'ไฟล์ (#$attachmentId)' : 'ไฟล์';
  }

  Map<String, dynamic> _buildEffectiveAttachment(
    int attachmentId,
    Map<String, dynamic> liveFile,
    Map<String, dynamic> sourceFile,
  ) {
    final combined = <String, dynamic>{
      ...sourceFile,
      ...liveFile,
      'attachment_id': attachmentId,
    };

    if (combined['post_id'] == null && sourceFile['post_id'] != null) {
      combined['post_id'] = sourceFile['post_id'];
    }
    if ((combined['file_url'] == null ||
            combined['file_url'].toString().trim().isEmpty) &&
        sourceFile['file_url'] != null) {
      combined['file_url'] = sourceFile['file_url'];
    }
    if ((combined['file_type'] == null ||
            combined['file_type'].toString().trim().isEmpty) &&
        sourceFile['file_type'] != null) {
      combined['file_type'] = sourceFile['file_type'];
    }
    if ((combined['original_name'] == null ||
            combined['original_name'].toString().trim().isEmpty) &&
        sourceFile['original_name'] != null) {
      combined['original_name'] = sourceFile['original_name'];
    }

    return combined;
  }

  List<Map<String, dynamic>> _buildSelectableAttachments() {
    final selectorById = <int, Map<String, dynamic>>{};

    for (final raw in widget.controller.liveLogFiles) {
      final logItem = Map<String, dynamic>.from(raw as Map);
      final id = _toInt(logItem['attachment_id']);
      if (id == null) continue;

      final nestedAttachment = logItem['attachment'];
      final fromLog = <String, dynamic>{'attachment_id': id};
      if (nestedAttachment is Map) {
        fromLog.addAll(Map<String, dynamic>.from(nestedAttachment));
      }
      if (fromLog['post_id'] == null && logItem['post_id'] != null) {
        fromLog['post_id'] = logItem['post_id'];
      }
      if (fromLog['file_url'] == null && logItem['file_url'] != null) {
        fromLog['file_url'] = logItem['file_url'];
      }
      if (fromLog['file_type'] == null && logItem['file_type'] != null) {
        fromLog['file_type'] = logItem['file_type'];
      }
      if (fromLog['original_name'] == null &&
          logItem['original_name'] != null) {
        fromLog['original_name'] = logItem['original_name'];
      }

      final existing = selectorById[id] ?? <String, dynamic>{};
      selectorById[id] = _buildEffectiveAttachment(id, existing, fromLog);
    }

    final entries = <Map<String, dynamic>>[];
    for (final entry in selectorById.entries) {
      final attachment = Map<String, dynamic>.from(entry.value);
      entries.add({'id': entry.key, 'attachment': attachment});
    }

    entries.sort((a, b) {
      final aLabel = _resolveFileLabel(
        Map<String, dynamic>.from(a['attachment'] as Map),
      );
      final bLabel = _resolveFileLabel(
        Map<String, dynamic>.from(b['attachment'] as Map),
      );
      return aLabel.toLowerCase().compareTo(bLabel.toLowerCase());
    });

    return entries;
  }

  List<dynamic> _filterQuestionsBySelectedLogAttachment(List<dynamic> items) {
    if (_showAllLogQuestions) {
      return items;
    }

    final selectedAttachmentId = _toInt(
      widget.controller.selectedAttachment.value?['attachment_id'],
    );
    if (selectedAttachmentId == null) {
      return items;
    }

    return items.where((question) {
      final attachmentId = question is Map
          ? _toInt(question['attachment_id'])
          : _toInt(question.attachmentId);
      return attachmentId == selectedAttachmentId;
    }).toList();
  }

  Future<void> _openFileFilterMenu(BuildContext context) async {
    final entries = _buildSelectableAttachments();
    final buttonBox = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (buttonBox == null || overlayBox == null) return;

    final buttonTopLeft = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final buttonRect = Rect.fromLTWH(
      buttonTopLeft.dx,
      buttonTopLeft.dy,
      buttonBox.size.width,
      buttonBox.size.height,
    );
    final overlayRect = Offset.zero & overlayBox.size;
    final buttonWidth = buttonRect.width;
    final menuWidth = buttonWidth.clamp(0.0, 360.0);

    final value = await showMenu<Object?>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(buttonRect.left, buttonRect.bottom + 8, menuWidth, 0),
        overlayRect,
      ),
      constraints: BoxConstraints.tightFor(width: menuWidth),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<Object?>(
          value: 'all',
          child: Row(
            children: [
              Icon(
                Icons.select_all,
                size: 18,
                color: AppColors.primaryPalette[600],
              ),
              const SizedBox(width: 8),
              Text(
                'ทั้งหมด',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: _showAllLogQuestions
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (entries.isNotEmpty) const PopupMenuDivider(height: 1),
        ...entries.map(
          (entry) => PopupMenuItem<Object?>(
            value: entry['id'],
            child: Text(
              _resolveFileLabel(
                Map<String, dynamic>.from(entry['attachment'] as Map),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    entry['id'] ==
                        _toInt(
                          widget
                              .controller
                              .selectedAttachment
                              .value?['attachment_id'],
                        )
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );

    if (value == null) return;

    if (value == 'all') {
      if (!mounted) return;
      setState(() {
        _showAllLogQuestions = true;
      });
      return;
    }

    final pickedId = _toInt(value);
    if (pickedId == null) return;

    final pickedEntry = entries.firstWhere(
      (entry) => entry['id'] == pickedId,
      orElse: () => entries.first,
    );

    if (!mounted) return;
    setState(() {
      _showAllLogQuestions = false;
    });

    await widget.controller.selectPresentationFile(
      Map<String, dynamic>.from(pickedEntry['attachment'] as Map),
    );
  }

  String _selectedFileLabel() {
    if (_showAllLogQuestions) {
      return 'ทั้งหมด';
    }

    final selected = widget.controller.selectedAttachment.value;
    if (selected != null) {
      return _resolveFileLabel(selected);
    }

    return 'ทั้งหมด';
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

    items = _filterQuestionsBySelectedLogAttachment(items);

    if (items.isEmpty) return [];

    items.sort((a, b) {
      final aVote = a is Map ? (_toInt(a['upvote_count']) ?? 0) : a.upvoteCount;
      final bVote = b is Map ? (_toInt(b['upvote_count']) ?? 0) : b.upvoteCount;

      if (aVote != bVote) {
        return bVote.compareTo(aVote);
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
      return bTime.compareTo(aTime);
    });

    return items;
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

    items = _filterQuestionsBySelectedLogAttachment(items);

    return items.length;
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

  int? _questionSlideNumber(dynamic question) {
    if (question is Map) {
      return _toInt(question['slide_number']);
    }
    try {
      return _toInt(question.slideNumber);
    } catch (_) {
      return null;
    }
  }

  int? _questionAttachmentId(dynamic question) {
    if (question is Map) {
      return _toInt(question['attachment_id']);
    }
    try {
      return _toInt(question.attachmentId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _waitForPdfReady({int maxAttempts = 25}) async {
    for (var i = 0; i < maxAttempts; i++) {
      if (widget.controller.pdfController.value != null) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<void> _handleQuestionReply(dynamic question) async {
    final slideNumber = _questionSlideNumber(question);
    if (slideNumber == null) {
      return;
    }

    final targetAttachmentId = _questionAttachmentId(question);
    final currentAttachmentId = _toInt(
      widget.controller.selectedAttachment.value?['attachment_id'],
    );

    if (targetAttachmentId != null &&
        targetAttachmentId != currentAttachmentId) {
      final resolved = widget.controller.resolveAttachmentById(
        targetAttachmentId,
      );
      if (resolved != null) {
        await widget.controller.selectPresentationFile(
          Map<String, dynamic>.from(resolved),
        );
        await _waitForPdfReady();
      }
    }

    widget.onReply?.call(slideNumber);
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
                        padding: const EdgeInsets.fromLTRB(12, 6, 0, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.question_answer_outlined,
                              size: 18,
                              color: AppColors.primaryPalette[700],
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'คำถาม',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (!_isHistoryMode)
                              Obx(() {
                                final count = _getFilteredQuestionsCount(
                                  widget.controller.questions,
                                );
                                final selectedLabel = _selectedFileLabel();

                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Builder(
                                      builder: (filterContext) =>
                                          GestureDetector(
                                            onTap: () => _openFileFilterMenu(
                                              filterContext,
                                            ),
                                            child: Container(
                                              height: 34,
                                              width: 150,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: AppColors
                                                      .primaryPalette[200]!,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.filter_alt_outlined,
                                                    size: 18,
                                                    color: AppColors
                                                        .primaryPalette[600],
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      selectedLabel,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .primaryPalette[800],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (count != 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryPalette[200],
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            color:
                                                AppColors.primaryPalette[800],
                                          ),
                                        ),
                                      ),
                                    if (!widget.readOnly) ...[
                                      IconButton(
                                        onPressed: () {
                                          widget.controller.isChatOpen.value =
                                              false;
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
                                  ],
                                );
                              }),
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
                            onReply: (_) => _handleQuestionReply(q),
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
