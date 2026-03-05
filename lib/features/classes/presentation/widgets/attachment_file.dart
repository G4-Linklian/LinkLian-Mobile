import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import '../../../../core/constants/colors.dart';

class AttachmentTile extends StatelessWidget {
  final Map<String, dynamic> file;
  final VoidCallback onRemove;

  const AttachmentTile({super.key, required this.file, required this.onRemove});

  bool get isLink => file['file_type'] == 'link';

  @override
  Widget build(BuildContext context) {
    if (isLink) {
      return _CompactLinkAttachmentTile(file: file, onRemove: onRemove);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file['file_name'] ?? 'ไฟล์แนบ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(file['file_size'] ?? 0),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  String _formatFileSize(dynamic bytes) {
    if (bytes == null || bytes == 0) return '';
    final size = bytes is int ? bytes : int.tryParse(bytes.toString()) ?? 0;
    if (size == 0) return '';
    final mb = size / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Compact Link Attachment Tile for create post (Row layout, preview left)
class _CompactLinkAttachmentTile extends StatefulWidget {
  final Map<String, dynamic> file;
  final VoidCallback onRemove;

  const _CompactLinkAttachmentTile({required this.file, required this.onRemove});

  @override
  State<_CompactLinkAttachmentTile> createState() => _CompactLinkAttachmentTileState();
}

class _CompactLinkAttachmentTileState extends State<_CompactLinkAttachmentTile> {
  Metadata? _metadata;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    try {
      final url = widget.file['file_url'] as String?;
      if (url == null || url.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final data = await MetadataFetch.extract(url);
      if (mounted) {
        setState(() {
          _metadata = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openLink() async {
    final url = widget.file['file_url'] as String?;
    if (url == null || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      bool launched = false;
      
      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (launched) return;
      } catch (e) {
        debugPrint('⚠️ platformDefault failed: $e');
      }
      
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) return;
        } catch (e) {
          debugPrint('⚠️ externalApplication failed: $e');
        }
      }
      
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          if (launched) return;
        } catch (e) {
          debugPrint('⚠️ inAppBrowserView failed: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error opening link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.file['file_url'] as String? ?? '';

    return GestureDetector(
      onTap: _openLink,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryPalette[200]!),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPalette[100]!.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Preview Image (Compact)
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[50],
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 1.5))
                  : _metadata?.image != null && _metadata!.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                          child: Image.network(
                            _metadata!.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.link, size: 28, color: AppColors.primaryPalette[300]),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.link, size: 28, color: AppColors.primaryPalette[300]),
                        ),
            ),

            // Title & URL
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, size: 12, color: AppColors.primaryPalette[600]),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _metadata?.title ?? 'ลิงก์',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: AppColors.primaryPalette[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      url,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.primaryPalette[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: widget.onRemove,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
