import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/reminder.dart';
import '../services/api_service.dart';

class FollowUpScreen extends StatefulWidget {
  final Reminder reminder;
  const FollowUpScreen({super.key, required this.reminder});

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  final _noteController = TextEditingController();
  final ApiService _api = ApiService();
  DateTime? _nextDate;
  XFile? _photo;
  Uint8List? _photoBytes;
  bool _saving = false;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (mounted) setState(() { _photo = picked; _photoBytes = bytes; });
    }
  }

  Future<void> _pickNextDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _nextDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.submitFollowUp(
        reminderId: widget.reminder.id,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        photoPath: _photo?.path,
        nextReminderAt: _nextDate,
        nextReminderDescription: _nextDate != null ? 'Follow-up: ${widget.reminder.description}' : null,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final r = widget.reminder;
    return Scaffold(
      appBar: AppBar(title: const Text('Follow-up')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.notifications)),
            title: Text(r.description, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${_two(r.remindAt.hour)}:${_two(r.remindAt.minute)}  •  '
              '${r.remindAt.year}-${_two(r.remindAt.month)}-${_two(r.remindAt.day)}'
              '${r.location != null ? '\n${r.location}' : ''}',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Outcome / Notes', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write meeting outcome or notes...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Add Photo (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickPhoto,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _photo == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined),
                          SizedBox(height: 4),
                          Text('Tap to capture or upload photo'),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_photoBytes!, fit: BoxFit.cover, width: double.infinity),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Next Meeting (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickNextDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(_nextDate == null
                ? 'Select date'
                : '${_nextDate!.year}-${_two(_nextDate!.month)}-${_two(_nextDate!.day)}'),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text('Save Follow-up'),
          ),
        ],
      ),
    );
  }
}
