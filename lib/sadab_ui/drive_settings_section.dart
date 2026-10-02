import 'package:flutter/material.dart';

/// Google Drive settings placeholder.
///
/// HONEST STATUS: Drive OAuth/upload is NOT implemented. Every control is
/// disabled and labelled "Pending". Implement later with a supported OAuth
/// flow (Android: google_sign_in / Google Identity; Windows: loopback
/// OAuth with PKCE). Never ship client secrets, tokens or service-account
/// keys in the app or repository.
class DriveSettingsSection extends StatelessWidget {
  const DriveSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.cloud_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text('Google Drive', style: t.textTheme.titleMedium)),
              Chip(
                label: const Text('Pending'),
                visualDensity: VisualDensity.compact,
                backgroundColor: t.colorScheme.secondaryContainer,
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              'Drive backup is not available yet. Use Export / Import backup '
              'in the meantime.',
              style: t.textTheme.bodyMedium
                  ?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            const _Row(Icons.account_circle_outlined, 'Owner account', 'Not connected'),
            const _Row(Icons.folder_outlined, 'Backup folder', 'Not configured'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: const [
              FilledButton.tonal(onPressed: null, child: Text('Connect account')),
              OutlinedButton(onPressed: null, child: Text('Upload backup')),
              OutlinedButton(onPressed: null, child: Text('Restore from Drive')),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Flexible(child: Text(value, overflow: TextOverflow.ellipsis)),
        ]),
      );
}
