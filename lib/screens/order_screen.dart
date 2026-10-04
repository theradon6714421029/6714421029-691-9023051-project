import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class OrderScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String menuId;
  final String menuName;
  final double price;

  const OrderScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.menuId,
    required this.menuName,
    required this.price,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final FirestoreService service = FirestoreService();

  int quantity = 1;
  bool takeAway = true;

  TimeOfDay? pickupTime;

  bool isSubmitting = false;

  double get totalPrice {
    return widget.price * quantity;
  }

  Future<void> selectPickupTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        pickupTime = picked;
      });
    }
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> confirmOrder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนสั่งอาหาร'),
        ),
      );
      return;
    }

    if (pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกเวลารับอาหาร'),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final orderNumber = await service.createOrder(
        userId: user.uid,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        menuId: widget.menuId,
        menuName: widget.menuName,
        price: widget.price,
        quantity: quantity,
        takeAway: takeAway,
        pickupTime: formatTime(pickupTime!),
      );

      if (!mounted) {
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('สั่งอาหารสำเร็จ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  'หมายเลขออเดอร์',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '#$orderNumber',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'เวลารับอาหาร ${formatTime(pickupTime!)}',
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สั่งอาหารไม่สำเร็จ: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยันการสั่งอาหาร'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.restaurantName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.menuName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.price.toStringAsFixed(2)} บาท / รายการ',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'จำนวน',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: quantity > 1
                    ? () {
                        setState(() {
                          quantity--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                ),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {
                  setState(() {
                    quantity++;
                  });
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ซื้อกลับ'),
            subtitle: const Text(
              'เลือกถ้าต้องการนำอาหารกลับ',
            ),
            value: takeAway,
            onChanged: (value) {
              setState(() {
                takeAway = value;
              });
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: selectPickupTime,
            icon: const Icon(Icons.access_time),
            label: Text(
              pickupTime == null
                  ? 'เลือกเวลารับอาหาร'
                  : 'เวลารับ ${formatTime(pickupTime!)}',
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ยอดรวม',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${totalPrice.toStringAsFixed(2)} บาท',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed:
                  isSubmitting ? null : confirmOrder,
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    )
                  : const Text(
                      'ยืนยันการสั่งอาหาร',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}