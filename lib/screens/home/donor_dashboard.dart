// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../../providers/auth_provider.dart';
// import '../../providers/theme_provider.dart';
// import '../../services/surplus_service.dart';
// import '../../models/surplus_report_model.dart';
// import '../../models/user_model.dart';
// import '../../widgets/dashboard_card.dart';
// import '../../widgets/custom_button.dart';
// import '../auth/sign_in_screen.dart';
// import '../forecast/forecast_dashboard.dart';
// import '../donor/create_surplus_screen.dart';
// import '../history/history_screen.dart';
// import '../notifications/notifications_screen.dart';

// class DonorDashboard extends StatefulWidget {
//   const DonorDashboard({super.key});

//   @override
//   State<DonorDashboard> createState() => _DonorDashboardState();
// }

// class _DonorDashboardState extends State<DonorDashboard> {
//   final SurplusService _surplusService = SurplusService();

//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<AuthProvider, ThemeProvider>(
//       builder: (context, authProvider, themeProvider, child) {
//         final user = authProvider.user;
//         final theme = Theme.of(context);
//         final colorScheme = theme.colorScheme;

//         if (user == null) {
//           return const SignInScreen();
//         }

//         return Scaffold(
//           backgroundColor: colorScheme.background,
//           body: SafeArea(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // 1. Header Section
//                   _buildHeaderSection(user, colorScheme),
//                   const SizedBox(height: 24),

//                   // 2. Quick Stats Dashboard Cards
//                   _buildQuickStatsSection(colorScheme),
//                   const SizedBox(height: 24),

//                   // 3. Forecast Section
//                   _buildForecastSection(context, colorScheme),
//                   const SizedBox(height: 24),

//                   // 4. Main Actions
//                   _buildMainActionsSection(context, colorScheme),
//                   const SizedBox(height: 24),

