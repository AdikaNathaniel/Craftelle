import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BasketItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final String? selectedSize;
  final double price;
  final String sellerName;
  final String sellerEmail;
  int quantity;

  BasketItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    this.selectedSize,
    required this.price,
    required this.sellerName,
    required this.sellerEmail,
    this.quantity = 1,
  });

  String get uniqueKey =>
      selectedSize != null ? '${productId}_$selectedSize' : productId;

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
        'productId': productId,
        'productName': productName,
        'imageUrl': imageUrl,
        'selectedSize': selectedSize,
        'price': price,
        'sellerName': sellerName,
        'sellerEmail': sellerEmail,
        'quantity': quantity,
      };

  factory BasketItem.fromJson(Map<String, dynamic> json) => BasketItem(
        productId: json['productId'],
        productName: json['productName'],
        imageUrl: json['imageUrl'],
        selectedSize: json['selectedSize'],
        price: (json['price'] as num).toDouble(),
        sellerName: json['sellerName'],
        sellerEmail: json['sellerEmail'],
        quantity: json['quantity'] ?? 1,
      );
}

class WishListItem {
  final String id;
  final String text;

  WishListItem({required this.id, required this.text});

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory WishListItem.fromJson(Map<String, dynamic> json) =>
      WishListItem(id: json['id'], text: json['text']);
}

class BasketService {
  static final BasketService _instance = BasketService._internal();
  factory BasketService() => _instance;
  BasketService._internal();

  static const String _basketKey = 'craftelle_basket_items';
  static const String _wishListKey = 'craftelle_wish_list';

  final List<BasketItem> _items = [];
  final List<WishListItem> _wishList = [];
  final List<VoidCallback> _listeners = [];
  bool _initialized = false;

  List<BasketItem> get items => List.unmodifiable(_items);
  List<WishListItem> get wishList => List.unmodifiable(_wishList);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void _notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();

    final basketJson = prefs.getString(_basketKey);
    if (basketJson != null) {
      final List<dynamic> decoded = json.decode(basketJson);
      _items.clear();
      _items.addAll(decoded.map((e) => BasketItem.fromJson(e)));
    }

    final wishListJson = prefs.getString(_wishListKey);
    if (wishListJson != null) {
      final List<dynamic> decoded = json.decode(wishListJson);
      _wishList.clear();
      _wishList.addAll(decoded.map((e) => WishListItem.fromJson(e)));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _basketKey, json.encode(_items.map((e) => e.toJson()).toList()));
    await prefs.setString(
        _wishListKey, json.encode(_wishList.map((e) => e.toJson()).toList()));
  }

  Future<void> addItem(BasketItem item) async {
    final existingIndex =
        _items.indexWhere((e) => e.uniqueKey == item.uniqueKey);
    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(item);
    }
    await _save();
    _notifyListeners();
  }

  Future<void> removeItem(String uniqueKey) async {
    _items.removeWhere((e) => e.uniqueKey == uniqueKey);
    await _save();
    _notifyListeners();
  }

  Future<void> updateQuantity(String uniqueKey, int newQuantity) async {
    final index = _items.indexWhere((e) => e.uniqueKey == uniqueKey);
    if (index != -1) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
    }
    await _save();
    _notifyListeners();
  }

  Future<void> clearBasket() async {
    _items.clear();
    await _save();
    _notifyListeners();
  }

  Future<void> addWishListItem(String text) async {
    _wishList.add(WishListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
    ));
    await _save();
    _notifyListeners();
  }

  Future<void> removeWishListItem(String id) async {
    _wishList.removeWhere((e) => e.id == id);
    await _save();
    _notifyListeners();
  }

  Future<void> clearWishList() async {
    _wishList.clear();
    await _save();
    _notifyListeners();
  }
}
