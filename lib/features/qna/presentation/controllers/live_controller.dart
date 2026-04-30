import 'dart:async';
import 'dart:io';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/core/services/api_client.dart';
import 'package:LinkLian/core/services/local_storage.dart';
import 'package:LinkLian/config/app_routes.dart';
import 'package:LinkLian/features/auth/controller/auth_controller.dart';
import 'package:LinkLian/features/profile/presentation/controllers/profile_controller.dart';
import 'package:LinkLian/features/shared/repositories/profile_repository.dart';
import 'package:LinkLian/features/shared/repositories/qna_repository.dart';
import 'package:LinkLian/features/qna/data/models/qa_question_model.dart';
import 'package:LinkLian/features/qna/data/models/qa_asker_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../../core/services/socket_service.dart';

class LiveController extends GetxController {
  final qaLiveId = Rxn<int>();
  final isHistoryMode = false.obs;

  final currentSlide = 0.obs;
  final questions = <QaQuestion>[].obs;
  final liveFiles = <Map<String, dynamic>>[].obs;
  final liveLogFiles = <Map<String, dynamic>>[].obs;
  final selectedAttachment = Rxn<Map<String, dynamic>>();
  final liveDetail = Rxn<Map<String, dynamic>>();

  final isFollowing = true.obs;
  final viewerCount = 0.obs;
  final isSendingQuestion = false.obs;
  final isChatOpen = false.obs;
  final isAnonymous = false.obs;

  final pdfController = Rxn<PDFViewController>();
  final totalPages = 0.obs;
  final currentPage = 0.obs;
  final pdfRebuildToken =
      0.obs; // Incremented when file changes to force UI rebuild
  bool _isFileChangingInProgress = false; // Flag to track file change state

  final SocketService _socket = SocketService();
  final QnaRepository _repo = QnaRepository();
  ProfileRepository? _profileRepo;

  StreamSubscription<dynamic>? _qaSubscription;
  // Timer? _questionsPollingTimer;
  // Timer? _liveStatusPollingTimer;
  final Map<int, QaAsker> _askerProfileCache = {};
  final Set<int> _loadingAskerIds = <int>{};
  final Set<int> _persistedUpvotedQuestionIds = <int>{};
  bool _hasLeftLiveSession = false;
  int? _pendingFollowPage;
  int? _lastPublishedSlideNumber;
  DateTime? _lastPublishedSlideAt;

  ProfileRepository get _profileRepoInstance =>
      _profileRepo ??= ProfileRepository(Get.find<ApiClient>());

  @override
  void onInit() {
    super.onInit();
    unawaited(enterLiveSessionFromArgs());
  }

  Future<void> enterLiveSessionFromArgs() async {
    final args = Get.arguments;
    final nextLiveId = _toInt(args?['qaLiveId']);
    final nextIsHistoryMode = args?['isHistoryMode'] == true;

    if (nextLiveId == null || nextLiveId <= 0) {
      appLog.warning(
        'qaLiveId is invalid',
        actionPage: 'LiveController.enterLiveSessionFromArgs',
        data: {'qaLiveId': nextLiveId},
      );
      return;
    }

    final hasLiveChanged = qaLiveId.value != nextLiveId;
    final hasModeChanged = isHistoryMode.value != nextIsHistoryMode;
    qaLiveId.value = nextLiveId;
    isHistoryMode.value = nextIsHistoryMode;

    // Reset transient UI/session state so opening Live always starts from slide view.
    isChatOpen.value = false;
    isSendingQuestion.value = false;

    if (hasLiveChanged || hasModeChanged) {
      questions.clear();
      selectedAttachment.value = null;
      liveDetail.value = null;
      currentSlide.value = 0;
      currentPage.value = 0;
      totalPages.value = 0;
    }

    await _loadPersistedUpvotedQuestions();

    await fetchLiveDetail();
    await fetchLiveFiles();
    await fetchLiveLogs();
    await fetchCurrentSlide();
    _ensureSelectedAttachmentHasUrl();
    await fetchQuestions();
    if (isHistoryMode.value) {
      await _qaSubscription?.cancel();
      _socket.disconnectQa();
      return;
    }

    appLog.debug(
      'About to call connectSocket',
      actionPage: 'LiveController.enterLiveSessionFromArgs',
      data: {
        'sectionId': liveDetail.value?['section_id'],
        'liveId': qaLiveId.value,
      },
    );
    await connectSocket();
  }

  Future<void> fetchLiveDetail() async {
    try {
      final res = await _repo.getLiveDetail(qaLiveId: qaLiveId.value!);
      liveDetail.value = res.toJson();

      final fromDetail = _extractQuestionItems(res.toJson());
      if (fromDetail.isNotEmpty) {
        final mapped = fromDetail
            .map((m) => _enrichQuestion(m))
            .map((m) => QaQuestion.fromJson(m))
            .toList();
        final merged = [...questions, ...mapped];
        questions.assignAll(_dedupeQaQuestions(merged));
        unawaited(_hydrateMissingAskers());
      }

      if (res.currentSlide is Map<String, dynamic>) {
        final attachment = res.currentSlide?['attachment'];
        if (attachment is Map<String, dynamic>) {
          final normalizedAttachment = _normalizeAttachmentShape(
            Map<String, dynamic>.from(attachment),
          );
          final currentPostId = res.currentSlide?['post_id'];
          if (normalizedAttachment['post_id'] == null &&
              currentPostId != null) {
            normalizedAttachment['post_id'] = currentPostId;
          }
          selectedAttachment.value = normalizedAttachment;
        }
      }

      if (liveFiles.isEmpty) {
        final fallbackFiles = _normalizeLiveFiles(_extractLiveFileItems(res));

        if (fallbackFiles.isNotEmpty) {
          liveFiles.assignAll(fallbackFiles);
          if (selectedAttachment.value == null) {
            selectedAttachment.value = fallbackFiles.first;
          }
        }
      }

      _ensureSelectedAttachmentHasUrl();
    } catch (e) {
      appLog.error(
        'Failed to fetch live detail',
        actionPage: 'LiveController.fetchLiveDetail',
        data: {'error': e.toString()},
      );
    }
  }

  Future<void> fetchLiveFiles() async {
    try {
      final sectionId =
          _toInt(Get.arguments?['sectionId']) ??
          _toInt(liveDetail.value?['section_id']);
      if (sectionId == null) {
        appLog.warning(
          'sectionId is null',
          actionPage: 'LiveController.fetchLiveFiles',
        );
        return;
      }

      final res = await _repo.getLiveFiles(sectionId: sectionId);
      final files = _normalizeLiveFiles(res);
      liveFiles.assignAll(files);

      if (selectedAttachment.value == null && files.isNotEmpty) {
        selectedAttachment.value = files.first;
      }

      _ensureSelectedAttachmentHasUrl();
    } catch (e) {
      appLog.error(
        'Failed to fetch live files',
        actionPage: 'LiveController.fetchLiveFiles',
        data: {'error': e.toString()},
      );
    }
  }

