import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'basket-service.dart';
import 'order-service.dart';
import 'payment-page.dart';
import 'location-picker-page.dart';

class BasketPage extends StatefulWidget {
  final VoidCallback? onOrderPlaced;
  final String customerEmail;

  const BasketPage({Key? key, this.onOrderPlaced, this.customerEmail = ''})
      : super(key: key);

  @override
  _BasketPageState createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage> with TickerProviderStateMixin {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);
  static const _bg = Color(0xFFFFF1F2);

  final _basket = BasketService();
  final _wishListController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _basket.addListener(_onBasketChanged);
  }

  void _onBasketChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _basket.removeListener(_onBasketChanged);
    _wishListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _basket.items;
    final wishList = _basket.wishList;
    final isEmpty = items.isEmpty && wishList.isEmpty;

    final hasContent = items.isNotEmpty || wishList.isNotEmpty;

    return Container(
      color: _bg,
      child: isEmpty
          ? _buildEmptyState()
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (items.isNotEmpty) ...[
                        ...items.map((item) => _buildBasketItemCard(item)),
                        const SizedBox(height: 12),
                        _buildTotalRow(),
                        const SizedBox(height: 8),
                        _buildClearBasketButton(),
                      ],
                      const SizedBox(height: 24),
                      _buildWishListSection(wishList),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                if (hasContent)
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: GestureDetector(
                      onTap: _placeOrder,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_pink, _pinkDark],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: _pinkDark.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Place Order',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _placeOrder() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _pink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: _pink, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Place Order?'),
          ],
        ),
        content: const Text(
          'Your basket items and wish list will be submitted as one order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showDeliveryDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Continue',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeliveryDialog() async {
    // Fetch user's saved location
    String savedAddress = '';
    double? savedLat;
    double? savedLng;

    try {
      final response = await http.get(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/users/profile/${widget.customerEmail}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['result'] != null) {
          savedAddress = (data['result']['savedAddress'] ?? '').toString();
          savedLat = (data['result']['savedLatitude'] as num?)?.toDouble();
          savedLng = (data['result']['savedLongitude'] as num?)?.toDouble();
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }

    if (!mounted) return;

    final phoneController = TextEditingController();
    SelectedLocation? selectedLocation;
    bool useMyLocation = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: _pink, size: 36),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Delivery Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Where should we deliver your order?',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 22),

                  // Option 1: Use My Location
                  if (savedAddress.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          useMyLocation = true;
                          selectedLocation = null;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: useMyLocation ? _pink.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: useMyLocation ? _pinkDark : _pink.withOpacity(0.3),
                            width: useMyLocation ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              useMyLocation ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: useMyLocation ? _pinkDark : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Use My Location',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    savedAddress,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (savedAddress.isNotEmpty) const SizedBox(height: 12),

                  // Option 2: Choose Different Location
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push<SelectedLocation>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LocationPickerPage(
                            title: 'Select Delivery Location',
                          ),
                        ),
                      );
                      if (result != null) {
                        setDialogState(() {
                          selectedLocation = result;
                          useMyLocation = false;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (selectedLocation != null && !useMyLocation)
                            ? _pink.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (selectedLocation != null && !useMyLocation)
                              ? _pinkDark
                              : _pink.withOpacity(0.3),
                          width: (selectedLocation != null && !useMyLocation) ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (selectedLocation != null && !useMyLocation)
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: (selectedLocation != null && !useMyLocation)
                                ? _pinkDark
                                : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedLocation != null && !useMyLocation
                                      ? 'Selected Location'
                                      : 'Choose Different Location',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedLocation != null && !useMyLocation
                                      ? selectedLocation!.address
                                      : 'Pick a location on the map',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.map_outlined, color: _pinkDark, size: 22),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Phone number field
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.phone, color: _pink, size: 20),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _pink.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _pink.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _pink, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Cancel',
                              style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (phoneController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a phone number')),
                              );
                              return;
                            }
                            if (!useMyLocation && selectedLocation == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a delivery location')),
                              );
                              return;
                            }

                            String city, region, address;
                            double? lat, lng;

                            if (useMyLocation) {
                              address = savedAddress;
                              lat = savedLat;
                              lng = savedLng;
                              // Parse city/region from saved address
                              final parts = savedAddress.split(', ');
                              city = parts.length >= 2 ? parts[parts.length - 2] : '';
                              region = parts.isNotEmpty ? parts.last : '';
                            } else {
                              city = selectedLocation!.city;
                              region = selectedLocation!.region;
                              address = selectedLocation!.address;
                              lat = selectedLocation!.latitude;
                              lng = selectedLocation!.longitude;
                            }

                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentPage(
                                  basketItems: _basket.items,
                                  wishList: _basket.wishList,
                                  totalPrice: _basket.totalPrice,
                                  deliveryCity: city,
                                  deliveryRegion: region,
                                  deliveryAddress: address,
                                  customerPhone: phoneController.text.trim(),
                                  deliveryLatitude: lat,
                                  deliveryLongitude: lng,
                                  onPaymentConfirmed: () async {
                                    await _basket.clearBasket();
                                    await _basket.clearWishList();
                                    if (mounted) {
                                      widget.onOrderPlaced?.call();
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Continue to Payment',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _pink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              size: 80,
              color: _pink.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Basket is Empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from Our Masterpieces\nor create a wish list below',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildWishListSection(_basket.wishList),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_pink, _pinkDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBasketItemCard(BasketItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _pink.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.image, color: _pink.withOpacity(0.4), size: 30),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.selectedSize != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.displaySize,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _pinkDark,
                      ),
                    ),
                  ),
                Text(
                  'GHS ${NumberFormat('#,##0').format(item.price)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _pink,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls + delete
          Column(
            children: [
              // Quantity row
              Container(
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQtyButton(
                      Icons.remove,
                      () => _basket.updateQuantity(
                          item.uniqueKey, item.quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    _buildQtyButton(
                      Icons.add,
                      () => _basket.updateQuantity(
                          item.uniqueKey, item.quantity + 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _basket.removeItem(item.uniqueKey),
                child: Icon(Icons.delete_outline, color: Colors.red[300], size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _pink.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: _pinkDark),
      ),
    );
  }

  Widget _buildTotalRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_pink, _pinkDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'GHS ${NumberFormat('#,##0').format(_basket.totalPrice)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearBasketButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Clear Basket?'),
              content: const Text('Remove all items from your basket?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _basket.clearBasket();
                  },
                  child: const Text('Clear', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        icon: Icon(Icons.remove_shopping_cart, size: 18, color: Colors.grey[500]),
        label: Text('Clear Basket', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ),
    );
  }

  Widget _buildWishListSection(List<WishListItem> wishList) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with pencil button
          Row(
            children: [
              Icon(Icons.list_alt, color: _pinkDark, size: 22),
              const SizedBox(width: 8),
              const Text(
                'My Wish List',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showAddWishListDialog,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _pink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _pink.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (wishList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _pink.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.edit_note, size: 36, color: _pink.withOpacity(0.4)),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the pencil to add items\nto your wish list',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...wishList.map((item) => _buildWishListItemCard(item)),

          if (wishList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Clear Wish List?'),
                      content: const Text('Remove all items from your wish list?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _basket.clearWishList();
                          },
                          child: const Text('Clear', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.delete_sweep, size: 18, color: Colors.grey[500]),
                label: Text('Clear List', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWishListItemCard(WishListItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _pink.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.note_outlined, color: _pink, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _basket.removeWishListItem(item.id),
            child: Icon(Icons.close, size: 20, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  void _showAddWishListDialog() {
    _wishListController.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _pink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: _pink, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add to Wish List',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _wishListController,
                autofocus: true,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'What would you like?',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _pink.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _pink.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _pink, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final text = _wishListController.text.trim();
                        if (text.isNotEmpty) {
                          _basket.addWishListItem(text);
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add to List',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
