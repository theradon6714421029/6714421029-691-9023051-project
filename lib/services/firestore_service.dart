import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get restaurants =>
      db.collection('restaurants');

  CollectionReference<Map<String, dynamic>> get orders =>
      db.collection('orders');

  // =========================
  // RESTAURANTS
  // =========================

  Stream<QuerySnapshot<Map<String, dynamic>>> restaurantStream() {
    return restaurants.orderBy('name').snapshots();
  }

  Future<void> addRestaurant({
    required String name,
    required bool isOpen,
  }) async {
    await restaurants.add({
      'name': name,
      'isOpen': isOpen,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRestaurantStatus({
    required String restaurantId,
    required bool isOpen,
  }) async {
    await restaurants.doc(restaurantId).update({
      'isOpen': isOpen,
    });
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    final menuSnapshot =
        await restaurants.doc(restaurantId).collection('menu').get();

    final batch = db.batch();

    for (final doc in menuSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(restaurants.doc(restaurantId));

    await batch.commit();
  }

  // =========================
  // MENU
  // =========================

  CollectionReference<Map<String, dynamic>> menu(
    String restaurantId,
  ) {
    return restaurants.doc(restaurantId).collection('menu');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> menuStream(
    String restaurantId,
  ) {
    return menu(restaurantId).orderBy('name').snapshots();
  }

  Future<void> addMenuItem({
    required String restaurantId,
    required String name,
    required double price,
  }) async {
    await menu(restaurantId).add({
      'name': name,
      'price': price,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMenuItem({
    required String restaurantId,
    required String menuId,
  }) async {
    await menu(restaurantId).doc(menuId).delete();
  }

  // =========================
  // ORDERS
  // =========================

  Future<String> createOrder({
    required String userId,
    required String restaurantId,
    required String restaurantName,
    required String menuId,
    required String menuName,
    required double price,
    required int quantity,
    required bool takeAway,
    required String pickupTime,
  }) async {
    final totalPrice = price * quantity;

    final docRef = orders.doc();

    final orderNumber =
        'CAF-${docRef.id.substring(0, 6).toUpperCase()}';

    await docRef.set({
      'orderNumber': orderNumber,
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'menuId': menuId,
      'menuName': menuName,
      'price': price,
      'quantity': quantity,
      'takeAway': takeAway,
      'pickupTime': pickupTime,
      'totalPrice': totalPrice,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return orderNumber;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> customerOrderStream(
    String userId,
  ) {
    return orders
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> adminOrderStream() {
    return orders
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await orders.doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}