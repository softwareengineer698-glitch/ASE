import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/push_notification_model.dart';
import '../../services/enhanced_notification_service.dart';
import '../../services/notification_service.dart';
import '../../providers/theme_provider.dart';

/// Comprehensive notification settings screen
/// Allows users to customize notification preferences and test notifications
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late EnhancedNotificationService _notificationService;
  late NotificationPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _notificationService = EnhancedNotificationService();
    _preferences = _notificationService.preferences;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notification Settings'),
            actions: [
              IconButton(
                icon: const Icon(Icons.bug_report),
                onPressed: () => _sendTestNotification(),
                tooltip: 'Send Test Notification',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Master Toggle
                _buildMasterToggle(themeProvider),

                const SizedBox(height: 24),

                // General Settings
                _buildGeneralSettings(themeProvider),

                const SizedBox(height: 24),

                // Channel Settings
                _buildChannelSettings(themeProvider),

                const SizedBox(height: 24),

                // Quiet Hours
                _buildQuietHoursSettings(themeProvider),

                const SizedBox(height: 24),

                // Notification Statistics
                _buildNotificationStats(themeProvider),

                const SizedBox(height: 24),

                // Test Section
                _buildTestSection(themeProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMasterToggle(ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Push Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle:
                  const Text('Receive push notifications from CareCircle'),
              value: _preferences.pushNotificationsEnabled,
              onChanged: (value) => _updateMasterToggle(value),
              activeThumbColor: themeProvider.primaryColor,
            ),
            if (!_preferences.pushNotificationsEnabled)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You won\'t receive important updates about surplus donations and pickups.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'General Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Sound'),
              subtitle: const Text('Play sound for notifications'),
              value: _preferences.soundEnabled,
              onChanged: _preferences.pushNotificationsEnabled
                  ? (value) => _updateSoundPreference(value)
                  : null,
              activeThumbColor: themeProvider.primaryColor,
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate device for notifications'),
              value: _preferences.vibrationEnabled,
              onChanged: _preferences.pushNotificationsEnabled
                  ? (value) => _updateVibrationPreference(value)
                  : null,
              activeThumbColor: themeProvider.primaryColor,
            ),
            SwitchListTile(
              title: const Text('Badge Count'),
              subtitle: const Text('Show unread count on app icon'),
              value: _preferences.badgeEnabled,
              onChanged: _preferences.pushNotificationsEnabled
                  ? (value) => _updateBadgePreference(value)
                  : null,
              activeThumbColor: themeProvider.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSettings(ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Notification Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose which types of notifications you want to receive',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ...NotificationChannel.values.map((channel) {
              return _buildChannelTile(channel, themeProvider);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelTile(
      NotificationChannel channel, ThemeProvider themeProvider) {
    final isEnabled = _preferences.channelPreferences[channel] ?? true;
    final canChange = _preferences.pushNotificationsEnabled;

    return ListTile(
      leading: Icon(
        _getChannelIcon(channel),
        color: canChange
            ? (isEnabled ? themeProvider.primaryColor : Colors.grey)
            : Colors.grey[400],
      ),
      title: Text(
        channel.displayName,
        style: TextStyle(
          color: canChange ? null : Colors.grey[400],
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        channel.description,
        style: TextStyle(
          fontSize: 12,
          color: canChange ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      trailing: Switch(
        value: isEnabled,
        onChanged: canChange
            ? (value) => _updateChannelPreference(channel, value)
            : null,
        activeThumbColor: themeProvider.primaryColor,
      ),
    );
  }

  Widget _buildQuietHoursSettings(ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Quiet Hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Silence non-urgent notifications during these hours',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Quiet Hours'),
              value: _preferences.quietHoursEnabled,
              onChanged: _preferences.pushNotificationsEnabled
                  ? (value) => _updateQuietHoursEnabled(value)
                  : null,
              activeThumbColor: themeProvider.primaryColor,
            ),
            if (_preferences.quietHoursEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      'Start Time',
                      _preferences.quietHoursStart,
                      (time) => _updateQuietHoursStart(time),
                      themeProvider,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeSelector(
                      'End Time',
                      _preferences.quietHoursEnd,
                      (time) => _updateQuietHoursEnd(time),
                      themeProvider,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
    String label,
    String currentTime,
    Function(String) onTimeChanged,
    ThemeProvider themeProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectTime(currentTime, onTimeChanged),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time,
                    size: 16, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                Text(currentTime),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationStats(ThemeProvider themeProvider) {
    final stats = _notificationService.getNotificationStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Notification Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    stats['Total']?.toString() ?? '0',
                    Icons.notifications,
                    themeProvider.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Unread',
                    stats['Unread']?.toString() ?? '0',
                    Icons.mark_email_unread,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection(ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: themeProvider.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Test Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _preferences.pushNotificationsEnabled
                    ? () => _sendTestNotification()
                    : null,
                icon: const Icon(Icons.send),
                label: const Text('Send Test Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send a test notification to verify your settings are working correctly.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getChannelIcon(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.general:
        return Icons.info;
      case NotificationChannel.surplus:
        return Icons.inventory;
      case NotificationChannel.pickup:
        return Icons.local_shipping;
      case NotificationChannel.delivery:
        return Icons.check_circle;
      case NotificationChannel.alerts:
        return Icons.warning;
      case NotificationChannel.social:
        return Icons.emoji_events;
      case NotificationChannel.system:
        return Icons.settings;
    }
  }

  void _updateMasterToggle(bool enabled) {
    setState(() {
      _preferences = _preferences.copyWith(pushNotificationsEnabled: enabled);
    });
    _notificationService.savePreferences(_preferences);
    NotificationService().setNotificationsEnabled(enabled);
  }

  void _updateSoundPreference(bool enabled) {
    setState(() {
      _preferences = _preferences.copyWith(soundEnabled: enabled);
    });
    _notificationService.updateSoundPreference(enabled);
  }

  void _updateVibrationPreference(bool enabled) {
    setState(() {
      _preferences = _preferences.copyWith(vibrationEnabled: enabled);
    });
    _notificationService.updateVibrationPreference(enabled);
  }

  void _updateBadgePreference(bool enabled) {
    setState(() {
      _preferences = _preferences.copyWith(badgeEnabled: enabled);
    });
    _notificationService.savePreferences(_preferences);
  }

  void _updateChannelPreference(NotificationChannel channel, bool enabled) {
    setState(() {
      final newChannelPrefs =
          Map<NotificationChannel, bool>.from(_preferences.channelPreferences);
      newChannelPrefs[channel] = enabled;
      _preferences = _preferences.copyWith(channelPreferences: newChannelPrefs);
    });
    _notificationService.updateChannelPreference(channel, enabled);
  }

  void _updateQuietHoursEnabled(bool enabled) {
    setState(() {
      _preferences = _preferences.copyWith(quietHoursEnabled: enabled);
    });
    _notificationService.savePreferences(_preferences);
  }

  void _updateQuietHoursStart(String time) {
    setState(() {
      _preferences = _preferences.copyWith(quietHoursStart: time);
    });
    _notificationService.updateQuietHours(
      startTime: time,
      endTime: _preferences.quietHoursEnd,
      enabled: _preferences.quietHoursEnabled,
    );
  }

  void _updateQuietHoursEnd(String time) {
    setState(() {
      _preferences = _preferences.copyWith(quietHoursEnd: time);
    });
    _notificationService.updateQuietHours(
      startTime: _preferences.quietHoursStart,
      endTime: time,
      enabled: _preferences.quietHoursEnabled,
    );
  }

  Future<void> _selectTime(
      String currentTime, Function(String) onTimeChanged) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final formattedTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      onTimeChanged(formattedTime);
    }
  }

  void _sendTestNotification() {
    _notificationService.sendTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
