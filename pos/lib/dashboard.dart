import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatelessWidget {
  // Firestore instance
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
              'Welcome, User!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // StreamBuilder for real-time data
            StreamBuilder(
              stream:
                  _firestore.collection('settings').doc('lowStock').snapshots(),
              builder: (
                context,
                AsyncSnapshot<DocumentSnapshot> settingsSnapshot,
              ) {
                // Handle settings (low stock threshold)
                int lowStockThreshold = 10; // Default
                if (settingsSnapshot.hasData && settingsSnapshot.data!.exists) {
                  lowStockThreshold = settingsSnapshot.data!['threshold'] ?? 10;
                }

                return StreamBuilder(
                  stream: _firestore.collection('sales').snapshots(),
                  builder: (
                    context,
                    AsyncSnapshot<QuerySnapshot> salesSnapshot,
                  ) {
                    return StreamBuilder(
                      stream: _firestore.collection('inventory').snapshots(),
                      builder: (
                        context,
                        AsyncSnapshot<QuerySnapshot> inventorySnapshot,
                      ) {
                        // Handle loading state
                        if (salesSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            inventorySnapshot.connectionState ==
                                ConnectionState.waiting ||
                            settingsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // Handle errors
                        if (salesSnapshot.hasError ||
                            inventorySnapshot.hasError ||
                            settingsSnapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Error loading data',
                              style: TextStyle(color: AppColors.alertRed),
                            ),
                          );
                        }

                        // Process sales data
                        double todaySales = 0.0;
                        double dailyProfit = 0.0;
                        int pendingOrders = 0;
                        final now = DateTime.now();
                        final todayStart = DateTime(
                          now.year,
                          now.month,
                          now.day,
                        );

                        for (var doc in salesSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final timestamp =
                              (data['timestamp'] as Timestamp).toDate();
                          final total = data['total']?.toDouble() ?? 0.0;

                          if (timestamp.isAfter(todayStart)) {
                            todaySales += total;
                            dailyProfit +=
                                total *
                                0.3; // Assume 30% profit margin (customize as needed)
                          }
                          if (data['status'] == 'pending') {
                            pendingOrders++;
                          }
                        }

                        // Process inventory data
                        int lowStockCount = 0;
                        for (var doc in inventorySnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final quantity = data['quantity']?.toInt() ?? 0;
                          if (quantity < lowStockThreshold) {
                            lowStockCount++;
                          }
                        }

                        // Display summary cards
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

// Reusable SummaryCard widget
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
