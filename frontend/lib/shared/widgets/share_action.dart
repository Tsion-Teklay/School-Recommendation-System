import 'package:flutter/material.dart';  
import 'package:share/share.dart' as share;  
  
class ShareAction extends StatelessWidget {  
  final String title;  
  final String content;  
  final String url;  
  const ShareAction({super.key, required this.title, required this.content, required this.url});  
  
  @override  
  Widget build(BuildContext context) {  
    return IconButton(  
      icon: const Icon(Icons.share),  
      onPressed: () => share.Share.share(  
        '$title\n\n$content\n\n$url',  
        subject: title,  
      ),  
      tooltip: 'Share',  
    );  
  }  
}