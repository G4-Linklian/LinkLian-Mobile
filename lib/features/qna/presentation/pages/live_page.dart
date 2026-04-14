import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/core/utils/logger.dart';
import 'package:LinkLian/features/qna/presentation/controllers/live_controller.dart';
import 'package:LinkLian/features/qna/presentation/widgets/chat_fab_widget.dart';
import 'package:LinkLian/features/qna/presentation/widgets/chat_panel_widget.dart';
import 'package:LinkLian/features/qna/presentation/widgets/pagination_bar_widget.dart';
import 'package:LinkLian/features/qna/presentation/widgets/presentation_file_selector.dart';
import 'package:LinkLian/features/qna/presentation/widgets/slide_viewer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get/get.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  late final LiveController controller;
  final TextEditingController textController = TextEditingController();
  final ScrollController _questionScrollController = ScrollController();
  double _chatSheetFraction = 0.75;

  static const double _chatSheetMinFraction = 0.5;
  static const double _chatSheetMaxFraction = 0.92;
  static const List<double> _chatSheetSnapFractions = [0.5, 0.75, 0.92];

  bool get _isHistoryMode => controller.isHistoryMode.value;

  @override
  void initState() {
    super.initState();
    final hasRegisteredController = Get.isRegistered<LiveController>();
    controller = hasRegisteredController
        ? Get.find<LiveController>()
        : Get.put(LiveController());

    _chatSheetFraction = 0.75;
    controller.isChatOpen.value = false;
    // New controller already runs enter flow in onInit.
    // Manually re-enter only when reusing an existing controller instance.
    if (hasRegisteredController) {
      controller.enterLiveSessionFromArgs();
    }

    // Debug logging
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.questions.isNotEmpty) {
        appLog.debug(
          'First question loaded',
          actionPage: 'LivePage.initState',
          data: {
            'question': controller.questions.first.toString(),
            'slideNumber': controller.questions.first.slideNumber,
          },
        );
      }
    });
  }

  @override
  void dispose() {
    controller.leaveLiveSession();
    _questionScrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  void _onHeaderDragUpdate(double primaryDelta, double screenHeight) {
    if (screenHeight <= 0) return;

    final next = (_chatSheetFraction - (primaryDelta / screenHeight)).clamp(
      _chatSheetMinFraction,
      _chatSheetMaxFraction,
    );

    if (next != _chatSheetFraction) {
      setState(() {
        _chatSheetFraction = next;
      });
    }
  }

  void _snapChatSheet() {
    double target = _chatSheetSnapFractions.first;
    double bestDistance = (_chatSheetFraction - target).abs();

    for (final snap in _chatSheetSnapFractions.skip(1)) {
      final distance = (_chatSheetFraction - snap).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        target = snap;
      }
    }

    if (target != _chatSheetFraction) {
      setState(() {
        _chatSheetFraction = target;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        controller.leaveLiveSession();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryPalette[100],
          elevation: 0.5,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () async {
              await controller.leaveLiveSession();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          centerTitle: true,
          title: Obx(() {
            final title =
                controller.liveDetail.value?['live_title']?.toString() ?? '';
            return Text(
              title.isNotEmpty ? title : 'Live Session',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            );
          }),
          actions: [
            Obx(() {
              final count = controller.viewerCount.value;
              if (count == 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        TablerIcons.users,
                        color: AppColors.primaryPalette[600],
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: AppColors.primaryPalette[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        body: _isHistoryMode
            ? _buildHistoryBody(context)
            : Stack(
                children: [
                  Column(
                    children: [
                      _buildTopControlBar(),

                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 0,
                            bottom:
                                MediaQuery.of(context).size.height *
                                (_chatSheetFraction - 0.5).clamp(0.0, 0.3),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height *
                                      (_chatSheetFraction <= 0.5
                                          ? 0.34
                                          : 0.44), 
                                  width: double.infinity,
                                  child: _buildSlideArea(),
                                ),

                                _buildPaginationBar(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox.shrink(),

                  Positioned(right: 16, bottom: 16, child: _buildChatFab()),
                  Obx(
                    () => controller.isChatOpen.value
                        ? Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height:
                                MediaQuery.of(context).size.height *
                                _chatSheetFraction,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOutCubic,
                              child: ChatPanelWidget(
                                controller: controller,
                                textController: textController,
                                scrollController: _questionScrollController,
                                readOnly: _isHistoryMode,
                                onHeaderDragUpdate: (delta, screenHeight) =>
                                    _onHeaderDragUpdate(delta, screenHeight),
                                onHeaderDragEnd: _snapChatSheet,
                                onClose: () {
                                  if (mounted) {
                                    setState(() {
                                      _chatSheetFraction = 0.75;
                                    });
                                  }
                                },
                                blockInput: false,
                                onReply: (slideNumber) {
                                  appLog.debug(
                                    'Chat panel reply triggered',
                                    actionPage: 'LivePage.onReply',
                                    data: {'slideNumber': slideNumber},
                                  );
                                  if (slideNumber == null) {
                                    appLog.warning(
                                      'slideNumber is null in onReply',
                                      actionPage: 'LivePage.onReply',
                                    );
                                    Get.snackbar('ข้อผิดพลาด', 'ไม่พบเลขหน้า');
                                    return;
                                  }
                                  // if (slideNumber is! int) {
                                  //   appLog.warning('slideNumber is not int', actionPage: 'LivePage.onReply', data: {'type': slideNumber.runtimeType.toString(), 'value': slideNumber.toString()});
                                  //   return;
                                  // }
                                  final targetPage = slideNumber > 0
                                      ? slideNumber - 1
                                      : 0;
                                  appLog.debug(
                                    'Navigating to page',
                                    actionPage: 'LivePage.onReply',
                                    data: {
                                      'targetPage': targetPage,
                                      'hasPdfController':
                                          controller.pdfController.value !=
                                          null,
                                    },
                                  );
                                  if (controller.pdfController.value == null) {
                                    appLog.warning(
                                      'PDF controller not initialized',
                                      actionPage: 'LivePage.onReply',
                                    );
                                    Get.snackbar(
                                      'รอสักครู่',
                                      'PDF กำลังโหลด กรุณารอ...',
                                    );
                                    return;
                                  }
                                  try {
                                    controller.pdfController.value!.setPage(
                                      targetPage,
                                    );
                                    appLog.debug(
                                      'Successfully navigated to page',
                                      actionPage: 'LivePage.onReply',
                                      data: {'page': targetPage},
                                    );
                                  } catch (e) {
                                    appLog.error(
                                      'Failed to navigate to page',
                                      actionPage: 'LivePage.onReply',
                                      data: {
                                        'targetPage': targetPage,
                                        'error': e.toString(),
                                      },
                                    );
                                    Get.snackbar(
                                      'ข้อผิดพลาด',
                                      'ไม่สามารถเปิดหน้าได้',
                                    );
                                  }
                                },
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHistoryBody(BuildContext context) {
    return Column(
      children: [
        _buildTopControlBar(showFollow: false),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.34,
          width: double.infinity,
          child: SlideViewerWidget(controller: controller),
        ),
        PaginationBarWidget(controller: controller),
        const SizedBox(height: 8),
        Expanded(
          child: ChatPanelWidget(
            controller: controller,
            textController: textController,
            scrollController: _questionScrollController,
            inlineMode: true,
            readOnly: true,
            draggable: false,
            onReply: (slideNumber) {
              appLog.debug(
                'History mode reply triggered',
                actionPage: 'LivePage._buildHistoryBody.onReply',
                data: {'slideNumber': slideNumber},
              );
              if (slideNumber == null) {
                appLog.warning(
                  'slideNumber is null in history mode onReply',
                  actionPage: 'LivePage._buildHistoryBody.onReply',
                );
                Get.snackbar('ข้อผิดพลาด', 'ไม่พบเลขหน้า');
                return;
              }
              // if (slideNumber is! int) {
              //   appLog.warning('slideNumber is not int in history mode', actionPage: 'LivePage._buildHistoryBody.onReply', data: {'type': slideNumber.runtimeType.toString(), 'value': slideNumber.toString()});
              //   return;
              // }
              final targetPage = slideNumber > 0 ? slideNumber - 1 : 0;
              appLog.debug(
                'Navigating to page in history mode',
                actionPage: 'LivePage._buildHistoryBody.onReply',
                data: {
                  'targetPage': targetPage,
                  'hasPdfController': controller.pdfController.value != null,
                },
              );
              if (controller.pdfController.value == null) {
                appLog.warning(
                  'PDF controller not initialized in history mode',
                  actionPage: 'LivePage._buildHistoryBody.onReply',
                );
                Get.snackbar('รอสักครู่', 'PDF กำลังโหลด กรุณารอ...');
                return;
              }
              try {
                controller.pdfController.value!.setPage(targetPage);
                appLog.debug(
                  'Successfully navigated to page in history mode',
                  actionPage: 'LivePage._buildHistoryBody.onReply',
                  data: {'page': targetPage},
                );
              } catch (e) {
                appLog.error(
                  'Failed to navigate to page in history mode',
                  actionPage: 'LivePage._buildHistoryBody.onReply',
                  data: {'targetPage': targetPage, 'error': e.toString()},
                );
                Get.snackbar('ข้อผิดพลาด', 'ไม่สามารถเปิดหน้าได้');
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopControlBar({bool showFollow = true}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: PresentationFileSelector(
        controller: controller,
        showFollow: showFollow,
        onFileSelected: (attachment) {
          controller.selectPresentationFile(
            Map<String, dynamic>.from(attachment),
          );
        },
      ),
    );
  }

  Widget _buildSlideArea() {
    return SlideViewerWidget(controller: controller);
  }

  Widget _buildPaginationBar() {
    return PaginationBarWidget(controller: controller);
  }

  Widget _buildChatFab() {
    return ChatFabWidget(controller: controller);
  }
}