  Future<void> fetchLiveLogs() async {
    try {
      final liveId = qaLiveId.value;
      if (liveId == null) {
        liveLogFiles.clear();
        return;
      }

      final res = await _repo.getLiveLogs(qaLiveId: liveId);
      final logs = <Map<String, dynamic>>[];

      for (final item in res) {
        final parsed = Map<String, dynamic>.from(item);

        final attachment = parsed['post_attachment'];
        if (attachment is Map) {
          parsed['attachment'] = Map<String, dynamic>.from(attachment);
        }

        final postContent = parsed['post_content'];
        if (postContent is Map) {
          parsed['post_content'] = Map<String, dynamic>.from(postContent);
        }

        logs.add(parsed);
      }

      logs.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['opened_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            DateTime.tryParse(b['opened_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

      liveLogFiles.assignAll(_dedupeLiveLogs(logs));

      _syncSelectedAttachmentWithLiveLogs();
      _ensureSelectedAttachmentHasUrl();
    } catch (e) {
      appLog.error(
        'Failed to fetch live logs',
        actionPage: 'LiveController.fetchLiveLogs',
        data: {'error': e.toString()},
      );
      liveLogFiles.clear();
    }
  }

  Future<void> fetchCurrentSlide() async {
    try {
      final res = await _repo.getCurrentLog(qaLiveId: qaLiveId.value!);
      final attachmentId = res['attachment_id'];
      final slideNumber = _toInt(res['slide_number']);

      final file = _findFileByAttachmentId(attachmentId);
      if (file != null) {
        selectedAttachment.value = file;
      }

      if (slideNumber != null) {
        final pageIndex = slideNumber > 0 ? slideNumber - 1 : 0;
        currentSlide.value = slideNumber;
        currentPage.value = pageIndex;
        _pendingFollowPage = pageIndex;
        _applyPendingFollowPage();
      }

      _ensureSelectedAttachmentHasUrl();
    } catch (e) {
      appLog.error(
        'Failed to fetch current slide',
        actionPage: 'LiveController.fetchCurrentSlide',
        data: {'error': e.toString()},
      );
    }
  }

  Future<void> fetchQuestions() async {
    try {
      // Fetch from API - returns typed QaQuestion list
      final qaQuestions = await _repo.getLiveQuestions(
        qaLiveId: qaLiveId.value!,
      );

      // Extract from live detail (nested data)
      final fromDetail = _extractQuestionItems(liveDetail.value);
      final detailQuestions = fromDetail
          .map((item) => QaQuestion.fromJson(item))
          .toList();

      // Guard against transient empty responses that would hide existing items.
      if (qaQuestions.isEmpty &&
          detailQuestions.isEmpty &&
          questions.isNotEmpty) {
        return;
      }

      // Merge and deduplicate
      final merged = <QaQuestion>[
        ...questions,
        ...qaQuestions,
        ...detailQuestions,
      ];
      final deduped = _dedupeQaQuestions(merged);

      questions.assignAll(deduped);
      _applyPersistedUpvoteState();
      unawaited(_hydrateMissingAskers());

      appLog.debug(
        'Question sync completed',
        actionPage: 'LiveController.fetchQuestions',
        data: {
          'apiCount': qaQuestions.length,
          'detailCount': detailQuestions.length,
          'totalShown': questions.length,
          'qaLiveId': qaLiveId.value,
        },
      );
    } catch (e) {
      appLog.error(
        'Failed to fetch questions',
        actionPage: 'LiveController.fetchQuestions',
        data: {'error': e.toString()},
      );
    }
  }

  Future<void> connectSocket() async {
    if (isHistoryMode.value) {
      return;
    }

    try {
      appLog.debug(
        'Setting up QA socket',
        actionPage: 'LiveController.connectSocket',
      );
      if (!_socket.isQaConnected) {
        final qaSocketUrl =
            '${dotenv.env['SOCKET_URL'] ?? 'wss://uat-socket.linklian.org/ws'}/qa';
        appLog.debug(
          'Connecting to socket',
          actionPage: 'LiveController.connectSocket',
          data: {'url': qaSocketUrl},
        );
        await _socket.connectQaLive(qaSocketUrl);
        appLog.debug(
          'Socket connected successfully',
          actionPage: 'LiveController.connectSocket',
        );
      } else {
        appLog.debug(
          'Socket already connected',
          actionPage: 'LiveController.connectSocket',
        );
      }

      final auth = Get.find<AuthController>();
      final userId = auth.userId.value;
      final liveId = qaLiveId.value;
      final sectionId =
          _toInt(Get.arguments?['sectionId']) ??
          _toInt(liveDetail.value?['section_id']);

      appLog.debug(
        'Socket setup parameters',
        actionPage: 'LiveController.connectSocket',
        data: {'userId': userId, 'liveId': liveId, 'sectionId': sectionId},
      );

      if (userId == null || liveId == null) {
        appLog.warning(
          'userId or liveId is null, returning',
          actionPage: 'LiveController.connectSocket',
          data: {'userId': userId, 'liveId': liveId},
        );
        return;
      }

      if (sectionId != null) {
        appLog.debug(
          'Joining section room',
          actionPage: 'LiveController.connectSocket',
          data: {'sectionId': sectionId},
        );
        _socket.joinQaSectionRoom(userId: userId, sectionId: sectionId);
      } else {
        appLog.debug(
          'sectionId is null, skipping section room join',
          actionPage: 'LiveController.connectSocket',
        );
      }

      appLog.debug(
        'Joining QA live',
        actionPage: 'LiveController.connectSocket',
        data: {'liveId': liveId},
      );
      _socket.joinQaLive(userId: userId, qaLiveId: liveId);

      appLog.debug(
        'Setting up socket event listener',
        actionPage: 'LiveController.connectSocket',
      );
      await _qaSubscription?.cancel();

      // Listen to qaStream with error handling and auto-reconnect on stream close
      _qaSubscription = _socket.qaStream.listen(
        handleSocketEvent,
        onError: (e) {
          appLog.warning(
            'Socket stream error',
            actionPage: 'LiveController.connectSocket',
            data: {'error': e.toString()},
          );
          _scheduleSocketReconnect();
        },
        onDone: () {
          appLog.warning(
            'Socket stream closed unexpectedly',
            actionPage: 'LiveController.connectSocket',
          );
          _scheduleSocketReconnect();
        },
      );
      appLog.debug(
        'Socket listener setup complete',
        actionPage: 'LiveController.connectSocket',
      );
    } catch (e) {
      appLog.error(
        'Socket connection error',
        actionPage: 'LiveController.connectSocket',
        data: {'error': e.toString()},
      );
    }
  }

  Timer? _socketReconnectTimer;
  void _scheduleSocketReconnect() {
    _socketReconnectTimer?.cancel();
    appLog.debug(
      'Scheduling socket reconnect in 3 seconds',
      actionPage: 'LiveController._scheduleSocketReconnect',
    );
    _socketReconnectTimer = Timer(Duration(seconds: 3), () {
      if (!_hasLeftLiveSession && qaLiveId.value != null) {
        appLog.debug(
          'Executing auto-reconnect',
          actionPage: 'LiveController._scheduleSocketReconnect',
        );
        unawaited(connectSocket());
      }
    });
  }

  void handleSocketEvent(dynamic event) {
    final normalized = _normalizeSocketEvent(event);
    if (normalized == null) return;

    final type = normalized['type'];
    final payload = Map<String, dynamic>.from(normalized['payload'] ?? {});

    appLog.debug(
      'Socket event received',
      actionPage: 'LiveController.handleSocketEvent',
      data: {
        'type': type,
        'isFollowing': isFollowing.value,
        'hasPdf': pdfController.value != null,
      },
    );

    switch (type) {
      case 'VIEWER_COUNT_UPDATED':
        final count = _toInt(
          payload['count'] ??
              payload['viewer_count'] ??
              payload['viewerCount'] ??
              payload['members'] ??
              payload['total'],
        );
        if (count != null) {
          viewerCount.value = count;
        }
        break;

      case 'LIVE_CURRENT_STATE':
        final liveViewerCount = _toInt(
          payload['count'] ??
              payload['viewer_count'] ??
              payload['viewerCount'] ??
              payload['members'] ??
              payload['total'],
        );
        if (liveViewerCount != null) {
          viewerCount.value = liveViewerCount;
        }
        break;

      case 'FILE_CHANGED':
        if (!isFollowing.value) return;
        unawaited(_handleFileChanged(payload));
        break;

      case 'SLIDE_SYNC':
        if (!isFollowing.value) return;

        final slideNumber = _toInt(payload['slide_number']);
        if (slideNumber != null) {
          final pageIndex = slideNumber > 0 ? slideNumber - 1 : 0;
          appLog.debug(
            'SLIDE_SYNC received',
            actionPage: 'LiveController.handleSocketEvent',
            data: {
              'slide': slideNumber,
              'pageIndex': pageIndex,
              'hasPdf': pdfController.value != null,
              'isFileChanging': _isFileChangingInProgress,
            },
          );
          currentSlide.value = slideNumber;
          currentPage.value = pageIndex;
          _pendingFollowPage = pageIndex;

          // Try to apply immediately
          _applyPendingFollowPage();

          // If controller wasn't available, log the state for debugging
          if (pdfController.value == null) {
            appLog.debug(
              'SLIDE_SYNC - PDF controller not yet loaded',
              actionPage: 'LiveController.handleSocketEvent',
            );
          } else {
            appLog.debug(
              'SLIDE_SYNC - PDF controller available, page applied',
              actionPage: 'LiveController.handleSocketEvent',
            );
          }
        }
        break;

      case 'QA_NEW_QUESTION':
        final incoming = payload['question'];
        if (incoming is Map) {
          addQuestion(Map<String, dynamic>.from(incoming));
        } else {
          addQuestion(payload);
        }
        break;

      case 'NEW_QUESTION':
      case 'QUESTION_CREATED':
      case 'QA_QUESTION_CREATED':
        addQuestion(payload['question'] is Map ? payload['question'] : payload);
        break;

      case 'QA_UPVOTED':
        handleUpvote(payload);
        break;

      case 'QA_LIVE_ENDED':
        _exitLivePage();
        break;

      default:
        appLog.debug(
          'Unhandled socket event type',
          actionPage: 'LiveController.handleSocketEvent',
          data: {'type': type, 'payloadKeys': payload.keys.toList()},
        );
        if (_looksLikeQuestionPayload(payload)) {
          addQuestion(
            payload['question'] is Map ? payload['question'] : payload,
          );
        }
        if (_looksLikeQuestionPayload(payload)) {
          unawaited(fetchQuestions());
        }
    }
  }

  Future<void> _handleFileChanged(Map<String, dynamic> payload) async {
    try {
      _isFileChangingInProgress = true;
      final file = _findFileByAttachmentId(payload['attachment_id']);
      if (file != null) {
        // Reset PDF controller and state when file changes
        pdfController.value = null;
        totalPages.value = 0;
        _pendingFollowPage = null;
        pdfRebuildToken.value = (pdfRebuildToken.value + 1) % 1000000;

        appLog.debug(
          'FILE_CHANGED - Fetching current slide',
          actionPage: 'LiveController._handleFileChanged',
          data: {'attachmentId': file['attachment_id']},
        );

        _ensureSelectedAttachmentHasUrl();

        // IMPORTANT: Await fetchCurrentSlide BEFORE updating selectedAttachment
        // This ensures currentPage is set correctly before the rebuild is triggered
        await fetchCurrentSlide();

        appLog.debug(
          'FILE_CHANGED - After fetchCurrentSlide',
          actionPage: 'LiveController._handleFileChanged',
          data: {
            'currentPage': currentPage.value,
            'currentSlide': currentSlide.value,
          },
        );

        // Now safely update selectedAttachment to trigger UI rebuild
        // currentPage is already correctly set
        selectedAttachment.value = Map<String, dynamic>.from(file);

        appLog.debug(
          'FILE_CHANGED - Updated attachment',
          actionPage: 'LiveController._handleFileChanged',
          data: {
            'attachmentId': file['attachment_id'],
            'rebuildToken': pdfRebuildToken.value,
          },
        );
      }

      final changedAttachmentId = _toInt(payload['attachment_id']);
      if (changedAttachmentId != null) {
        final nextLog = <String, dynamic>{
          'qa_live_id': payload['qa_live_id'] ?? qaLiveId.value,
          'post_id': payload['post_id'],
          'attachment_id': changedAttachmentId,
          'opened_at': payload['opened_at'] ?? DateTime.now().toIso8601String(),
          if (file != null) 'attachment': Map<String, dynamic>.from(file),
        };

        final deduped = liveLogFiles
            .where((log) => _toInt(log['attachment_id']) != changedAttachmentId)
            .toList();
        deduped.add(nextLog);
        liveLogFiles.assignAll(_dedupeLiveLogs(deduped));
      }

      _isFileChangingInProgress = false;
    } catch (e) {
      appLog.error(
        'FILE_CHANGED error',
        actionPage: 'LiveController._handleFileChanged',
        data: {'error': e.toString()},
      );
      _isFileChangingInProgress = false;
    }
  }

  Map<String, dynamic>? _normalizeSocketEvent(dynamic rawEvent) {
    if (rawEvent is! Map) {
      return null;
    }

    final root = Map<String, dynamic>.from(rawEvent);

    if (root['type'] is String) {
      return {'type': root['type'], 'payload': _toMap(root['payload']) ?? root};
    }

    final data = _toMap(root['data']);
    if (data != null && data['type'] is String) {
      return {'type': data['type'], 'payload': _toMap(data['payload']) ?? data};
    }

    final payload = _toMap(root['payload']);
    if (payload != null && payload['type'] is String) {
      return {
        'type': payload['type'],
        'payload': _toMap(payload['payload']) ?? payload,
      };
    }

    if (_looksLikeQuestionPayload(root)) {
      return {'type': 'QA_NEW_QUESTION', 'payload': root};
    }

    if (data != null && _looksLikeQuestionPayload(data)) {
      return {'type': 'QA_NEW_QUESTION', 'payload': data};
    }

    if (payload != null && _looksLikeQuestionPayload(payload)) {
      return {'type': 'QA_NEW_QUESTION', 'payload': payload};
    }

    return null;
  }

  Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  List<QaQuestion> _dedupeQaQuestions(List<QaQuestion> items) {
    final result = <QaQuestion>[];
    final seenIds = <String, int>{};
    final seenIdentityKeys = <String, int>{};

    for (final q in items) {
      final id = q.qaQuestionId;
      final identityKey = _questionIdentityKeyForQa(q);
      final idKey = id?.toString();

      var existingIndex = identityKey != null
          ? seenIdentityKeys[identityKey]
          : null;
      existingIndex ??= idKey != null ? seenIds[idKey] : null;

      if (existingIndex != null) {
        final existing = result[existingIndex];
        final existingPending = existing.isLocalPending;
        final incomingPending = q.isLocalPending;

        if (existingPending && !incomingPending) {
          result[existingIndex] = q;
          if (idKey != null) {
            seenIds[idKey] = existingIndex;
          }
          if (identityKey != null) {
            seenIdentityKeys[identityKey] = existingIndex;
          }
        }
        continue;
      }

      final nextIndex = result.length;
      result.add(q);

      if (idKey != null) {
        seenIds[idKey] = nextIndex;
      }
      if (identityKey != null) {
        seenIdentityKeys[identityKey] = nextIndex;
      }
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  String? _questionIdentityKeyForQa(QaQuestion question) {
    final liveId = question.qaLiveId;
    final postId = question.postId;
    final attachmentId = question.attachmentId;
    final slideNumber = question.slideNumber;
    final text = _sanitizeText(question.question);
    final askerKey = _questionAskerKeyForQa(question);

    if (liveId == 0 ||
        postId == null ||
        attachmentId == null ||
        slideNumber == 0 ||
        askerKey == null ||
        text.isEmpty) {
      return null;
    }

    return '$liveId|$postId|$attachmentId|$slideNumber|$askerKey|$text|${question.isAnonymous ? 1 : 0}';
  }

  String? _questionAskerKeyForQa(QaQuestion question) {
    final askerId = question.askerId;
    if (askerId != null) {
      return 'id:$askerId';
    }

    final asker = question.asker;
    if (asker == null) {
      return null;
    }

    final firstName = _sanitizeText(asker.firstName);
    final lastName = _sanitizeText(asker.lastName);
    final profilePic = _sanitizeText(asker.profilePic);
    final fullName = [firstName, lastName].where((e) => e.isNotEmpty).join(' ');

    if (fullName.isEmpty && profilePic.isEmpty) {
      return null;
    }

    return 'asker:${fullName.isNotEmpty ? fullName.toLowerCase() : '-'}|${profilePic.toLowerCase()}';
  }

  void addQuestion(dynamic q) {
    // Support both Map and QaQuestion for backward compatibility with sockets
    late final QaQuestion question;

    if (q is QaQuestion) {
      question = q;
    } else if (q is Map<String, dynamic>) {
      question = QaQuestion.fromJson(q);
    } else {
      return;
    }

    final id = question.qaQuestionId;
    final matchingPendingIndex = _findMatchingPendingQuestionIndexForQa(
      question,
    );

    if (matchingPendingIndex != -1) {
      questions[matchingPendingIndex] = question;
      _applyPersistedUpvoteState();
      questions.refresh();
      unawaited(_hydrateMissingAskers());
      return;
    }

    // Ignore id-less socket questions to prevent duplicates with optimistic UI.
    if (id == null) {
      return;
    }

    final exists = questions.any((e) => e.qaQuestionId == id);
    if (!exists) {
      questions.insert(0, question);
      _applyPersistedUpvoteState();
      unawaited(_hydrateMissingAskers());
    }
  }

  int _findMatchingPendingQuestionIndexForQa(QaQuestion question) {
    final identityKey = _questionIdentityKeyForQa(question);
    if (identityKey == null) {
      return -1;
    }

    for (var index = 0; index < questions.length; index++) {
      final existing = questions[index];
      if (!existing.isLocalPending) {
        continue;
      }

      if (_questionIdentityKeyForQa(existing) == identityKey) {
        return index;
      }
    }

    return -1;
  }

  void handleUpvote(Map<String, dynamic> data) {
    final id = data['qa_question_id'];
    final index = questions.indexWhere(
      (q) => q.qaQuestionId == id || q.qaQuestionId.toString() == id.toString(),
    );

    if (index != -1) {
      final upvoteCount = _toInt(data['upvote_count']) ?? 0;
      final question = questions[index];
      questions[index] = question.copyWith(
        upvoteCount: upvoteCount,
        isUpvoted: _persistedUpvotedQuestionIds.contains(_toInt(id) ?? -1),
      );
      questions.refresh();
    }
  }

  bool isPersistedUpvotedQuestion(dynamic questionId) {
    final id = _toInt(questionId);
    if (id == null) return false;
    return _persistedUpvotedQuestionIds.contains(id);
  }

  Future<bool> upvote(int questionId) async {
    try {
      final auth = Get.find<AuthController>();
      final voterId = auth.userId.value;
      if (voterId == null) return false;

      await _repo.upvoteQuestion(questionId: questionId, voterId: voterId);
      await _persistUpvotedQuestion(questionId);
      return true;
    } catch (e) {
      appLog.error(
        'Failed to upvote question',
        actionPage: 'LiveController.upvote',
        data: {'questionId': questionId, 'error': e.toString()},
      );
      return false;
    }
  }

  Future<bool> sendQuestion(String text) async {
    if (text.trim().isEmpty) return false;
    if (isSendingQuestion.value) return false;

    final postIdRaw =
        selectedAttachment.value?['post_id'] ??
        liveDetail.value?['current_slide']?['post_id'] ??
        liveDetail.value?['post_id'] ??
        liveDetail.value?['post']?['post_id'];
    final attachmentIdRaw =
        selectedAttachment.value?['attachment_id'] ??
        liveDetail.value?['current_slide']?['attachment_id'];
    final auth = Get.find<AuthController>();
    final askerIdRaw = auth.userId.value;
    final slideNumber = (currentPage.value < 0 ? 0 : currentPage.value) + 1;

    int? postId = _toInt(postIdRaw);
    int? attachmentId = _toInt(attachmentIdRaw);
    final askerId = _toInt(askerIdRaw);

    if ((postId == null || attachmentId == null) && qaLiveId.value != null) {
      await fetchLiveDetail();
      await fetchCurrentSlide();

      final retryPostIdRaw =
          selectedAttachment.value?['post_id'] ??
          liveDetail.value?['current_slide']?['post_id'] ??
          liveDetail.value?['post_id'] ??
          liveDetail.value?['post']?['post_id'];
      final retryAttachmentIdRaw =
          selectedAttachment.value?['attachment_id'] ??
          liveDetail.value?['current_slide']?['attachment_id'];

      postId = _toInt(retryPostIdRaw);
      attachmentId = _toInt(retryAttachmentIdRaw);
    }

    if (postId == null ||
        attachmentId == null ||
        qaLiveId.value == null ||
        askerId == null) {
      appLog.warning(
        'sendQuestion aborted - missing required parameters',
        actionPage: 'LiveController.sendQuestion',
        data: {
          'postId': postIdRaw,
          'attachmentId': attachmentIdRaw,
          'askerId': askerIdRaw,
          'qaLiveId': qaLiveId.value,
        },
      );
      return false;
    }

    final tempId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final currentUserAsker = _currentUserAsker();
    final optimisticQuestionMap = <String, dynamic>{
      'qa_question_id': tempId,
      'qa_live_id': qaLiveId.value,
      'question': text.trim(),
      'asker_id': askerId,
      'post_id': postId,
      'attachment_id': attachmentId,
      'slide_number': slideNumber,
      'status': 'PENDING',
      'upvote_count': 0,
      'is_local_pending': true,
      'created_at': DateTime.now().toIso8601String(),
      if (currentUserAsker.isNotEmpty) 'asker': currentUserAsker,
    };

    final optimisticQuestion = QaQuestion.fromJson(optimisticQuestionMap);
    questions.insert(0, optimisticQuestion);
    questions.refresh();
    isSendingQuestion.value = true;

    try {
      appLog.debug(
        'Sending question',
        actionPage: 'LiveController.sendQuestion',
        data: {
          'qaLiveId': qaLiveId.value,
          'askerId': askerId,
          'postId': postId,
          'attachmentId': attachmentId,
          'slideNumber': slideNumber,
        },
      );
      await _repo.sendQuestion(
        qaLiveId: qaLiveId.value!,
        question: text.trim(),
        postId: postId,
        attachmentId: attachmentId,
        askerId: askerId,
        slideNumber: slideNumber,
        isAnonymous: isAnonymous.value,
      );

      questions.removeWhere((q) => q['qa_question_id'] == tempId);
      questions.refresh();

      // Sync with source of truth so temporary item is replaced by persisted data.
      await fetchQuestions();
      return true;
    } catch (e) {
      questions.removeWhere((q) => q['qa_question_id'] == tempId);
      questions.refresh();
      appLog.error(
        'Failed to send question',
        actionPage: 'LiveController.sendQuestion',
        data: {'error': e.toString()},
      );
      return false;
    } finally {
      isSendingQuestion.value = false;
    }
  }

  Future<String?> downloadPdf(String url, {dynamic attachmentId}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return null;
      }

      final dir = await getTemporaryDirectory();
      final normalizedAttachmentId = _toInt(attachmentId) ?? 0;
      final file = File(
        '${dir.path}/live_${qaLiveId.value}_${normalizedAttachmentId}_${url.hashCode}.pdf',
      );
      await file.writeAsBytes(response.bodyBytes);

      return file.path;
    } catch (e) {
      appLog.error(
        'Failed to download PDF',
        actionPage: 'LiveController.downloadPdf',
        data: {'url': url, 'error': e.toString()},
      );
      return null;
    }
  }

  Map<String, dynamic> _enrichQuestion(Map<String, dynamic> question) {
    final auth = Get.find<AuthController>();
    final currentUserId = auth.userId.value;
    final askerId = _toInt(question['asker_id']);

    final questionId = _toInt(question['qa_question_id']);
    if (questionId != null &&
        _persistedUpvotedQuestionIds.contains(questionId)) {
      question['is_upvoted'] = true;
    }

    if (currentUserId == null || askerId != currentUserId) {
      return question;
    }

    final existingAsker = question['asker'];
    if (existingAsker is Map) {
      final map = Map<String, dynamic>.from(existingAsker);
      final hasName =
          (map['first_name']?.toString().trim().isNotEmpty ?? false) ||
          (map['last_name']?.toString().trim().isNotEmpty ?? false);
      if (hasName) {
        return question;
      }
    }

    final currentAsker = _currentUserAsker();
    if (currentAsker.isEmpty) {
      return question;
    }

    question['asker'] = currentAsker;
    return question;
  }

  Map<String, dynamic> _currentUserAsker() {
    if (!Get.isRegistered<ProfileController>()) {
      return {};
    }

    final profile = Get.find<ProfileController>().profile.value;
    if (profile == null) {
      return {};
    }

    return {
      'first_name': profile.firstName,
      'last_name': profile.lastName,
      'profile_pic': profile.profilePic,
      'is_anonymous': isAnonymous.value,
    };
  }

  Map<String, dynamic>? _parseQuestion(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final source = Map<String, dynamic>.from(raw);
    Map<String, dynamic> question = source;

    final nested =
        source['question'] ?? source['data'] ?? source['qa_question'];
    if (nested is Map) {
      question = Map<String, dynamic>.from(nested);
    }

    if ((question['question'] == null ||
            '${question['question']}'.trim().isEmpty) &&
        question['message'] != null) {
      question['question'] = question['message'];
    }
    if ((question['question'] == null ||
            '${question['question']}'.trim().isEmpty) &&
        question['content'] != null) {
      question['question'] = question['content'];
    }
    if ((question['question'] == null ||
            '${question['question']}'.trim().isEmpty) &&
        question['text'] != null) {
      question['question'] = question['text'];
    }

    if (question['asker'] == null && source['asker'] is Map) {
      question['asker'] = Map<String, dynamic>.from(source['asker']);
    }
    if (question['asker'] == null && source['user'] is Map) {
      question['asker'] = Map<String, dynamic>.from(source['user']);
    }
    if (question['asker'] == null && source['sender'] is Map) {
      question['asker'] = Map<String, dynamic>.from(source['sender']);
    }
    if (question['asker'] == null && question['sender'] is Map) {
      question['asker'] = Map<String, dynamic>.from(question['sender']);
    }

    if (question['qa_question_id'] == null &&
        source['qa_question_id'] != null) {
      question['qa_question_id'] = source['qa_question_id'];
    }
    if (question['asker_id'] == null && source['asker_id'] != null) {
      question['asker_id'] = source['asker_id'];
    }
    if (question['created_at'] == null && source['created_at'] != null) {
      question['created_at'] = source['created_at'];
    }
    if (question['slide_number'] == null && source['slide_number'] != null) {
      question['slide_number'] = source['slide_number'];
    }
    if (question['upvote_count'] == null && source['upvote_count'] != null) {
      question['upvote_count'] = source['upvote_count'];
    }
    if (question['asker_id'] == null && source['user_id'] != null) {
      question['asker_id'] = source['user_id'];
    }
    if (question['asker_id'] == null && source['sender_id'] != null) {
      question['asker_id'] = source['sender_id'];
    }
    if (question['created_at'] == null && source['timestamp'] != null) {
      question['created_at'] = source['timestamp'];
    }

    final text = question['question']?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    return question;
  }

  List<Map<String, dynamic>> _extractQuestionItems(dynamic source) {
    final result = <Map<String, dynamic>>[];
    final queue = <dynamic>[source];

    while (queue.isNotEmpty) {
      final node = queue.removeLast();

      if (node is Map) {
        final map = Map<String, dynamic>.from(node);

        final parsed = _parseQuestion(map);
        if (parsed != null) {
          final liveId = _toInt(parsed['qa_live_id']);
          if (qaLiveId.value == null ||
              liveId == null ||
              liveId == qaLiveId.value) {
            result.add(parsed);
          }
        }

        for (final value in map.values) {
          if (value is Map || value is List) {
            queue.add(value);
          }
        }
      } else if (node is List) {
        for (final item in node) {
          if (item is Map || item is List) {
            queue.add(item);
          }
        }
      }
    }

    return result;
  }

  String _sanitizeText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null' || text == '-') {
      return '';
    }
    return text;
  }

  bool _looksLikeQuestionPayload(Map<String, dynamic> payload) {
    if (payload['qa_question_id'] != null) return true;
    if (payload['question'] is String) return true;
    if (payload['message'] is String) return true;
    if (payload['question'] is Map) return true;
    return false;
  }

  Future<void> _hydrateMissingAskers() async {
    final idsToLoad = <int>{};
    var appliedCached = false;

    for (final question in questions) {
      final askerId = question.askerId;
      if (askerId == null || question.isAnonymous) continue;

      final asker = question.asker;
      final hasName =
          asker != null &&
          ((asker.firstName?.trim().isNotEmpty ?? false) ||
              (asker.lastName?.trim().isNotEmpty ?? false));
      if (hasName) continue;

      final cached = _askerProfileCache[askerId];
      if (cached != null) {
        appliedCached = true;
        continue;
      }

      if (!_loadingAskerIds.contains(askerId)) {
        idsToLoad.add(askerId);
      }
    }

    if (appliedCached) {
      final updated = questions.map((q) {
        if (q.askerId != null && !q.isAnonymous) {
          final cached = _askerProfileCache[q.askerId];
          if (cached != null &&
              (q.asker == null ||
                  (q.asker!.firstName?.trim().isEmpty ?? true))) {
            return q.copyWith(asker: cached);
          }
        }
        return q;
      }).toList();
      questions.assignAll(updated);
    }

    if (idsToLoad.isEmpty) {
      return;
    }

    _loadingAskerIds.addAll(idsToLoad);

    for (final askerId in idsToLoad) {
      try {
        final profile = await _profileRepoInstance.getProfile(askerId);
        _askerProfileCache[askerId] = QaAsker(
          userId: askerId,
          firstName: profile.firstName,
          lastName: profile.lastName,
          profilePic: profile.profilePic,
          isAnonymous: false,
        );
      } catch (_) {
        // Keep fallback name when profile endpoint is not available for this id.
      } finally {
        _loadingAskerIds.remove(askerId);
      }
    }

    var changed = false;
    final updated = <QaQuestion>[];
    for (final question in questions) {
      final askerId = question.askerId;
      if (askerId == null) {
        updated.add(question);
        continue;
      }

      final cached = _askerProfileCache[askerId];
      if (cached == null) {
        updated.add(question);
        continue;
      }

      final asker = question.asker;
      final hasName =
          asker != null &&
          ((asker.firstName?.trim().isNotEmpty ?? false) ||
              (asker.lastName?.trim().isNotEmpty ?? false));

      if (!hasName) {
        updated.add(question.copyWith(asker: cached));
        changed = true;
      } else {
        updated.add(question);
      }
    }

    if (changed) {
      questions.assignAll(updated);
    }
  }

  void _exitLivePage() {
    isChatOpen.value = false;

    if (Get.isOverlaysOpen == true) {
      Get.back();
    }

    if (Get.currentRoute == AppRoutes.livePage || Get.currentRoute.isNotEmpty) {
      Get.back();
    }
  }

  List<Map<String, dynamic>> _normalizeLiveFiles(List<dynamic> rawFiles) {
    final normalized = <Map<String, dynamic>>[];

    for (final item in rawFiles) {
      if (item is! Map) continue;
      final mapItem = Map<String, dynamic>.from(item);

      if (mapItem['attachment_id'] != null) {
        normalized.add(mapItem);
        continue;
      }

      final attachments = mapItem['attachments'];
      if (attachments is List) {
        for (final attachment in attachments) {
          if (attachment is Map) {
            final normalizedAttachment = Map<String, dynamic>.from(attachment);
            if (normalizedAttachment['post_id'] == null &&
                mapItem['post_id'] != null) {
              normalizedAttachment['post_id'] = mapItem['post_id'];
            }
            normalized.add(normalizedAttachment);
          }
        }
      }
    }

    return normalized;
  }

  List<Map<String, dynamic>> _dedupeLiveLogs(List<Map<String, dynamic>> logs) {
    final result = <Map<String, dynamic>>[];
    final seenAttachmentIds = <int>{};

    for (final log in logs) {
      final attachment = _extractAttachmentFromLog(log);
      final attachmentId = _toInt(attachment?['attachment_id']);
      if (attachmentId == null) {
        result.add(log);
        continue;
      }

      if (seenAttachmentIds.add(attachmentId)) {
        result.add(log);
      }
    }

    return result;
  }

  Map<String, dynamic>? _extractAttachmentFromLog(Map<String, dynamic> log) {
    final attachment = log['attachment'];
    if (attachment is Map) {
      return _normalizeAttachmentShape(Map<String, dynamic>.from(attachment));
    }

    final attachmentId = _toInt(log['attachment_id']);
    if (attachmentId == null) {
      return null;
    }

    final fallback = <String, dynamic>{
      'attachment_id': attachmentId,
      'post_id': log['post_id'],
      'file_url': log['file_url'],
      'file_type': log['file_type'],
      'original_name': log['original_name'],
      'file_name': log['file_name'],
    };

    return _normalizeAttachmentShape(fallback);
  }

  Map<String, dynamic> _normalizeAttachmentShape(
    Map<String, dynamic> attachment,
  ) {
    final normalized = Map<String, dynamic>.from(attachment);

    final candidateUrl =
        [
          normalized['file_url'],
          normalized['url'],
          normalized['file_path'],
          normalized['attachment_url'],
          normalized['s3_url'],
          normalized['download_url'],
        ].firstWhere(
          (value) => value != null && value.toString().trim().isNotEmpty,
          orElse: () => null,
        );

    if (candidateUrl != null) {
      normalized['file_url'] = candidateUrl.toString();
    }

    final candidateType =
        [
          normalized['file_type'],
          normalized['mime_type'],
          normalized['content_type'],
        ].firstWhere(
          (value) => value != null && value.toString().trim().isNotEmpty,
          orElse: () => null,
        );

    if (candidateType != null) {
      normalized['file_type'] = candidateType.toString().toLowerCase();
    }

    return normalized;
  }

  void _ensureSelectedAttachmentHasUrl() {
    final current = selectedAttachment.value;
    if (current == null) {
      return;
    }

    final currentUrl = current['file_url']?.toString().trim() ?? '';
    if (currentUrl.isNotEmpty) {
      return;
    }

    final resolved = resolveAttachmentById(current['attachment_id']);
    if (resolved == null) {
      return;
    }

    final normalized = _normalizeAttachmentShape(
      Map<String, dynamic>.from(resolved),
    );
    final resolvedUrl = normalized['file_url']?.toString().trim() ?? '';
    if (resolvedUrl.isNotEmpty) {
      selectedAttachment.value = normalized;
    }
  }

  Map<String, dynamic>? resolveAttachmentById(dynamic attachmentIdRaw) {
    final attachmentId = _toInt(attachmentIdRaw);
    appLog.debug(
      'Resolving attachment',
      actionPage: 'LiveController.resolveAttachmentById',
      data: {'attachmentIdRaw': attachmentIdRaw, 'attachmentId': attachmentId},
    );
    if (attachmentId == null) {
      appLog.debug(
        'Attachment ID conversion failed',
        actionPage: 'LiveController.resolveAttachmentById',
      );
      return null;
    }

    appLog.debug(
      'Searching in collections',
      actionPage: 'LiveController.resolveAttachmentById',
      data: {
        'liveFilesCount': liveFiles.length,
        'liveLogFilesCount': liveLogFiles.length,
      },
    );
    for (final file in liveFiles) {
      final fileAttId = _toInt(file['attachment_id']);
      if (fileAttId == attachmentId) {
        appLog.debug(
          'Found in liveFiles',
          actionPage: 'LiveController.resolveAttachmentById',
          data: {'attachmentId': attachmentId},
        );
        return file;
      }
    }

    for (final log in liveLogFiles) {
      final logAttId = _toInt(log['attachment_id']);
      if (logAttId == attachmentId) {
        appLog.debug(
          'Found in liveLogFiles, resolving',
          actionPage: 'LiveController.resolveAttachmentById',
          data: {'attachmentId': attachmentId},
        );
        final resolved = _resolveAttachmentForLog(log);
        if (resolved != null) {
          appLog.debug(
            'Successfully resolved from log',
            actionPage: 'LiveController.resolveAttachmentById',
            data: {'attachmentId': attachmentId},
          );
          return resolved;
        }
      }
    }

    appLog.debug(
      'Attachment not found in any collection',
      actionPage: 'LiveController.resolveAttachmentById',
      data: {'attachmentId': attachmentId},
    );
    return null;
  }

  Map<String, dynamic>? _resolveAttachmentForLog(Map<String, dynamic> log) {
    final attachment = _extractAttachmentFromLog(log);
    if (attachment == null) {
      return null;
    }

    final attachmentId = _toInt(attachment['attachment_id']);
    if (attachmentId != null) {
      for (final file in liveFiles) {
        if (_toInt(file['attachment_id']) == attachmentId) {
          return file;
        }
      }
    }

    return attachment;
  }

  void _syncSelectedAttachmentWithLiveLogs() {
    if (liveLogFiles.isEmpty) {
      return;
    }

    final currentAttachmentId = _toInt(
      selectedAttachment.value?['attachment_id'],
    );
    if (currentAttachmentId != null) {
      final currentResolved = resolveAttachmentById(currentAttachmentId);
      if (currentResolved != null) {
        selectedAttachment.value = currentResolved;
        return;
      }
    }

    final currentOpenLog = liveLogFiles.lastWhere(
      (log) => log['closed_at'] == null,
      orElse: () => liveLogFiles.last,
    );
    selectedAttachment.value = _resolveAttachmentForLog(currentOpenLog);
  }

  List<dynamic> _extractLiveFileItems(dynamic source) {
    final result = <dynamic>[];
    final queue = <dynamic>[source];

    while (queue.isNotEmpty) {
      final node = queue.removeLast();

      if (node is Map) {
        final map = Map<String, dynamic>.from(node);

        if (map['attachment_id'] != null &&
            (map['file_url'] != null ||
                map['file_name'] != null ||
                map['original_name'] != null ||
                map['file_type'] != null)) {
          result.add(map);
        }

        final attachments = map['attachments'];
        if (attachments is List) {
          for (final attachment in attachments) {
            if (attachment is Map || attachment is List) {
              queue.add(attachment);
            }
          }
        }

        for (final value in map.values) {
          if (value is Map || value is List) {
            queue.add(value);
          }
        }
      } else if (node is List) {
        for (final item in node) {
          if (item is Map || item is List) {
            queue.add(item);
          }
        }
      }
    }

    return result;
  }

  Map<String, dynamic>? _findFileByAttachmentId(dynamic attachmentId) {
    final targetId = _toInt(attachmentId);
    if (targetId == null) {
      return null;
    }

    for (final file in liveFiles) {
      if (_toInt(file['attachment_id']) == targetId) {
        return file;
      }
    }

    for (final log in liveLogFiles) {
      final resolved = _resolveAttachmentForLog(log);
      if (resolved != null && _toInt(resolved['attachment_id']) == targetId) {
        return resolved;
      }
    }

    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _upvotedQuestionStorageKey() {
    final liveId = qaLiveId.value;
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final userId = auth?.userId.value;
    if (liveId == null || userId == null) {
      return '';
    }

    return 'qa_upvoted_questions_${liveId}_$userId';
  }

  Future<void> _loadPersistedUpvotedQuestions() async {
    _persistedUpvotedQuestionIds.clear();

    final storageKey = _upvotedQuestionStorageKey();
    if (storageKey.isEmpty) {
      return;
    }

    final storedIds = await LocalStorage.getStringList(storageKey);
    for (final value in storedIds) {
      final id = int.tryParse(value);
      if (id != null) {
        _persistedUpvotedQuestionIds.add(id);
      }
    }

    _applyPersistedUpvoteState();
  }

  Future<void> setFollowing(bool value) async {
    isFollowing.value = value;
    if (!value) {
      return;
    }

    // Immediately sync to presenter's current file/slide when follow is turned on.
    await fetchLiveLogs();
    await fetchCurrentSlide();
  }

  bool get isCurrentUserPresenter {
    if (!Get.isRegistered<AuthController>()) {
      return false;
    }

    final userId = Get.find<AuthController>().userId.value;
    final liveBy = _toInt(liveDetail.value?['live_by']);
    if (userId == null || liveBy == null) {
      return false;
    }

    return userId == liveBy;
  }

  Future<void> selectPresentationFile(Map<String, dynamic> attachment) async {
    // Manual file selection should stop auto-following presenter changes.
    isFollowing.value = false;

    final attachmentId = _toInt(attachment['attachment_id']);
    appLog.debug(
      'selectPresentationFile - Starting',
      actionPage: 'LiveController.selectPresentationFile',
      data: {'attachmentId': attachmentId},
    );

    // Reset previous PDF controller state before swapping files.
    pdfController.value = null;
    totalPages.value = 0;
    currentSlide.value = 1;
    currentPage.value = 0;
    _pendingFollowPage = null;

    // Increment token to force UI rebuild and signal that a new PDF is being loaded
    pdfRebuildToken.value = (pdfRebuildToken.value + 1) % 1000000;

    final normalized = Map<String, dynamic>.from(attachment);
    selectedAttachment.value = normalized;

    appLog.debug(
      'selectPresentationFile - After reset',
      actionPage: 'LiveController.selectPresentationFile',
      data: {
        'attachmentId': attachmentId,
        'rebuildToken': pdfRebuildToken.value,
      },
    );

    if (isHistoryMode.value || !isCurrentUserPresenter) {
      appLog.debug(
        'selectPresentationFile - Skipping (history mode or not presenter)',
        actionPage: 'LiveController.selectPresentationFile',
      );
      return;
    }

    final liveId = qaLiveId.value;
    final postId = _toInt(
      normalized['post_id'] ??
          liveDetail.value?['current_slide']?['post_id'] ??
          liveDetail.value?['post_id'],
    );

    if (liveId == null || postId == null || attachmentId == null) {
      appLog.warning(
        'selectPresentationFile - Missing required IDs',
        actionPage: 'LiveController.selectPresentationFile',
        data: {
          'liveId': liveId,
          'postId': postId,
          'attachmentId': attachmentId,
        },
      );
      return;
    }

    try {
      await _repo.createLiveLog(
        qaLiveId: liveId,
        postId: postId,
        attachmentId: attachmentId,
      );
      appLog.debug(
        'selectPresentationFile - Created live log successfully',
        actionPage: 'LiveController.selectPresentationFile',
      );
      // Do NOT immediately fetch logs after creating a new live log.
      // The backend may return stale current-log that can override selectedAttachment.
      // Instead, rely on FILE_CHANGED event or next polling cycle to update liveLogFiles.
      // await fetchLiveLogs();
    } catch (e) {
      appLog.error(
        'Failed to create live log',
        actionPage: 'LiveController.selectPresentationFile',
        data: {'error': e.toString()},
      );
    }
  }

  void onPdfPageChanged(int pageIndex) {
    // Ignore automatic page change from PDF render if we're syncing a specific page
    if (_isFileChangingInProgress && currentPage.value != pageIndex) {
      appLog.debug(
        'PDF page change ignored (file changing)',
        actionPage: 'LiveController.onPdfPageChanged',
        data: {'pageIndex': pageIndex, 'currentPage': currentPage.value},
      );
      return;
    }

    final safePageIndex = pageIndex < 0 ? 0 : pageIndex;
    final slideNumber = safePageIndex + 1;
    appLog.debug(
      'PDF page changed',
      actionPage: 'LiveController.onPdfPageChanged',
      data: {
        'pageIndex': pageIndex,
        'safePageIndex': safePageIndex,
        'slideNumber': slideNumber,
      },
    );
    currentSlide.value = slideNumber;
    currentPage.value = safePageIndex;

    if (isHistoryMode.value || !isCurrentUserPresenter) {
      return;
    }

    if (!Get.isRegistered<AuthController>()) {
      return;
    }

    final userId = Get.find<AuthController>().userId.value;
    final liveId = qaLiveId.value;
    if (userId == null || liveId == null) {
      return;
    }

    final now = DateTime.now();
    final justPublishedSameSlide =
        _lastPublishedSlideNumber == slideNumber &&
        _lastPublishedSlideAt != null &&
        now.difference(_lastPublishedSlideAt!) <
            const Duration(milliseconds: 450);

    if (justPublishedSameSlide) {
      return;
    }

    _lastPublishedSlideNumber = slideNumber;
    _lastPublishedSlideAt = now;

    _socket.syncSlide(
      slideNumber: slideNumber,
      qaLiveId: liveId.toString(),
      userId: userId,
    );
  }

  void applyCurrentPageToPdf() {
    final currentPageValue = currentPage.value;
    appLog.debug(
      'applyCurrentPageToPdf',
      actionPage: 'LiveController.applyCurrentPageToPdf',
      data: {
        'currentPage': currentPageValue,
        'hasPdf': pdfController.value != null,
      },
    );
    _pendingFollowPage = currentPageValue < 0 ? 0 : currentPageValue;
    appLog.debug(
      'Set pending follow page',
      actionPage: 'LiveController.applyCurrentPageToPdf',
      data: {'pendingPage': _pendingFollowPage},
    );
    _applyPendingFollowPage();
  }

  void _applyPendingFollowPage() {
    final controller = pdfController.value;
    final pending = _pendingFollowPage;
    appLog.debug(
      'Applying pending follow page',
      actionPage: 'LiveController._applyPendingFollowPage',
      data: {'hasPdf': controller != null, 'pending': pending},
    );
    if (controller == null || pending == null) {
      appLog.debug(
        'Controller or pending is null',
        actionPage: 'LiveController._applyPendingFollowPage',
      );
      return;
    }

    appLog.debug(
      'Calling PDF controller.setPage',
      actionPage: 'LiveController._applyPendingFollowPage',
      data: {'page': pending},
    );
    unawaited(controller.setPage(pending));
    _pendingFollowPage = null;
  }

  Future<void> _persistUpvotedQuestion(int questionId) async {
    _persistedUpvotedQuestionIds.add(questionId);

    final storageKey = _upvotedQuestionStorageKey();
    if (storageKey.isEmpty) {
      return;
    }

    await LocalStorage.saveStringList(
      storageKey,
      _persistedUpvotedQuestionIds.map((id) => id.toString()).toList(),
    );

    _applyPersistedUpvoteState();
  }

  void _applyPersistedUpvoteState() {
    var changed = false;
    final updated = <QaQuestion>[];

    for (final question in questions) {
      final questionId = _toInt(question.qaQuestionId);
      if (questionId == null) {
        updated.add(question);
        continue;
      }

      if (_persistedUpvotedQuestionIds.contains(questionId) &&
          !question.isUpvoted) {
        updated.add(question.copyWith(isUpvoted: true));
        changed = true;
      } else {
        updated.add(question);
      }
    }

    if (changed) {
      questions.assignAll(updated);
    }
  }

  Future<void> leaveLiveSession() async {
    if (_hasLeftLiveSession) {
      return;
    }
    _hasLeftLiveSession = true;

    _socketReconnectTimer?.cancel();
    appLog.debug(
      'leaveLiveSession - cancelled reconnect timer',
      actionPage: 'LiveController.leaveLiveSession',
    );

    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final userId = auth?.userId.value;
    final liveId = qaLiveId.value;
    final sectionId =
        _toInt(Get.arguments?['sectionId']) ??
        _toInt(liveDetail.value?['section_id']);

    if (userId != null && liveId != null) {
      _socket.leaveQaLive(userId: userId, qaLiveId: liveId);
    }
    if (userId != null && sectionId != null) {
      _socket.leaveQaSectionRoom(userId: userId, sectionId: sectionId);
    }

    await _qaSubscription?.cancel();

    _socket.disconnectQa();
  }

  @override
  void onClose() {
    unawaited(leaveLiveSession());
    super.onClose();
  }
}
