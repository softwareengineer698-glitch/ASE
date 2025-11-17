// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../auth/sign_in_screen.dart';

// class DonorHomePage extends StatelessWidget {
//   const DonorHomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () => _showExitDialog(context),
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Donor Dashboard'),
//           backgroundColor: Colors.green,
//           foregroundColor: Colors.white,
//           automaticallyImplyLeading: false, // Remove back button
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.logout),
//               onPressed: () => _showLogoutDialog(context),
//             ),
//           ],
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Welcome Card
//               Card(
//                 elevation: 4,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           CircleAvatar(
//                             backgroundColor: Colors.green,
//                             radius: 30,
//                             child: Text(
//                               'D',
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Welcome, Donor!',
//                                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.green,
//                                 ),
//                               ),
//                               Text(
//                                 user?.email ?? '',
//                                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color: Colors.green.shade100,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text(
//                                   'DONOR',
//                                   style: TextStyle(
//                                     color: Colors.green.shade700,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Quick Actions
//             Text(
//               'Quick Actions',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             GridView.count(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               crossAxisCount: 2,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               children: [
//                 _buildActionCard(
//                   context,
//                   'Make Donation',
//                   Icons.volunteer_activism,
//                   Colors.green,
//                   () => _showFeatureComingSoon(context),
//                 ),
//                 _buildActionCard(
//                   context,
//                   'Find NGOs',
//                   Icons.search,
//                   Colors.blue,
//                   () => _showFeatureComingSoon(context),
//                 ),
//                 _buildActionCard(
//                   context,
//                   'Donation History',
//                   Icons.history,
//                   Colors.orange,
//                   () => _showFeatureComingSoon(context),
//                 ),
//                 _buildActionCard(
//                   context,
//                   'My Profile',
//                   Icons.person,
//                   Colors.purple,
//                   () => _showFeatureComingSoon(context),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),

//             // Recent Activity
//             Text(
//               'Recent Activity',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     const Icon(
//                       Icons.inbox_outlined,
//                       size: 48,
//                       color: Colors.grey,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'No recent activity',
//                       style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Start making donations to see your activity here',
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: Colors.grey[500],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionCard(
//     BuildContext context,
//     String title,
//     IconData icon,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return Card(
//       elevation: 2,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(8),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 48,
//                 color: color,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 title,
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Logout'),
//           content: const Text('Are you sure you want to logout?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Logout'),
//             ),
//           ],
//         ],
//       ),
//       ), // Close WillPopScope child (Scaffold)
//     ); // Close WillPopScope
//   }

//   // Show exit confirmation dialog
//   Future<bool> _showExitDialog(BuildContext context) async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Exit App'),
//         content: const Text('Do you really want to exit?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: const Text('No'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(true);
//               SystemNavigator.pop(); // Exit the app
//             },
//             child: const Text('Yes'),
//           ),
//         ],
//       ),
//     ) ?? false;
//   }

//   // Show logout confirmation dialog
//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(builder: (context) => const SignInScreen()),
//                 (route) => false,
//               );
//             },
//             child: const Text('Logout'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showFeatureComingSoon(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('This feature is coming soon!'),
//         backgroundColor: Colors.blue,
//       ),
//     );
//   }
// }
