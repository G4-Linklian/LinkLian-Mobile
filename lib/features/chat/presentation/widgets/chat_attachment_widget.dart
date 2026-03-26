import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

class ChatAttachmentWidget {
  static bool isImage(String? type, String url) {
    if (type == null) return false;

    final t = type.toLowerCase();

    return t.contains("image") ||
        url.endsWith(".jpg") ||
        url.endsWith(".jpeg") ||
        url.endsWith(".png") ||
        url.endsWith(".webp");
  }

  static bool isPdf(String? type, String url) {
    if (type != null && type.toLowerCase().contains("pdf")) {
      return true;
    }
    return url.toLowerCase().endsWith('.pdf');
  }

  static bool isLink(String? type) {
    if (type == null) return false;
    return type.toLowerCase().contains("link");
  }

  static bool isDoc(String? type, String url) {
    return url.endsWith(".doc") || url.endsWith(".docx");
  }

  static bool isExcel(String? type, String url) {
    return url.endsWith(".xls") || url.endsWith(".xlsx");
  }

  static bool isPpt(String? type, String url) {
    return url.endsWith(".ppt") || url.endsWith(".pptx");
  }

  static Future<void> _openAttachmentUrl(
    BuildContext context,
    String rawUrl,
  ) async {
    final normalized = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
    final uri = Uri.tryParse(normalized);

    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ไม่สามารถเปิดไฟล์ได้')));
      }
      return;
    }

    bool launched = false;

    try {
      launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {}

    if (!launched) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    if (!launched) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เปิดไฟล์ไม่สำเร็จ')));
    }
  }

  static Widget _buildFileTile({
    required BuildContext context,
    required String url,
    required Widget leading,
    required String name,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openAttachmentUrl(context, url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildAttachment(BuildContext context, dynamic file) {
    final type = file['type'] ?? file['file_type'];
    final url = file['url'] ?? file['file_url'];
    final name = file['name'] ?? file['original_name'] ?? extractFileName(url);

    if (url == null) return const SizedBox();

    if (isImage(type, url)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(backgroundColor: Colors.black),
                  body: Center(
                    child: InteractiveViewer(child: Image.network(url)),
                  ),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(url, width: 200, fit: BoxFit.cover),
          ),
        ),
      );
    }

    if (isLink(type)) {
      return buildLinkPreview(url);
    }

    if (isPdf(type, url)) {
      return _buildFileTile(
        context: context,
        url: url,
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        name: name,
      );
    }

    if (isDoc(type, url)) {
      return _buildFileTile(
        context: context,
        url: url,
        leading: const Icon(Icons.description, color: Colors.blue),
        name: name,
      );
    }

    if (isExcel(type, url)) {
      return _buildFileTile(
        context: context,
        url: url,
        leading: const Icon(Icons.table_chart, color: Colors.green),
        name: name,
      );
    }

    if (isPpt(type, url)) {
      return _buildFileTile(
        context: context,
        url: url,
        leading: const Icon(Icons.slideshow, color: Colors.orange),
        name: name,
      );
    }

    return _buildFileTile(
      context: context,
      url: url,
      leading: const Icon(Icons.insert_drive_file),
      name: name,
    );
  }

  static String extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final name = uri.pathSegments.last;
      return Uri.decodeComponent(name);
    } catch (e) {
      return url;
    }
  }

  static Widget buildLinkPreview(String url) {
    final link = url.startsWith("http") ? url : "https://$url";
    final fileName = extractFileName(link);

    return FutureBuilder<Metadata?>(
      future: MetadataFetch.extract(link),
      builder: (context, snapshot) {
        final data = snapshot.data;

        final isPdf = fileName.toLowerCase().endsWith(".pdf");
        final isDoc =
            fileName.toLowerCase().endsWith(".doc") ||
            fileName.toLowerCase().endsWith(".docx");

        final isExcel =
            fileName.toLowerCase().endsWith(".xls") ||
            fileName.toLowerCase().endsWith(".xlsx");

        final isPpt =
            fileName.toLowerCase().endsWith(".ppt") ||
            fileName.toLowerCase().endsWith(".pptx");

        return GestureDetector(
          onTap: () async {
            final uri = Uri.parse(link);
            await launchUrl(uri);
          },
          child: Container(
            width: 250,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isPdf && data?.image != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      data!.image!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (isPdf || isDoc || isExcel || isPpt)
                                  ? fileName
                                  : (data?.title ?? fileName),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (!isPdf && data?.description != null)
                              Text(
                                data!.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
