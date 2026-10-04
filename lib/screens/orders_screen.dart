import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class OrdersScreen extends StatelessWidget {
  OrdersScreen({super.key});

  final FirestoreService service = FirestoreService();

  String statusText(String status) {
    switch (status) {
      case 'preparing':
        return 'กำลังเตรียม';
      case 'ready':
        return 'พร้อมรับ';
      case 'completed':
        return 'เสร็จสิ้น';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return 'รอดำเนินการ';
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('กรุณาเข้าสู่ระบบ'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ออเดอร์ของฉัน'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: service.customerOrderStream(user.uid),
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

          final docs = [
            ...(snapshot.data?.docs ?? []),
          ];

          docs.sort((a, b) {
            final aTime =
                (a.data()['createdAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                    0;

            final bTime =
                (b.data()['createdAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                    0;

            return bTime.compareTo(aTime);
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีออเดอร์'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              final orderNumber =
                  data['orderNumber']?.toString() ?? '-';

              final restaurant =
                  data['restaurantName']?.toString() ?? '-';

              final menu =
                  data['menuName']?.toString() ?? '-';

              final quantity =
                  (data['quantity'] as num?)?.toInt() ?? 0;

              final total =
                  (data['totalPrice'] as num?)?.toDouble() ??
                      0;

              final pickupTime =
                  data['pickupTime']?.toString() ?? '-';

              final status =
                  data['status']?.toString() ?? 'pending';

              final takeAway =
                  data['takeAway'] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#$orderNumber',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            avatar: Icon(
                              statusIcon(status),
                              size: 18,
                            ),
                            label: Text(
                              statusText(status),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('ร้าน: $restaurant'),
                      Text('เมนู: $menu'),
                      Text('จำนวน: $quantity'),
                      Text(
                        'เวลารับ: $pickupTime',
                      ),
                      Text(
                        takeAway
                            ? 'ซื้อกลับ'
                            : 'ทานที่ร้าน',
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ยอดรวม',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${total.toStringAsFixed(2)} บาท',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}