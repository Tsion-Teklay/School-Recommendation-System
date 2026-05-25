import 'package:flutter/material.dart';  
import '../data/achievement_dtos.dart';  
  
class AchievementReviewDialog extends StatefulWidget {  
  final Achievement achievement;  
  const AchievementReviewDialog({super.key, required this.achievement});  
  
  @override  
  State<AchievementReviewDialog> createState() => _AchievementReviewDialogState();  
}  
  
class _AchievementReviewDialogState extends State<AchievementReviewDialog> {  
  String _decision = 'APPROVED';  
  final _notesCtrl = TextEditingController();  
  
  @override  
  void dispose() {  
    _notesCtrl.dispose();  
    super.dispose();  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return AlertDialog(  
      title: Text('Review: ${widget.achievement.title}'),  
      content: ConstrainedBox(  
        constraints: const BoxConstraints(maxWidth: 480),  
        child: Column(  
          mainAxisSize: MainAxisSize.min,  
          crossAxisAlignment: CrossAxisAlignment.start,  
          children: [  
            Text('Tier: ${widget.achievement.tier} (${widget.achievement.score} pts)'),  
            Text('Year: ${widget.achievement.year}'),  
            if (widget.achievement.description != null) ...[  
              const SizedBox(height: 8),  
              Text('Description: ${widget.achievement.description}'),  
            ],  
            const SizedBox(height: 16),  
            SegmentedButton<String>(  
              segments: const [  
                ButtonSegment(value: 'APPROVED', label: Text('Approve')),  
                ButtonSegment(value: 'REJECTED', label: Text('Reject')),  
              ],  
              selected: {_decision},  
              onSelectionChanged: (s) => setState(() => _decision = s.first),  
            ),  
            const SizedBox(height: 12),  
            TextField(  
              controller: _notesCtrl,  
              decoration: const InputDecoration(  
                labelText: 'Review notes (optional)',  
              ),  
              minLines: 2,  
              maxLines: 5,  
            ),  
          ],  
        ),  
      ),  
      actions: [  
        TextButton(  
          onPressed: () => Navigator.of(context).pop(),  
          child: const Text('Cancel'),  
        ),  
        FilledButton(  
          onPressed: () => Navigator.of(context).pop(  
            (status: _decision, notes: _notesCtrl.text.trim()),  
          ),  
          child: const Text('Submit decision'),  
        ),  
      ],  
    );  
  }  
}