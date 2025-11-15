import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

/// Screen for customizing app theme and appearance settings
/// Allows users to choose theme variants and brightness modes
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme & Appearance'),
        elevation: 0,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          if (themeProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Mode Section
                _buildSectionHeader('Brightness Mode'),
                const SizedBox(height: 12),
                _buildThemeModeSelector(context, themeProvider),
                
                const SizedBox(height: 32),
                
                // Theme Variant Section
                _buildSectionHeader('Color Theme'),
                const SizedBox(height: 12),
                _buildThemeVariantSelector(context, themeProvider),
                
                const SizedBox(height: 32),
                
                // Preview Section
                _buildSectionHeader('Preview'),
                const SizedBox(height: 12),
                _buildPreviewSection(context, themeProvider),
                
                const SizedBox(height: 32),
                
                // Reset Button
                _buildResetButton(context, themeProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThemeModeSelector(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: themeProvider.availableThemeModes.map((mode) {
            final isSelected = themeProvider.themeMode == mode['value'];
            
            return ListTile(
              leading: Icon(
                mode['icon'] as IconData,
                color: isSelected ? themeProvider.primaryColor : null,
              ),
              title: Text(mode['name'] as String),
              trailing: isSelected 
                ? Icon(
                    Icons.check_circle,
                    color: themeProvider.primaryColor,
                  )
                : null,
              onTap: () => themeProvider.setThemeMode(mode['value'] as ThemeMode),
              selected: isSelected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildThemeVariantSelector(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3,
          ),
          itemCount: themeProvider.availableThemes.length,
          itemBuilder: (context, index) {
            final theme = themeProvider.availableThemes[index];
            final isSelected = themeProvider.currentTheme == theme['value'];
            final primaryColor = AppTheme.getPrimaryColor(theme['value']!);
            
            return InkWell(
              onTap: () => themeProvider.setThemeVariant(theme['value']!),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Color indicator
                    Container(
                      width: 4,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Theme name
                    Expanded(
                      child: Text(
                        theme['name']!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? primaryColor : null,
                        ),
                      ),
                    ),
                    // Selection indicator
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: primaryColor,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Sample UI elements
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Primary Button'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outlined Button'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sample card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeProvider.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        color: themeProvider.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sample Donation Card',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeProvider.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('This is how cards will look with the selected theme.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, ThemeProvider themeProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showResetDialog(context, themeProvider),
        icon: const Icon(Icons.refresh),
        label: const Text('Reset to Default'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Theme'),
        content: const Text(
          'Are you sure you want to reset the theme to default settings? '
          'This will change the theme to Ocean Blue with system brightness.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              themeProvider.resetTheme();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Theme reset to default'),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
