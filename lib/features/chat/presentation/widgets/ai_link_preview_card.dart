import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:LinkLian/core/constants/colors.dart';

class AILinkPreviewCard extends StatefulWidget {
  final String url;

  const AILinkPreviewCard({super.key, required this.url});

  @override
  State<AILinkPreviewCard> createState() => _AILinkPreviewCardState();
}

class _AILinkPreviewCardState extends State<AILinkPreviewCard> {
  Metadata? metadata;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMetadata();
  }

  Future<void> fetchMetadata() async {
    try {
      final data = await MetadataFetch.extract(widget.url);

      if (mounted) {
        setState(() {
          metadata = data;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> openLink() async {
    final uri = Uri.parse(widget.url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: openLink,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryPalette[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryPalette[50],
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : metadata?.image != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                          child: Image.network(
                            metadata!.image!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.link, size: 30),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata?.title ?? "ลิงก์",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.url,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryPalette[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.open_in_new, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}