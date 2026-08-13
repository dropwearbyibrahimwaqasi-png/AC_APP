import 'package:flutter/material.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 30)),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assistant Commissioner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Field Activity Tracker', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _settingsTile(context, Icons.settings_outlined, 'App Settings'),
          _settingsTile(context, Icons.location_on_outlined, 'Tracking Settings'),
          _settingsTile(context, Icons.notifications_outlined, 'Reminders Settings'),
          _settingsTile(context, Icons.help_outline, 'Help & Support'),
          _settingsTile(context, Icons.info_outline, 'About App'),
        ],
      ),
    );
  }

  Widget _settingsTile(BuildContext context, IconData icon, String label) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label — not built yet')),
          );
        },
      ),
    );
  }
}
