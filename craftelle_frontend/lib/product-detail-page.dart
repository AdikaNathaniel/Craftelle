import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'basket-service.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isSellerView;

  const ProductDetailPage({
    Key? key,
    required this.product,
    this.isSellerView = false,
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Set<String> _selectedSizes = {};

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
            backgroundColor: const Color(0xFFFDA4AF),
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
                            Icon(
                              Icons.image_not_supported,
                              size: 120,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Image not available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
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
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          widget.product['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        const SizedBox(height: 8),

                        // Seller Info
                        Row(
                          children: [
                            const Icon(
                              Icons.store,
                              size: 18,
                              color: Color(0xFFFDA4AF),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'by ${widget.product['sellerName']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product['description'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Pricing Section
                        if (hasSizes && sizePrices != null) ...[
                          const Text(
                            'Available Sizes & Pricing',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFDA4AF),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Size Cards (selectable)
                          if (sizePrices['small'] != null)
                            _buildSizeCard('Small', 'small', sizePrices['small'], Icons.crop_square),
                          if (sizePrices['medium'] != null)
                            _buildSizeCard('Medium', 'medium', sizePrices['medium'], Icons.crop_din),
                          if (sizePrices['large'] != null)
                            _buildSizeCard('Large', 'large', sizePrices['large'], Icons.crop_landscape),
                          if (sizePrices['extraLarge'] != null)
                            _buildSizeCard('Extra Large', 'extraLarge', sizePrices['extraLarge'], Icons.crop_free),
                        ] else if (widget.product['basePrice'] != null) ...[
                          const Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFDA4AF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDA4AF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFDA4AF),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.product['priceDisplay'] != null && widget.product['priceDisplay'].toString().isNotEmpty
                                      ? widget.product['priceDisplay']
                                      : 'GHS ${NumberFormat('#,##0').format(widget.product['basePrice'])} and above',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFDA4AF),
                                  ),
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
                              onPressed: () {
                                _addToBasket();
                              },
                              icon: const Icon(Icons.shopping_basket, size: 24),
                              label: const Text(
                                'Add to Basket',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFDA4AF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
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
          color: isSelected ? const Color(0xFFFDA4AF).withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFDA4AF),
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFDA4AF).withOpacity(isSelected ? 0.2 : 0.1),
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
                color: const Color(0xFFFDA4AF).withOpacity(isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFDA4AF),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GHS ${NumberFormat('#,##0').format(price)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFDA4AF),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: const Color(0xFFFDA4AF),
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
    final message = count > 1
        ? '$count items added to Basket!'
        : 'Added to Basket!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFFFDA4AF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