//                   // 5. Active Surplus List
//                   _buildActiveSurplusSection(colorScheme),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // 1. Header Section
//   Widget _buildHeaderSection(UserModel user, ColorScheme colorScheme) {
//     return DashboardCard(
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: colorScheme.primary.withOpacity(0.1),
//             child: Icon(
//               Icons.person,
//               size: 30,
//               color: colorScheme.primary,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Hello, ${user.name} 👋',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: colorScheme.onSurface,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Ready to help reduce food waste today?',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 2. Quick Stats Dashboard Cards
//   Widget _buildQuickStatsSection(ColorScheme colorScheme) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Today\'s Overview',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: colorScheme.onSurface,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: MetricCard(
//                 title: 'Surplus Risk',
//                 value: 'High',
//                 icon: Icons.warning,
//                 iconColor: Colors.orange,
//                 subtitle: 'Check forecast',
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: MetricCard(
//                 title: 'This Month',
//                 value: '12',
//                 icon: Icons.restaurant,
//                 iconColor: Colors.green,
//                 subtitle: 'Food donated',
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: MetricCard(
//                 title: 'Meals Helped',
//                 value: '156',
//                 icon: Icons.people,
//                 iconColor: Colors.blue,
//                 subtitle: 'People fed',
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: MetricCard(
//                 title: 'Pending',
//                 value: '3',
//                 icon: Icons.schedule,
//                 iconColor: Colors.purple,
//                 subtitle: 'Pickups waiting',
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   // 3. Forecast Section
//   Widget _buildForecastSection(BuildContext context, ColorScheme colorScheme) {
//     return DashboardCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.analytics, color: colorScheme.primary),
//               const SizedBox(width: 8),
//               Text(
//                 '📊 Demand Forecast',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: colorScheme.onSurface,
//                 ),
//               ),
//               const Spacer(),
//               TextButton(
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const ForecastDashboard()),
//                 ),
//                 child: const Text('View Full'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Container(
//             height: 120,
//             child: _buildMiniChart(colorScheme),
//           ),
//           const SizedBox(height: 12),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.orange.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.orange.withOpacity(0.3)),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.warning, color: Colors.orange, size: 20),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Surplus Alert: High demand expected tomorrow',
//                     style: TextStyle(
//                       color: Colors.orange[800],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 4. Main Actions
//   Widget _buildMainActionsSection(BuildContext context, ColorScheme colorScheme) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Quick Actions',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: colorScheme.onSurface,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: QuickActionCard(
//                 title: 'Report Surplus',
//                 subtitle: 'Add new surplus',
//                 icon: Icons.add_circle,
//                 iconColor: Colors.green,
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const CreateSurplusScreen()),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: QuickActionCard(
//                 title: 'View History',
//                 subtitle: 'Past donations',
//                 icon: Icons.history,
//                 iconColor: Colors.blue,
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const HistoryScreen()),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         CustomButton(
//           text: '🔔 Notifications',
//           icon: Icons.notifications,
//           fullWidth: true,
//           variant: ButtonVariant.outlined,
//           onPressed: () => Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => const NotificationsScreen()),
//           ),
//         ),
//       ],
//     );
//   }

//   // 5. Active Surplus List
//   Widget _buildActiveSurplusSection(ColorScheme colorScheme) {
//     final mockSurplus = _generateMockSurplus();
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               'Active Surplus',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: colorScheme.onSurface,
//               ),
//             ),
//             const Spacer(),
//             TextButton(
//               onPressed: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const HistoryScreen()),
//               ),
//               child: const Text('View All'),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         ...mockSurplus.map((surplus) => _buildSurplusCard(surplus, colorScheme)),
//       ],
//     );
//   }

//   Widget _buildSurplusCard(Map<String, dynamic> surplus, ColorScheme colorScheme) {
//     return DashboardCard(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(surplus['status']).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(
//                   Icons.restaurant,
//                   color: _getStatusColor(surplus['status']),
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       surplus['foodName'],
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: colorScheme.onSurface,
//                       ),
//                     ),
//                     Text(
//                       'Quantity: ${surplus['quantity']}',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: colorScheme.onSurfaceVariant,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(surplus['status']).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   surplus['status'],
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: _getStatusColor(surplus['status']),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (surplus['ngoName'] != null) ...[
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(Icons.business, size: 16, color: colorScheme.onSurfaceVariant),
//                 const SizedBox(width: 4),
//                 Text(
//                   'NGO: ${surplus['ngoName']}',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//                 const Spacer(),
//                 if (surplus['eta'] != null)
//                   Text(
//                     'ETA: ${surplus['eta']}',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: colorScheme.onSurfaceVariant,
//                     ),
//                   ),
//               ],
//             ),
//           ],
//           if (surplus['status'] == 'Accepted') ...[
//             const SizedBox(height: 12),
//             CustomButton(
//               text: 'Track Pickup',
//               icon: Icons.location_on,
//               size: ButtonSize.small,
//               variant: ButtonVariant.tonal,
//               onPressed: () => _showTrackingDialog(context, surplus),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildMiniChart(ColorScheme colorScheme) {
//     return LineChart(
//       LineChartData(
//         gridData: FlGridData(show: false),
//         titlesData: FlTitlesData(show: false),
//         borderData: FlBorderData(show: false),
//         lineBarsData: [
//           LineChartBarData(
//             spots: [
//               FlSpot(0, 3),
//               FlSpot(1, 1),
//               FlSpot(2, 4),
//               FlSpot(3, 2),
//               FlSpot(4, 5),
//               FlSpot(5, 3),
//               FlSpot(6, 4),
//             ],
//             isCurved: true,
//             color: colorScheme.primary,
//             barWidth: 3,
//             dotData: FlDotData(show: false),
//             belowBarData: BarAreaData(
//               show: true,
//               color: colorScheme.primary.withOpacity(0.1),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'Available':
//         return Colors.green;
//       case 'Requested':
//         return Colors.orange;
//       case 'Accepted':
//         return Colors.blue;
//       case 'Collected':
//         return Colors.purple;
//       default:
//         return Colors.grey;
//     }
//   }

//   List<Map<String, dynamic>> _generateMockSurplus() {
//     return [
//       {
//         'foodName': 'Fresh Vegetables',
//         'quantity': '5 kg',
//         'status': 'Accepted',
//         'ngoName': 'Edhi Foundation',
//         'eta': '2:30 PM',
//       },
//       {
//         'foodName': 'Cooked Rice',
//         'quantity': '10 portions',
//         'status': 'Available',
//         'ngoName': null,
//         'eta': null,
//       },
//       {
//         'foodName': 'Bread Loaves',
//         'quantity': '20 pieces',
//         'status': 'Requested',
//         'ngoName': 'Saylani Welfare',
//         'eta': '4:00 PM',
//       },
//     ];
//   }

//   void _showTrackingDialog(BuildContext context, Map<String, dynamic> surplus) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Tracking: ${surplus['foodName']}'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: Icon(Icons.check_circle, color: Colors.green),
//               title: Text('Accepted by ${surplus['ngoName']}'),
//               subtitle: Text('10:30 AM'),
//             ),
//             ListTile(
//               leading: Icon(Icons.directions_car, color: Colors.blue),
//               title: Text('On the way'),
//               subtitle: Text('ETA: ${surplus['eta']}'),
//             ),
//             ListTile(
//               leading: Icon(Icons.schedule, color: Colors.grey),
//               title: Text('Pickup pending'),
//               subtitle: Text('Waiting for collection'),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Contact NGO'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
//                   Expanded(
//                     child: _buildMainActionCard(
//                       context,
//                       'Add Surplus',
//                       'Donate your excess food',
//                       Icons.add_circle,
//                       Colors.green,
//                       () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const CreateSurplusScreen(),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: _buildMainActionCard(
//                       context,
//                       'View Forecast',
//                       'See demand predictions',
//                       Icons.analytics,
//                       Colors.blue,
//                       () => Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const ForecastDashboard(),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),

//               // Stats Section
//               const Text(
//                 'Your Impact',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Dynamic Impact Statistics - Using StreamBuilder for real-time updates
//               StreamBuilder<List<SurplusReportModel>>(
//                 stream: _surplusService.getDonorSurplusReports(user.uid),
//                 builder: (context, reportsSnapshot) {
//                   if (reportsSnapshot.connectionState == ConnectionState.waiting) {
//                     return Card(
//                       elevation: 4,
//                       child: Padding(
//                         padding: const EdgeInsets.all(20.0),
//                         child: Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceAround,
//                               children: [
//                                 _buildLoadingStatItem('Items Donated', Icons.inventory, Colors.green),
//                                 _buildLoadingStatItem('People Fed', Icons.people, Colors.blue),
//                                 _buildLoadingStatItem('PKR Saved', Icons.attach_money, Colors.orange),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.green.shade50,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     Icons.eco,
//                                     color: Colors.green.shade700,
//                                     size: 20,
//                                   ),
//                                   const SizedBox(width: 8),
//                                   const Expanded(
//                                     child: Text(
//                                       'Loading your impact statistics...',
//                                       style: TextStyle(
//                                         color: Colors.grey,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }

//                   if (reportsSnapshot.hasError) {
//                     return Card(
//                       elevation: 4,
//                       child: Padding(
//                         padding: const EdgeInsets.all(20.0),
//                         child: Column(
//                           children: [
//                             Icon(Icons.error, size: 48, color: Colors.red[300]),
//                             const SizedBox(height: 8),
//                             Text('Error loading statistics: ${reportsSnapshot.error}'),
//                             const SizedBox(height: 8),
//                             ElevatedButton(
//                               onPressed: () => setState(() {}),
//                               child: const Text('Retry'),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }

//                   // Calculate statistics from the real-time surplus reports
//                   final reports = reportsSnapshot.data ?? [];
//                   final completedItems = reports.where((r) => r.status == 'completed').length;
//                   final completedQuantity = reports
//                       .where((r) => r.status == 'completed')
//                       .fold<double>(0, (sum, report) => sum + report.quantity);
                  
//                   final peopleFed = (completedQuantity * 4).round();
//                   final pkrSaved = (completedQuantity * 150).round();
                  
//                   // Calculate this month's waste reduction
//                   final now = DateTime.now();
//                   final thisMonth = DateTime(now.year, now.month, 1);
//                   final thisMonthQuantity = reports
//                       .where((r) => r.timestamp.isAfter(thisMonth) && r.status == 'completed')
//                       .fold<double>(0, (sum, report) => sum + report.quantity);

//                   return Card(
//                     elevation: 4,
//                     child: Padding(
//                       padding: const EdgeInsets.all(20.0),
//                       child: Column(
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             children: [
//                               _buildStatItem(
//                                 'Items Donated',
//                                 completedItems.toString(),
//                                 Icons.inventory,
//                                 Colors.green,
//                               ),
//                               _buildStatItem(
//                                 'People Fed',
//                                 _formatNumber(peopleFed),
//                                 Icons.people,
//                                 Colors.blue,
//                               ),
//                               _buildStatItem(
//                                 'PKR Saved',
//                                 _formatCurrency(pkrSaved),
//                                 Icons.attach_money,
//                                 Colors.orange,
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.green.shade50,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.eco,
//                                   color: Colors.green.shade700,
//                                   size: 20,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     thisMonthQuantity > 0
//                                         ? 'You\'ve helped reduce food waste by ${thisMonthQuantity.toStringAsFixed(1)}kg this month!'
//                                         : 'Start donating to see your monthly impact!',
//                                     style: TextStyle(
//                                       color: Colors.green.shade700,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 24),

//               // My Surplus Reports Section
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'My Surplus Reports',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const CreateSurplusScreen(),
//                       ),
//                     ),
//                     child: const Text('Add New'),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               // Surplus Reports List
//               StreamBuilder<List<SurplusReportModel>>(
//                 stream: _surplusService.getDonorSurplusReports(user.uid),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
                  
//                   if (snapshot.hasError) {
//                     return Card(
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Text('Error: ${snapshot.error}'),
//                       ),
//                     );
//                   }
                  
//                   final reports = snapshot.data ?? [];
                  
//                   if (reports.isEmpty) {
//                     return Card(
//                       child: Padding(
//                         padding: const EdgeInsets.all(32.0),
//                         child: Column(
//                           children: [
//                             Icon(
//                               Icons.inventory_2_outlined,
//                               size: 64,
//                               color: Colors.grey[400],
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               'No surplus reports yet',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Create your first surplus report to help reduce food waste',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(color: Colors.grey[500]),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }
                  
//                   return Column(
//                     children: reports.take(3).map((report) => 
//                       _buildSurplusReportCard(report)
//                     ).toList(),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMainActionCard(
//     BuildContext context,
//     String title,
//     String subtitle,
//     IconData icon,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return Card(
//       elevation: 6,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 color.withOpacity(0.1),
//                 color.withOpacity(0.05),
//               ],
//             ),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Icon(
//                   icon,
//                   size: 32,
//                   color: color,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 1,
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 2,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatItem(String label, String value, IconData icon, Color color) {
//     return Column(
//       children: [
//         Icon(
//           icon,
//           size: 28,
//           color: color,
//         ),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 12,
//             color: Colors.grey,
//           ),
//           textAlign: TextAlign.center,
//           overflow: TextOverflow.ellipsis,
//           maxLines: 1,
//         ),
//       ],
//     );
//   }

//   // Helper method for loading state statistics
//   Widget _buildLoadingStatItem(String label, IconData icon, Color color) {
//     return Column(
//       children: [
//         Icon(
//           icon,
//           size: 28,
//           color: color.withOpacity(0.5),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           width: 30,
//           height: 18,
//           decoration: BoxDecoration(
//             color: Colors.grey[300],
//             borderRadius: BorderRadius.circular(4),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 12,
//             color: Colors.grey,
//           ),
//           textAlign: TextAlign.center,
//           overflow: TextOverflow.ellipsis,
//           maxLines: 1,
//         ),
//       ],
//     );
//   }

//   // Helper method to format numbers with K/M suffixes
//   String _formatNumber(int number) {
//     if (number >= 1000000) {
//       return '${(number / 1000000).toStringAsFixed(1)}M';
//     } else if (number >= 1000) {
//       return '${(number / 1000).toStringAsFixed(1)}K';
//     } else {
//       return number.toString();
//     }
//   }

//   // Helper method to format currency
//   String _formatCurrency(int amount) {
//     if (amount >= 1000000) {
//       return '${(amount / 1000000).toStringAsFixed(1)}M';
//     } else if (amount >= 1000) {
//       return '${(amount / 1000).toStringAsFixed(0)}K';
//     } else {
//       return amount.toString();
//     }
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

//   Widget _buildSurplusReportCard(SurplusReportModel report) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12.0),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: _getStatusColor(report.status),
//           child: Icon(
//             _getStatusIcon(report.status),
//             color: Colors.white,
//             size: 20,
//           ),
//         ),
//         title: Text(
//           report.foodType,
//           style: const TextStyle(fontWeight: FontWeight.w600),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Quantity: ${report.quantity} kg'),
//             Text(
//               'Expires: ${report.expiry.day}/${report.expiry.month}/${report.expiry.year}',
//               style: TextStyle(
//                 color: _isExpiringSoon(report.expiry) ? Colors.red : Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//         trailing: Chip(
//           label: Text(
//             report.status.toUpperCase(),
//             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//           ),
//           backgroundColor: _getStatusColor(report.status).withOpacity(0.2),
//           labelStyle: TextStyle(color: _getStatusColor(report.status)),
//         ),
//         onTap: () {
//           // TODO: Navigate to surplus detail screen
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Surplus details for ${report.foodType}')),
//           );
//         },
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'available':
//         return Colors.green;
//       case 'requested':
//         return Colors.orange;
//       case 'completed':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getStatusIcon(String status) {
//     switch (status.toLowerCase()) {
//       case 'available':
//         return Icons.check_circle;
//       case 'requested':
//         return Icons.hourglass_empty;
//       case 'completed':
//         return Icons.done_all;
//       default:
//         return Icons.help;
//     }
//   }

//   bool _isExpiringSoon(DateTime expiry) {
//     final now = DateTime.now();
//     final difference = expiry.difference(now).inDays;
//     return difference <= 2; // Expires within 2 days
//   }
// }
