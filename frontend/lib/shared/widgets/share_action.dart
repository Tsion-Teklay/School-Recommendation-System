import 'package:flutter/material.dart';
import 'dart:html' as html;

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
      // Try Web Share API first
      if (html.window.navigator.share != null) {
        await html.window.navigator.share({
          'title': title,
          'text': content,
          'url': url,
        });
      } else {
        // Fallback: copy to clipboard
        await html.window.navigator.clipboard?.writeText(shareText);
        _showClipboardMessage(context);
      }
    } catch (e) {
      // If sharing fails, fallback to clipboard
      await html.window.navigator.clipboard?.writeText(shareText);
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
