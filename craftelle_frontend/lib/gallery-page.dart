import 'package:flutter/material.dart';
import 'dart:async';

class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> with TickerProviderStateMixin {
  static const _pink = Color(0xFFF9A8D4);
  static const _pinkDark = Color(0xFFEC4899);

  final List<_CategoryData> categories = [
    _CategoryData(
      name: 'Forever Flower Bouquets',
      folder: 'assets/forever-flower-bouquet',
      imageFiles: [
        '1.jpeg', '2.jpeg', '3.jpeg', '4.jpeg', '5.jpeg', '6.jpeg',
        '8.jpeg', '9.jpeg', '10.jpeg', '11.jpeg', '12.jpeg', '13.jpeg',
        '14.jpeg', '15.jpeg', '16.jpeg', '17.jpeg', '18.jpeg', '19.jpeg',
      ],
      icon: Icons.local_florist,
    ),
    _CategoryData(
      name: 'Bobo Balloon',
      folder: 'assets/bobo-ballon',
      imageFiles: ['1.jpeg', '2.jpeg', '3.jpeg', '4.jpeg', '5.jpeg', '6.jpeg'],
      icon: Icons.celebration,
    ),
    _CategoryData(
      name: 'Treats Box',
      folder: 'assets/treats-box',
      imageFiles: [
        '1.jpeg', '2.jpeg', '3.jpeg', '4.jpeg',
        '5.jpeg', '6.jpeg', '7.jpeg', '8.jpeg',
      ],
      icon: Icons.card_giftcard,
    ),
    _CategoryData(
      name: 'Room Decor',
      folder: 'assets/room-decor',
      imageFiles: ['1.jpeg', '2.jpeg'],
      icon: Icons.home_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF1F2),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _AnimatedCategorySection(
            category: categories[index],
            delayMs: index * 200,
            pink: _pink,
            pinkDark: _pinkDark,
          );
        },
      ),
    );
  }
}

class _CategoryData {
  final String name;
  final String folder;
  final List<String> imageFiles;
  final IconData icon;

  const _CategoryData({
    required this.name,
    required this.folder,
    required this.imageFiles,
    required this.icon,
  });
}

class _AnimatedCategorySection extends StatefulWidget {
  final _CategoryData category;
  final int delayMs;
  final Color pink;
  final Color pinkDark;

  const _AnimatedCategorySection({
    required this.category,
    required this.delayMs,
    required this.pink,
    required this.pinkDark,
  });

  @override
  _AnimatedCategorySectionState createState() => _AnimatedCategorySectionState();
}

class _AnimatedCategorySectionState extends State<_AnimatedCategorySection>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  double _scrollPosition = 0;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _entryController.forward();
    });

    _scrollController = ScrollController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || _isUserScrolling) return;
      if (!_scrollController.hasClients) return;

      _scrollPosition += 0.5;
      final maxScroll = _scrollController.position.maxScrollExtent;

      if (_scrollPosition >= maxScroll) {
        _scrollPosition = 0;
      }

      _scrollController.jumpTo(_scrollPosition);
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _entryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.pink, widget.pinkDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Auto-scrolling Image Carousel
              ClipRect(
                child: SizedBox(
                  height: 220,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification &&
                          notification.dragDetails != null) {
                        _isUserScrolling = true;
                      }
                      if (notification is ScrollEndNotification) {
                        Future.delayed(const Duration(seconds: 3), () {
                          if (mounted) {
                            _isUserScrolling = false;
                            _scrollPosition = _scrollController.offset;
                          }
                        });
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.hardEdge,
                      itemCount: cat.imageFiles.length * 100,
                      itemBuilder: (context, index) {
                        final imgIndex = index % cat.imageFiles.length;
                        final imagePath = '${cat.folder}/${cat.imageFiles[imgIndex]}';

                        return _GalleryImageCard(
                          imagePath: imagePath,
                          pink: widget.pink,
                          onTap: () => _openFullScreen(context, cat, imgIndex),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context, _CategoryData cat, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(
          category: cat,
          initialIndex: initialIndex,
          pink: widget.pink,
        ),
      ),
    );
  }
}

class _GalleryImageCard extends StatelessWidget {
  final String imagePath;
  final Color pink;
  final VoidCallback onTap;

  const _GalleryImageCard({
    required this.imagePath,
    required this.pink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: pink.withOpacity(0.2),
                    child: Icon(
                      Icons.image_not_supported,
                      color: pink,
                      size: 40,
                    ),
                  );
                },
              ),
              // Tap hint icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fullscreen,
                    size: 16,
                    color: pink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Full-screen gallery viewer with page swipe
class _FullScreenGallery extends StatefulWidget {
  final _CategoryData category;
  final int initialIndex;
  final Color pink;

  const _FullScreenGallery({
    required this.category,
    required this.initialIndex,
    required this.pink,
  });

  @override
  _FullScreenGalleryState createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          cat.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: cat.imageFiles.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final imagePath = '${cat.folder}/${cat.imageFiles[index]}';
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 64,
                      );
                    },
                  ),
                ),
              );
            },
          ),
          // Bottom dot indicators
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                cat.imageFiles.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? widget.pink
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
