import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final dynamic t;
  const ProfileScreen({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
        const SizedBox(height: 12),
        Center(child: Text(t.profileName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
        const Center(child: Text('Darkmintis', style: TextStyle(fontSize: 16, color: Colors.grey))),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(leading: const Icon(Icons.person), title: Text(t.profileName), trailing: const Text('Dipesh Mahat', style: TextStyle(color: Colors.grey))),
              const Divider(height: 1),
              ListTile(leading: const Icon(Icons.email), title: Text(t.profileEmail), trailing: const Text('dipesh@darkmintis.com', style: TextStyle(color: Colors.grey))),
              const Divider(height: 1),
              ListTile(leading: const Icon(Icons.calendar_today), title: Text(t.profileMemberSince(date: '2024'))),
            ],
          ),
        ),
      ],
    );
  }
}
