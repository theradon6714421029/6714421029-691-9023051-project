 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/current_user.dart';
import '../services/firestore_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService service = FirestoreService();

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // ADD RESTAURANT
  // ============================================================

  Future<void> _addRestaurant() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('เพิ่มร้านอาหาร'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'ชื่อร้าน',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) {
      return;
    }

    await service.addRestaurant(
      name: name,
      isOpen: true,
    );
  }

  // ============================================================
  // DELETE RESTAURANT
  // ============================================================

  Future<void> _deleteRestaurant({
    required String restaurantId,
    required String restaurantName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ลบร้านอาหาร'),
          content: Text(
            'ต้องการลบ "$restaurantName" และเมนูทั้งหมดหรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await service.deleteRestaurant(restaurantId);
  }

  // ============================================================
  // MANAGE MENU
  // ============================================================

  Future<void> _manageMenu({
    required String restaurantId,
    required String restaurantName,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MenuManagementScreen(
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        ),
      ),
    );
  }

  // ============================================================
  // UPDATE RESTAURANT
  // ============================================================

  Future<void> _toggleRestaurant({
    required String restaurantId,
    required bool isOpen,
  }) async {
    await service.updateRestaurantStatus(
      restaurantId: restaurantId,
      isOpen: !isOpen,
    );
  }

  // ============================================================
  // ORDER STATUS
  // ============================================================

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอรับออเดอร์';
      case 'preparing':
        return 'กำลังทำ';
      case 'ready':
        return 'พร้อมรับ';
      case 'completed':
        return 'เสร็จแล้ว';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  Future<void> _updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await service.updateOrderStatus(
      orderId: orderId,
      status: status,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('ไม่มีสิทธิ์เข้าหน้านี้'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.restaurant),
              text: 'ร้านและเมนู',
            ),
            Tab(
              icon: Icon(Icons.receipt_long),
              text: 'ออเดอร์',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _restaurantsTab(),
          _ordersTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          if (_tabController.index != 0) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: _addRestaurant,
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มร้าน'),
          );
        },
      ),
    );
  }

  // ============================================================
  // RESTAURANTS
  // ============================================================

  Widget _restaurantsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
            child: Text(
              'เกิดข้อผิดพลาด\n${snapshot.error}',
              textAlign: TextAlign.center,
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
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final name =
                data['name'] as String? ?? 'ไม่มีชื่อ';

            final isOpen =
                data['isOpen'] as bool? ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    isOpen
                        ? Icons.restaurant
                        : Icons.restaurant_outlined,
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  isOpen
                      ? 'เปิดให้บริการ'
                      : 'ปิดร้าน',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'toggle') {
                      await _toggleRestaurant(
                        restaurantId: doc.id,
                        isOpen: isOpen,
                      );
                    }

                    if (value == 'menu') {
                      await _manageMenu(
                        restaurantId: doc.id,
                        restaurantName: name,
                      );
                    }

                    if (value == 'delete') {
                      await _deleteRestaurant(
                        restaurantId: doc.id,
                        restaurantName: name,
                      );
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: Text(
                          isOpen
                              ? 'ปิดร้าน'
                              : 'เปิดร้าน',
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'menu',
                        child: Text('จัดการเมนู'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('ลบร้าน'),
                      ),
                    ];
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ORDERS
  // ============================================================

  Widget _ordersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.adminOrderStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
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

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text('ยังไม่มีออเดอร์'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final orderNumber =
                data['orderNumber'] as String? ?? '-';

            final restaurantName =
                data['restaurantName'] as String? ?? '-';

            final menuName =
                data['menuName'] as String? ?? '-';

            final quantity =
                data['quantity'] as int? ?? 0;

            final totalPrice =
                (data['totalPrice'] as num?)
                        ?.toDouble() ??
                    0;

            final pickupTime =
                data['pickupTime'] as String? ?? '-';

            final takeAway =
                data['takeAway'] as bool? ?? false;

            final status =
                data['status'] as String? ?? 'pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            orderNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownButton<String>(
                          value: status,
                          items: const [
                            DropdownMenuItem(
                              value: 'pending',
                              child:
                                  Text('รอรับออเดอร์'),
                            ),
                            DropdownMenuItem(
                              value: 'preparing',
                              child: Text('กำลังทำ'),
                            ),
                            DropdownMenuItem(
                              value: 'ready',
                              child: Text('พร้อมรับ'),
                            ),
                            DropdownMenuItem(
                              value: 'completed',
                              child: Text('เสร็จแล้ว'),
                            ),
                            DropdownMenuItem(
                              value: 'cancelled',
                              child: Text('ยกเลิก'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            _updateOrderStatus(
                              orderId: doc.id,
                              status: value,
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Text('ร้าน: $restaurantName'),
                    Text('เมนู: $menuName'),
                    Text('จำนวน: $quantity'),
                    Text('รับเวลา: $pickupTime'),
                    Text(
                      takeAway
                          ? 'รูปแบบ: Take Away'
                          : 'รูปแบบ: ทานที่ร้าน',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'รวม ${totalPrice.toStringAsFixed(2)} บาท',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'สถานะ: ${_statusText(status)}',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// MENU MANAGEMENT SCREEN
// ============================================================

class MenuManagementScreen extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const MenuManagementScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  // ============================================================
  // ADD MENU
  // ============================================================

  Future<void> _addMenuItem(BuildContext context) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    final result =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('เพิ่มเมนู'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ชื่อเมนู',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'ราคา',
                  suffixText: 'บาท',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                final name =
                    nameController.text.trim();

                final price = double.tryParse(
                  priceController.text.trim(),
                );

                if (name.isEmpty ||
                    price == null ||
                    price <= 0) {
                  return;
                }

                Navigator.of(dialogContext).pop({
                  'name': name,
                  'price': price,
                });
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        );
      },
    );

    // สำคัญ:
    // ไม่ dispose controller ตรงนี้
    // เพราะ Flutter อาจกำลังถอด TextField ออกจาก tree

    if (result == null) {
      return;
    }

    await FirestoreService().addMenuItem(
      restaurantId: restaurantId,
      name: result['name'] as String,
      price: result['price'] as double,
    );
  }

  // ============================================================
  // DELETE MENU
  // ============================================================

  Future<void> _deleteMenuItem({
    required BuildContext context,
    required String menuId,
    required String menuName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ลบเมนู'),
          content: Text(
            'ต้องการลบ "$menuName" หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await FirestoreService().deleteMenuItem(
      restaurantId: restaurantId,
      menuId: menuId,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text('เมนู $restaurantName'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.menuStream(restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
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

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีเมนู'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final name =
                  data['name'] as String? ?? '-';

              final price =
                  (data['price'] as num?)
                          ?.toDouble() ??
                      0;

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.restaurant_menu,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${price.toStringAsFixed(2)} บาท',
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                    ),
                    onPressed: () {
                      _deleteMenuItem(
                        context: context,
                        menuId: doc.id,
                        menuName: name,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          _addMenuItem(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มเมนู'),
      ),
    );
  }
}