import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareAction extends StatelessWidget {
  final String title;
  final String content;
  final String url;

  const ShareAction({
    super.key,
    required this.title,
    required this.content,
    required this.url,
  });

  Future<void> _share(BuildContext context) async {
    final shareText = '$title\n\n$content\n\n$url';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
        ),
      );
    } catch (e) {
      await Clipboard.setData(
        ClipboardData(text: shareText),
      );

      _showClipboardMessage(context);
    }
  }

  void _showClipboardMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Content copied to clipboard!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: 'Share',
      onPressed: () async {
        await _share(context);
      },
    );
  }
}
