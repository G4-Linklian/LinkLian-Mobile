import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/features/chat/presentation/widgets/ai_link_preview_card.dart';
import 'package:LinkLian/features/shared/repositories/ai_chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:LinkLian/features/chat/presentation/widgets/ai_quiz_popup.widget.dart';
import 'package:LinkLian/features/chat/presentation/widgets/chat_attachment_widget.dart';

class AIChatDetailPage extends StatefulWidget {
  final String title;
  final int aiChatId;
  final String summary;
  final String content;
  final List attachments;
  // final String className;

  const AIChatDetailPage({
    super.key,
    required this.title,
    required this.aiChatId,
    required this.summary,
    required this.content,
    required this.attachments,
    // required this.className,
  });

  @override
  State<AIChatDetailPage> createState() => _AIChatDetailPageState();
}

class _AIChatDetailPageState extends State<AIChatDetailPage> {
  final TextEditingController _textController = TextEditingController();

  List<Map<String, dynamic>> messages = [];

  bool get hasText => _textController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    messages.add({"isMe": false, "text": widget.summary});

    _textController.addListener(() {
      setState(() {});
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"isMe": true, "text": text});
    });

    _textController.clear();
  }

  void _generateQuiz() async {
    showDialog(
      context: context,
      builder: (context) {
        return AIQuizPopup(
          onGenerate: (difficulty, questionCount) async {
            final repo = AIChatRepository();

            await repo.generateQuiz(
              aiChatId: widget.aiChatId,
              difficulty: difficulty,
              questionCount: questionCount,
            );

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Quiz generated successfully")),
            );
          },
        );
      },
    );
  }

  /// =========================
  /// POST CARD
  /// =========================
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
              color: const Color(0xFFF4D2A8),
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
                    color: const Color(0xFFEBC08F),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
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
                        ...widget.attachments.map((file) {
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

                          return ChatAttachmentWidget.buildAttachment(context, {
                            "url": url,
                            "type": type,
                            "name": name,
                          });
                        }).toList(),
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

  /// =========================
  /// CHAT MESSAGE
  /// ======================
  Widget _buildMessage(Map<String, dynamic> message) {
    final isMe = message["isMe"];

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
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryPalette[100],
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppColors.primaryPalette[600],
                ),
              ),
            ),

          /// Chat bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primaryPalette[500] : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              message["text"],
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Widget _buildMessage(Map<String, dynamic> message) {
  //   final isMe = message["isMe"];

  //   return Padding(
  //     padding: EdgeInsets.only(
  //       left: isMe ? 80 : 16,
  //       right: isMe ? 16 : 80,
  //       bottom: 12,
  //     ),
  //     child: Align(
  //       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
  //       child: Container(
  //         constraints: BoxConstraints(
  //           maxWidth: MediaQuery.of(context).size.width * 0.65,
  //         ),
  //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  //         decoration: BoxDecoration(
  //           color: isMe ? AppColors.primaryPalette[500] : Colors.white,
  //           borderRadius: BorderRadius.circular(14),
  //         ),
  //         child: Text(
  //           message["text"],
  //           style: TextStyle(
  //             color: isMe ? Colors.white : Colors.black,
  //             fontSize: 14,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  /// =========================
  /// INPUT BAR
  /// =========================
  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          child: Row(
            children: [
              InkWell(
                onTap: _generateQuiz,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPalette[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    TablerIcons.brain,
                    color: AppColors.primaryPalette[600],
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryPalette[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Aa...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                      if (hasText)
                        IconButton(
                          icon: Icon(TablerIcons.send, color: AppColors.white),
                          onPressed: _sendMessage,
                        ),
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

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildPostCard(),
                const SizedBox(height: 10),
                ...messages.map((msg) => _buildMessage(msg)).toList(),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}
