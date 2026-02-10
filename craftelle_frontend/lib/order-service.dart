import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'basket-service.dart';

class OrderItem {
  final String productName;
  final String imageUrl;
  final String? selectedSize;
  final double price;
  final int quantity;
  final String sellerName;

  OrderItem({
    required this.productName,
    required this.imageUrl,
    this.selectedSize,
    required this.price,
    required this.quantity,
    required this.sellerName,
  });

  String get displaySize {
    switch (selectedSize) {
      case 'small':
        return 'Small';
      case 'medium':
        return 'Medium';
      case 'large':
        return 'Large';
      case 'extraLarge':
        return 'Extra Large';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'imageUrl': imageUrl,
        'selectedSize': selectedSize,
        'price': price,
        'quantity': quantity,
        'sellerName': sellerName,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productName: json['productName'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        selectedSize: json['selectedSize'],
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] ?? 1,
        sellerName: json['sellerName'] ?? '',
      );

  factory OrderItem.fromBasketItem(BasketItem item) => OrderItem(
        productName: item.productName,
        imageUrl: item.imageUrl,
        selectedSize: item.selectedSize,
        price: item.price,
        quantity: item.quantity,
        sellerName: item.sellerName,
      );
}

class Order {
  final String id;
  final DateTime createdAt;
  final List<OrderItem> items;
  final List<String> wishListItems;
  final double totalPrice;
  final String customerEmail;

  Order({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.wishListItems,
    required this.totalPrice,
    this.customerEmail = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'wishListItems': wishListItems,
        'totalPrice': totalPrice,
        'customerEmail': customerEmail,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['_id'] ?? json['id'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        items: (json['items'] as List? ?? [])
            .map((e) => OrderItem.fromJson(e))
            .toList(),
        wishListItems: List<String>.from(json['wishListItems'] ?? []),
        totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
        customerEmail: json['customerEmail'] ?? '',
      );
}

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  static const String _baseUrl =
      'https://neurosense-palsy.fly.dev/api/v1/orders';

  final List<Order> _orders = [];
  final List<VoidCallback> _listeners = [];
  bool _initialized = false;
  String _customerEmail = '';

  List<Order> get orders => List.unmodifiable(_orders);

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void _notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  Future<void> init({String? customerEmail}) async {
    if (customerEmail != null) _customerEmail = customerEmail;
    if (_initialized && customerEmail == null) return;
    _initialized = true;
    await _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final uri = _customerEmail.isNotEmpty
          ? Uri.parse('$_baseUrl?customerEmail=$_customerEmail')
          : Uri.parse(_baseUrl);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> results = data['result'] ?? [];
          _orders.clear();
          _orders.addAll(results.map((e) => Order.fromJson(e)));
          _notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
  }

  Future<void> placeOrder(
      List<BasketItem> basketItems, List<WishListItem> wishList) async {
    final orderItems =
        basketItems.map((e) => OrderItem.fromBasketItem(e)).toList();
    final totalPrice = basketItems.fold(
        0.0, (sum, item) => sum + (item.price * item.quantity));

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerEmail': _customerEmail,
          'items': orderItems.map((e) => e.toJson()).toList(),
          'wishListItems': wishList.map((e) => e.text).toList(),
          'totalPrice': totalPrice,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['result'] != null) {
          final order = Order.fromJson(data['result']);
          _orders.insert(0, order);
          _notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error placing order to backend: $e');
    }

    // Fallback: save locally if backend fails
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      items: orderItems,
      wishListItems: wishList.map((e) => e.text).toList(),
      totalPrice: totalPrice,
      customerEmail: _customerEmail,
    );
    _orders.insert(0, order);
    _notifyListeners();
  }

  Future<void> removeOrder(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        _orders.removeWhere((e) => e.id == id);
        _notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Error deleting order from backend: $e');
    }

    // Fallback: remove locally
    _orders.removeWhere((e) => e.id == id);
    _notifyListeners();
  }
}
