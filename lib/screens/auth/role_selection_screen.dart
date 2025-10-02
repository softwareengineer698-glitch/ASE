import 'package:flutter/material.dart';
import 'package:foodbridge/screens/home/ngo_dashboard_simple.dart';
import '../../models/user_model.dart';
import '../home/donor_dashboard.dart';
// import '../home/ngo_dashboard.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add some top spacing for better centering
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                // App Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    size: 50,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                const Text(
                  'Choose Your Role',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Subtitle
                const Text(
                  'Select how you want to use DonateConnect',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Donor Role Card
                _buildRoleCard(
                  context: context,
                  title: 'I\'m a Donor',
                  subtitle: 'I want to donate items to those in need',
                  icon: Icons.favorite,
                  color: Colors.red,
                  onTap: () => _navigateToHome(context, UserRole.donor),
                ),
                const SizedBox(height: 20),

                // NGO Role Card
                _buildRoleCard(
                  context: context,
                  title: 'I\'m an NGO',
                  subtitle: 'I represent an organization helping communities',
                  icon: Icons.business,
                  color: Colors.green,
                  onTap: () => _navigateToHome(context, UserRole.ngo),
                ),
                const SizedBox(height: 40),

                // Back Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Back to Sign In',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),

                // Add bottom spacing for better scrolling
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          minHeight: 100,
        ),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      icon,
                      size: 30,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow Icon
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        )); // closes the ConstrainedBox
  }

  void _navigateToHome(BuildContext context, UserRole role) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => role == UserRole.donor
            ? const DonorDashboard()
            : const NGODashboard(),
      ),
      (route) => false, // Remove all previous routes
    );
  }
}
