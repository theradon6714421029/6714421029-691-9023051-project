import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'restaurant_detail_screen.dart';

import '../services/firestore_service.dart';
import 'order_screen.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final bool isOpen;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(restaurantName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.menuStream(restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'เกิดข้อผิดพลาด\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final menus = snapshot.data?.docs ?? [];

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 42,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurantName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isOpen ? 'ร้านเปิดอยู่' : 'ร้านปิดอยู่',
                            style: TextStyle(
                              color: isOpen
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: menus.isEmpty
                    ? const Center(
                        child: Text(
                          'ร้านนี้ยังไม่มีเมนู',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        itemCount: menus.length,
                        itemBuilder: (context, index) {
                          final doc = menus[index];
                          final data = doc.data();

                          final name =
                              data['name'] ?? 'ไม่มีชื่อเมนู';

                          final price =
                              (data['price'] as num?)?.toDouble() ??
                                  0;

                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                child: const Icon(
                                  Icons.fastfood,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${price.toStringAsFixed(0)} บาท',
                              ),
                              trailing: isOpen
                                  ? FilledButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                OrderScreen(
                                              restaurantId:
                                                  restaurantId,
                                              restaurantName:
                                                  restaurantName,
                                              menuId: doc.id,
                                              menuName: name,
                                              price: price,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'สั่ง',
                                      ),
                                    )
                                  : const Text(
                                      'ปิด',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}