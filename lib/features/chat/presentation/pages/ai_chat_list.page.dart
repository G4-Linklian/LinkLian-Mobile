// import 'package:LinkLian/core/constants/colors.dart';
// import 'package:LinkLian/features/chat/presentation/pages/ai_chat_detail.page.dart';
// import 'package:LinkLian/features/shared/repositories/ai_chat_repository.dart';
// import 'package:flutter/material.dart';

// class AIChatListPage extends StatefulWidget {
//   const AIChatListPage({super.key});

//   @override
//   State<AIChatListPage> createState() => _AIChatListPageState();
// }

// class _AIChatListPageState extends State<AIChatListPage> {
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _searchFocus = FocusNode();

//   List<Map<String, dynamic>> chats = [];
//   List<Map<String, dynamic>> filteredChats = [];

//   final AIChatRepository _repo = AIChatRepository();

//   @override
//   void initState() {
//     super.initState();
//     loadChats();

//     _searchController.addListener(() {
//       setState(() {});
//     });
//   }
//   Future<void> loadChats() async {
//   try {
//     final result = await _repo.getAIChats();

//     setState(() {
//       chats = result;
//       filteredChats = result;
//     });
//   } catch (e) {
//     print(e);
//   }
// }
//   void _onSearchChanged(String value) {
//     setState(() {
//       filteredChats = chats
//          .where((chat) =>
//   (chat["chat_title"] ?? "")
//       .toLowerCase()
//       .contains(value.toLowerCase()))
//           .toList();
//     });
//   }

//   void _resetSearch() {
//     _searchFocus.unfocus();

//     setState(() {
//       _searchController.clear();
//       filteredChats = chats;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,

//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         shadowColor: Colors.black.withValues(alpha: 0.1),
//         scrolledUnderElevation: 0,
//         surfaceTintColor: Colors.white,

//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),

//         centerTitle: true,

//         title: const Text(
//           "AI Chat",
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.w600,
//             fontSize: 18,
//           ),
//         ),
//       ),

//       body: Column(
//         children: [
//           const SizedBox(height: 16),

//           _buildSearch(),

//           const SizedBox(height: 10),

