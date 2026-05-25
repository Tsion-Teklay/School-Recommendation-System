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
  String? _selectedTier;
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
            Text('Year: ${widget.achievement.year}'),
            if (widget.achievement.description != null) ...[
              const SizedBox(height: 8),
              Text('Description: ${widget.achievement.description}'),
            ],
            if (widget.achievement.documents != null && widget.achievement.documents!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Submitted Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...widget.achievement.documents!.map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.description, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doc.split('/').last,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              )),
            ],  
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'APPROVED', label: Text('Approve')),
                ButtonSegment(value: 'REJECTED', label: Text('Reject')),
              ],
              selected: {_decision},
              onSelectionChanged: (s) => setState(() {
                _decision = s.first;
                if (_decision == 'REJECTED') {
                  _selectedTier = null;
                }
              }),
            ),
            if (_decision == 'APPROVED') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedTier,
                decoration: const InputDecoration(
                  labelText: 'Assign Tier *',
                  hintText: 'Select achievement tier',
                ),
                items: const [
                  DropdownMenuItem(value: 'GOLD', child: Text('Gold (100 pts)')),
                  DropdownMenuItem(value: 'SILVER', child: Text('Silver (50 pts)')),
                  DropdownMenuItem(value: 'BRONZE', child: Text('Bronze (25 pts)')),
                ],
                onChanged: (v) => setState(() => _selectedTier = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ],  
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
          onPressed: () {
            if (_decision == 'APPROVED' && _selectedTier == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a tier when approving')),
              );
              return;
            }
            Navigator.of(context).pop(
              (status: _decision, notes: _notesCtrl.text.trim(), tier: _selectedTier),
            );
          },  
          child: const Text('Submit decision'),  
        ),  
      ],  
    );  
  }  
}