// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../auth/sign_in_screen.dart';
// import '../ngo/surplus_list_screen.dart';
// import '../../services/local_surplus_service.dart';

// class NGODashboard extends StatelessWidget {
//   const NGODashboard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Initialize mock data
//     LocalSurplusService().initializeMockData();

//     return WillPopScope(
//       onWillPop: () => _showExitDialog(context),
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('NGO Dashboard'),
//           backgroundColor: Colors.blue,
//           foregroundColor: Colors.white,
//           automaticallyImplyLeading: false,
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.logout),
//               onPressed: () => _showLogoutDialog(context),
//             ),
//           ],
//         ),
//         body: Column(
//           children: [
//             // Header Section
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.indigo.shade50,
//                 border: Border(
//                   bottom: BorderSide(color: Colors.indigo.shade100),
//                 ),
//               ),
//               body: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Welcome Card
//                     Card(
//                       elevation: 4,
//                       child: Padding(
//                         padding: const EdgeInsets.all(20.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 const Icon(
//                                   Icons.volunteer_activism,
//                                   size: 32,
//                                   color: Colors.blue,
//                                 ),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       const Text(
//                                         'Welcome, NGO Partner!',
//                                         style: TextStyle(
//                                           fontSize: 24,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.blue,
//                                         ),
//                                       ),
//                                       Text(
//                                         'Help collect surplus food and feed communities',
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // Quick Stats
//                     const Text(
//                       'Quick Overview',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildStatCard(
//                             'Available Items',
//                             '${LocalSurplusService().getAvailableSurplusItems().length}',
//                             Icons.inventory,
//                             Colors.green,
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: _buildStatCard(
//                             'Total Items',
//                             '${LocalSurplusService().getAllSurplusItems().length}',
//                             Icons.list_alt,
//                             Colors.blue,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),

//                     // Main Action
//                     const Text(
//                       'Actions',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     _buildMainActionCard(
//                       context,
//                       'View Surplus List',
//                       'Browse and accept available surplus food items',
//                       Icons.list,
//                       Colors.blue,
//                       () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const SurplusListScreen(
//                             ngoName: 'Current NGO', // TODO: Get from auth provider
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Info Card
//                     Card(
//                       elevation: 2,
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Icon(Icons.info, color: Colors.blue[700]),
//                                 const SizedBox(width: 8),
//                                 const Text(
//                                   'How It Works',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),
//                             const Text(
//                               '1. Browse available surplus food items\n'
//                               '2. Accept items that match your needs\n'
//                               '3. Coordinate pickup with donors\n'
//                               '4. Help feed communities in need',
//                               style: TextStyle(fontSize: 14, height: 1.5),
//                             ),
//                           ],
//                         ),
//                       ),
//                 Flexible(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(item.status).withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       item.status.displayName,
//                       style: TextStyle(
//                         color: _getStatusColor(item.status),
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),

//             // Details
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildDetailItem(Icons.category, 'Category', item.category),
//                 ),
//                 Expanded(
//                   child: _buildDetailItem(Icons.scale, 'Quantity', '${item.quantity} ${item.unit}'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: _buildDetailItem(Icons.location_on, 'Location', item.location),
//                 ),
//                 Expanded(
//                   child: _buildDetailItem(
//                     Icons.schedule,
//                     'Expires',
//                     _formatExpiryDate(item.expiryDate),
//                     textColor: item.isExpiringSoon ? Colors.red : null,
//                   ),
//                 ),
//               ],
//             ),
            
//             if (item.description.isNotEmpty) ...[
//               const SizedBox(height: 12),
//               Text(
//                 item.description,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[700],
//                 ),
//               ),
//             ],

//             // Action Button
//             if (item.status == SurplusStatus.available) ...[
//               const SizedBox(height: 16),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: () => _reserveItem(item),
//                   icon: const Icon(Icons.bookmark_add),
//                   label: const Text('Reserve Item'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.indigo,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailItem(IconData icon, String label, String value, {Color? textColor}) {
//     return Row(
//       children: [
//         Icon(icon, size: 16, color: Colors.grey[600]),
//         const SizedBox(width: 4),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: Colors.grey[500],
//                   fontWeight: FontWeight.w500,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: textColor ?? Colors.grey[800],
//                 ),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Color _getStatusColor(SurplusStatus status) {
//     switch (status) {
//       case SurplusStatus.available:
//         return Colors.green;
//       case SurplusStatus.reserved:
//         return Colors.orange;
//       case SurplusStatus.collected:
//         return Colors.blue;
//       case SurplusStatus.expired:
//         return Colors.red;
//     }
//   }

//   String _formatExpiryDate(DateTime expiryDate) {
//     final now = DateTime.now();
//     final difference = expiryDate.difference(now);
    
//     if (difference.inDays > 0) {
//       return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
//     } else {
//       return 'Expired';
//     }
//   }

//   void _reserveItem(SurplusItem item) {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Reserve Item'),
//         content: Text('Do you want to reserve "${item.itemName}" from ${item.donorName}?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(dialogContext).pop(),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.of(dialogContext).pop();
              
//               // Check if widget is still mounted before proceeding
//               if (!mounted) return;
              
//               // Show loading
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Reserving item...')),
//               );
              
//               try {
//                 // Simulate reservation
//                 final success = await MockDataService.reserveSurplus(item.id);
                
//                 // Check if widget is still mounted after async operation
//                 if (!mounted) return;
                
//                 if (success) {
//                   setState(() {
//                     final index = surplusItems.indexWhere((i) => i.id == item.id);
//                     if (index != -1) {
//                       surplusItems[index] = SurplusItem(
//                         id: item.id,
//                         donorName: item.donorName,
//                         itemName: item.itemName,
//                         category: item.category,
//                         quantity: item.quantity,
//                         unit: item.unit,
//                         expiryDate: item.expiryDate,
//                         location: item.location,
//                         description: item.description,
//                         status: SurplusStatus.reserved,
//                         createdAt: item.createdAt,
//                       );
//                     }
//                   });
                  
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Successfully reserved "${item.itemName}"'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Failed to reserve item. Please try again.'),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               } catch (e) {
//                 // Check if widget is still mounted before showing error
//                 if (!mounted) return;
                
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Error: ${e.toString()}'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             child: const Text('Reserve'),
//           ),
//         ],
//       ),
//     );
//   }

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
//               SystemNavigator.pop();
//             },
//             child: const Text('Yes'),
//           ),
//         ],
//       ),
//     ) ?? false;
//   }

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
// }