//           Expanded(
//             child: filteredChats.isEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.auto_awesome,
//                           size: 64,
//                           color: Colors.grey[300],
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           "ยังไม่มี AI Chat",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 : Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: AppColors.white,
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: ListView.separated(
//                         itemCount: filteredChats.length,

//                         separatorBuilder: (_, __) => const Divider(
//                           height: 1,
//                           thickness: 1,
//                           color: Color(0xFFF0F0F0),
//                           indent: 16,
//                           endIndent: 16,
//                         ),

//                         itemBuilder: (context, index) {
//                           final chat = filteredChats[index];
//                           final title = chat["chat_title"] ?? "AI Chat";
// final summary = chat["summary_text"] ?? "";
// final aiChatId = chat["ai_chat_id"];

//                           return InkWell(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => AIChatDetailPage(
//                                     title: chat,
//                                     aiChatId: index,
//                                     summary: "Summary preview...",
//                                   ),
//                                 ),
//                               );
//                             },

//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 14,
//                               ),

//                               child: Row(
//                                 children: [
//                                   /// AI ICON
//                                   Container(
//                                     width: 50,
//                                     height: 50,
//                                     decoration: BoxDecoration(
//                                       color: AppColors.buttonPalette[100],
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: Icon(
//                                       Icons.auto_awesome,
//                                       color: AppColors.buttonPalette[600],
//                                     ),
//                                   ),

//                                   const SizedBox(width: 14),

//                                   /// TEXT
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           chat,
//                                           style: const TextStyle(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.w600,
//                                             color: Color(0xFF1A1A1A),
//                                           ),
//                                         ),

//                                         const SizedBox(height: 4),

//                                         Text(
//                                           "Summary preview...",
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             color: Colors.grey[600],
//                                           ),
//                                           maxLines: 1,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ],
//                                     ),
//                                   ),

//                                   Icon(
//                                     Icons.chevron_right,
//                                     color: Colors.grey[400],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearch() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: SizedBox(
//         height: 45,
//         child: TextField(
//           controller: _searchController,
//           focusNode: _searchFocus,
//           onChanged: _onSearchChanged,

//           decoration: InputDecoration(
//             hintText: "ค้นหา AI Chat...",
//             hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),

//             prefixIcon: Icon(
//               Icons.search,
//               color: AppColors.buttonPalette[600],
//               size: 22,
//             ),

//             suffixIcon: _searchController.text.isNotEmpty
//                 ? IconButton(
//                     icon: const Icon(Icons.close, size: 20),
//                     color: AppColors.buttonPalette[600],
//                     onPressed: _resetSearch,
//                   )
//                 : null,

//             filled: true,
//             fillColor: AppColors.buttonPalette[100]!.withValues(alpha: 0.2),

//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(30),
//               borderSide: BorderSide(
//                 color: AppColors.buttonPalette[300]!,
//                 width: 1.2,
//               ),
//             ),

//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(30),
//               borderSide: BorderSide(
//                 color: AppColors.buttonPalette[300]!,
//                 width: 1.2,
//               ),
//             ),

//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 12,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:LinkLian/core/constants/colors.dart';
import 'package:LinkLian/features/chat/presentation/pages/ai_chat_detail.page.dart';
import 'package:LinkLian/features/shared/repositories/ai_chat_repository.dart';
import 'package:flutter/material.dart';

class AIChatListPage extends StatefulWidget {
  const AIChatListPage({super.key});

  @override
  State<AIChatListPage> createState() => _AIChatListPageState();
}

class _AIChatListPageState extends State<AIChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> filteredChats = [];

  final AIChatRepository _repo = AIChatRepository();

  @override
  void initState() {
    super.initState();
    loadChats();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> loadChats() async {
    try {
      final result = await _repo.getAIChats();

      setState(() {
        chats = result;
        filteredChats = result;
      });
    } catch (e) {
      print(e);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      filteredChats = chats
          .where(
            (chat) => (chat["chat_title"] ?? "").toLowerCase().contains(
              value.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  void _resetSearch() {
    _searchFocus.unfocus();

    setState(() {
      _searchController.clear();
      filteredChats = chats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),

        centerTitle: true,

        title: const Text(
          "AI Chat",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),

      body: Column(
        children: [
          const SizedBox(height: 16),

          _buildSearch(),

          const SizedBox(height: 10),

          Expanded(
            child: filteredChats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "ยังไม่มี AI Chat",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        itemCount: filteredChats.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF0F0F0),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];

                          final title = chat["chat_title"] ?? "AI Chat";
                          final summary = chat["summary_text"] ?? "";
                          final aiChatId = chat["ai_chat_id"];

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AIChatDetailPage(
                                    title: title,
                                    aiChatId: aiChatId,
                                    summary: summary,
                                    content: chat["content"] ?? "",
                                    attachments: chat["attachments"] ?? [],
                                    // className: chat["class_name"] ?? "",
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  /// AI ICON
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.buttonPalette[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.auto_awesome,
                                      color: AppColors.buttonPalette[600],
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  /// TEXT
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          summary,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 45,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: "ค้นหา AI Chat...",
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),

            prefixIcon: Icon(
              Icons.search,
              color: AppColors.buttonPalette[600],
              size: 22,
            ),

            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.buttonPalette[600],
                    onPressed: _resetSearch,
                  )
                : null,

            filled: true,
            fillColor: AppColors.buttonPalette[100]!.withValues(alpha: 0.2),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: AppColors.buttonPalette[300]!,
                width: 1.2,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: AppColors.buttonPalette[300]!,
                width: 1.2,
              ),
            ),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }
}
