import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'basket-service.dart';
import 'rating-widget.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isSellerView;
  final String? userEmail;

  const ProductDetailPage({
    Key? key,
    required this.product,
    this.isSellerView = false,
    this.userEmail,
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with SingleTickerProviderStateMixin {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);
  static const _ratingsUrl = 'https://craftelle.fly.dev/api/v1/ratings';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Set<String> _selectedSizes = {};

  double _averageRating = 0.0;
  int _totalRatings = 0;
  int _userRating = 0;
  Timer? _ratingDebounce;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _fetchRatings();
  }

  @override
  void dispose() {
    _ratingDebounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRatings() async {
    final productId = widget.product['_id'];
    if (productId == null) return;

    try {
      final avgResponse = await http.get(
        Uri.parse('$_ratingsUrl/product/$productId/average'),
        headers: {'Content-Type': 'application/json'},
      );

      if (avgResponse.statusCode == 200) {
        final avgData = json.decode(avgResponse.body);
        if (avgData['success'] == true && avgData['result'] != null) {
          if (mounted) {
            setState(() {
              _averageRating = (avgData['result']['averageRating'] ?? 0.0).toDouble();
              _totalRatings = avgData['result']['totalRatings'] ?? 0;
            });
          }
        }
      }

      if (!widget.isSellerView && widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        final userResponse = await http.get(
          Uri.parse('$_ratingsUrl/product/$productId/user/${widget.userEmail}'),
          headers: {'Content-Type': 'application/json'},
        );

        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          if (userData['success'] == true && userData['result'] != null) {
            if (mounted) {
              setState(() {
                _userRating = userData['result']['stars'] ?? 0;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching ratings: $e');
    }
  }

  void _onStarTapped() {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return;

    setState(() {
      _userRating = _userRating >= 5 ? 1 : _userRating + 1;
    });

    // Debounce: auto-save after 1.5 seconds of no tapping
    _ratingDebounce?.cancel();
    _ratingDebounce = Timer(const Duration(milliseconds: 1500), () {
      _saveRating(_userRating);
    });
  }

  Future<void> _saveRating(int stars) async {
    if (stars == 0) return;

    try {
      final response = await http.post(
        Uri.parse(_ratingsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'type': 'product',
          'userEmail': widget.userEmail,
          'productId': widget.product['_id'],
          'productName': widget.product['name'] ?? '',
          'sellerEmail': widget.product['sellerEmail'] ?? '',
          'stars': stars,
          'reviewText': '',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _fetchRatings();
      }
    } catch (e) {
      debugPrint('Error saving rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSizes = widget.product['hasSizes'] == true;
    final sizePrices = widget.product['sizePrices'];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: _pink,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_${widget.product['_id']}',
                child: Image.network(
                  widget.product['imageUrl'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 120, color: Colors.grey[500]),
                            const SizedBox(height: 16),
                            Text('Image not available', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Product Details
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          widget.product['name'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        const SizedBox(height: 8),

                        // Seller Info
                        Row(
                          children: [
                            const Icon(Icons.store, size: 18, color: _pink),
                            const SizedBox(width: 8),
                            Text(
                              'by ${widget.product['sellerName']}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),

                        // Rating Section
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            // Average rating display
                            if (_totalRatings > 0)
                              AverageRatingDisplay(
                                averageRating: _averageRating,
                                totalRatings: _totalRatings,
                                starSize: 18,
                              ),
                            if (_totalRatings > 0 && !widget.isSellerView && widget.userEmail != null)
                              const SizedBox(width: 16),
                            // Inline tap-to-rate star (customers only)
                            if (!widget.isSellerView && widget.userEmail != null)
                              GestureDetector(
                                onTap: _onStarTapped,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _userRating > 0 ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 26,
                                      color: _userRating > 0 ? _pinkDark : Colors.grey[400],
                                    ),
                                    if (_userRating > 0) ...[
                                      const SizedBox(width: 3),
                                      Text(
                                        '$_userRating',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _pinkDark,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product['description'] ?? '',
                          style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                        ),
                        const SizedBox(height: 32),

                        // Pricing Section
                        if (hasSizes && sizePrices != null) ...[
                          const Text(
                            'Available Sizes & Pricing',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _pink),
                          ),
                          const SizedBox(height: 16),
                          ...(sizePrices as Map<String, dynamic>).entries
                              .where((e) => e.value != null)
                              .map((e) => _buildSizeCard(e.key, e.key, e.value, Icons.straighten)),
                        ] else if (widget.product['basePrice'] != null) ...[
                          const Text(
                            'Price',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _pink),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _pink.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _pink, width: 2),
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.product['priceDisplay'] != null && widget.product['priceDisplay'].toString().isNotEmpty
                                      ? widget.product['priceDisplay']
                                      : 'GHS ${NumberFormat('#,##0').format(widget.product['basePrice'])} and above',
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _pink),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Add to Basket Button (only for customers)
                        if (!widget.isSellerView) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _addToBasket,
                              icon: const Icon(Icons.shopping_basket, size: 24),
                              label: const Text(
                                'Add to Basket',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeCard(String displayName, String sizeKey, dynamic price, IconData icon) {
    final bool isSelected = _selectedSizes.contains(sizeKey);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSizes.remove(sizeKey);
          } else {
            _selectedSizes.add(sizeKey);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? _pink.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _pink, width: isSelected ? 2.5 : 2),
          boxShadow: [
            BoxShadow(
              color: _pink.withOpacity(isSelected ? 0.2 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pink.withOpacity(isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _pink, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'GHS ${NumberFormat('#,##0').format(price)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _pink),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: _pink,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  void _addToBasket() {
    final bool hasSizes = widget.product['hasSizes'] == true;
    final sizePrices = widget.product['sizePrices'];

    if (hasSizes && sizePrices != null) {
      if (_selectedSizes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Please select at least one size'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      int addedCount = 0;
      for (final sizeKey in _selectedSizes) {
        final price = sizePrices[sizeKey];
        if (price != null) {
          final item = BasketItem(
            productId: widget.product['_id'] ?? '',
            productName: widget.product['name'] ?? '',
            imageUrl: widget.product['imageUrl'] ?? '',
            selectedSize: sizeKey,
            price: (price as num).toDouble(),
            sellerName: widget.product['sellerName'] ?? '',
            sellerEmail: widget.product['sellerEmail'] ?? '',
          );
          BasketService().addItem(item);
          addedCount++;
        }
      }

      setState(() => _selectedSizes.clear());
      _showAddedSnackbar(count: addedCount);
    } else {
      final item = BasketItem(
        productId: widget.product['_id'] ?? '',
        productName: widget.product['name'] ?? '',
        imageUrl: widget.product['imageUrl'] ?? '',
        selectedSize: null,
        price: (widget.product['basePrice'] as num?)?.toDouble() ?? 0.0,
        sellerName: widget.product['sellerName'] ?? '',
        sellerEmail: widget.product['sellerEmail'] ?? '',
      );
      BasketService().addItem(item);
      _showAddedSnackbar();
    }
  }

  void _showAddedSnackbar({int count = 1}) {
    final message = count > 1 ? '$count items added to Basket!' : 'Added to Basket!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: _pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
