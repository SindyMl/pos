import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Dashboard'),
        backgroundColor: AppColors.primaryTeal,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<DocumentSnapshot>(
              stream:
                  _firestore.collection('settings').doc('lowStock').snapshots(),
              builder: (
                context,
                AsyncSnapshot<DocumentSnapshot> settingsSnapshot,
              ) {
                if (settingsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                int lowStockThreshold = 10;
                if (settingsSnapshot.hasData && settingsSnapshot.data!.exists) {
                  lowStockThreshold =
                      settingsSnapshot.data!['threshold'] is int
                          ? settingsSnapshot.data!['threshold'] as int
                          : 10;
                }
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('sales').snapshots(),
                  builder: (
                    context,
                    AsyncSnapshot<QuerySnapshot> salesSnapshot,
                  ) {
                    if (salesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('inventory').snapshots(),
                      builder: (
                        context,
                        AsyncSnapshot<QuerySnapshot> inventorySnapshot,
                      ) {
                        if (inventorySnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        // Handle errors
                        if (salesSnapshot.hasError) {
                          debugPrint('Sales error: ${salesSnapshot.error}');
                          return const Center(
                            child: Text(
                              'Error loading sales',
                              style: TextStyle(color: AppColors.alertRed),
                            ),
                          );
                        }
                        if (inventorySnapshot.hasError) {
                          debugPrint(
                            'Inventory error: ${inventorySnapshot.error}',
                          );
                          return const Center(
                            child: Text(
                              'Error loading inventory',
                              style: TextStyle(color: AppColors.alertRed),
                            ),
                          );
                        }
                        // Process sales
                        double todaySales = 0.0;
                        double dailyProfit = 0.0;
                        int pendingOrders = 0;
                        if (salesSnapshot.hasData &&
                            salesSnapshot.data!.docs.isNotEmpty) {
                          final now = DateTime.now();
                          final todayStart = DateTime(
                            now.year,
                            now.month,
                            now.day,
                          );
                          for (var doc in salesSnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            try {
                              final timestamp =
                                  data['timestamp'] is Timestamp
                                      ? (data['timestamp'] as Timestamp)
                                          .toDate()
                                      : DateTime.now();
                              final total =
                                  data['total'] is num
                                      ? (data['total'] as num).toDouble()
                                      : 0.0;
                              final status =
                                  data['status'] as String? ?? 'completed';
                              if (timestamp.isAfter(todayStart)) {
                                todaySales += total;
                                dailyProfit += total * 0.3; // 30% profit margin
                              }
                              if (status == 'pending') {
                                pendingOrders++;
                              }
                            } catch (e) {
                              debugPrint('Error processing sale ${doc.id}: $e');
                            }
                          }
                        }
                        // Process inventory
                        int lowStockCount = 0;
                        if (inventorySnapshot.hasData &&
                            inventorySnapshot.data!.docs.isNotEmpty) {
                          for (var doc in inventorySnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            try {
                              final quantity =
                                  data['quantity'] is num
                                      ? (data['quantity'] as num).toInt()
                                      : 0;
                              if (quantity < lowStockThreshold) {
                                lowStockCount++;
                              }
                            } catch (e) {
                              debugPrint(
                                'Error processing inventory ${doc.id}: $e',
                              );
                            }
                          }
                        }
                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            SummaryCard(
                              title: 'Today\'s Sales',
                              value: '\$${todaySales.toStringAsFixed(2)}',
                              icon: Icons.attach_money,
                              onTap:
                                  () => Navigator.pushNamed(context, '/sales'),
                            ),
                            SummaryCard(
                              title: 'Low Stock',
                              value: '$lowStockCount items',
                              icon: Icons.warning,
                              color: AppColors.alertRed,
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    '/inventory',
                                  ),
                            ),
                            SummaryCard(
                              title: 'Profit',
                              value: '\$${dailyProfit.toStringAsFixed(2)}',
                              icon: Icons.trending_up,
                            ),
                            SummaryCard(
                              title: 'Pending Orders',
                              value: '$pendingOrders',
                              icon: Icons.hourglass_empty,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentAmber,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/sales'),
                  child: const Text('New Sale'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/inventory'),
                  child: const Text('Add Inventory'),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: AppColors.textDarkGray,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/sales');
          if (index == 2) Navigator.pushNamed(context, '/inventory');
          if (index == 3) Navigator.pushNamed(context, '/summary');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Summary',
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color ?? AppColors.primaryTeal),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
