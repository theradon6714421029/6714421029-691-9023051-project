import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/current_user.dart';
import '../services/firestore_service.dart';
import 'admin_screen.dart';
import 'orders_screen.dart';
import 'restaurant_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final FirestoreService service = FirestoreService();

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cafeteria'),
        actions: [
          IconButton(
            tooltip: 'ออเดอร์ของฉัน',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrdersScreen(),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long),
          ),
          if (isAdmin)
            IconButton(
              tooltip: 'Admin',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
            ),
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: service.restaurantStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'เกิดข้อผิดพลาด: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีร้านอาหาร'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final name =
                  data['name']?.toString() ?? 'ไม่มีชื่อ';

              final isOpen =
                  data['isOpen'] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 26,
                    child: Icon(
                      isOpen
                          ? Icons.restaurant
                          : Icons.storefront,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isOpen
                        ? 'เปิดให้บริการ'
                        : 'ปิดให้บริการ',
                  ),
                  trailing: Icon(
                    isOpen
                        ? Icons.arrow_forward_ios
                        : Icons.lock_outline,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RestaurantDetailScreen(
                          restaurantId: doc.id,
                          restaurantName: name,
                          isOpen: isOpen,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}