import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'collections-page.dart';
import 'login_page.dart';
import 'chat-contacts.dart';
import 'gallery-page.dart';
import 'basket-service.dart';
import 'basket-page.dart';
import 'order-service.dart';
import 'orders-page.dart';
import 'profile-page.dart';
import 'support-page.dart';
import 'settings-page.dart';

class CustomerHomePage extends StatefulWidget {
  final String userEmail;

  const CustomerHomePage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _CustomerHomePageState createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    BasketService().init();
    OrderService().init(customerEmail: widget.userEmail);
    BasketService().addListener(_onBasketChanged);
    _pages = [
      CollectionsPage(userEmail: widget.userEmail, isSellerView: false),
      BasketPage(
        customerEmail: widget.userEmail,
        onOrderPlaced: () {
          setState(() => _selectedIndex = 2);
        },
      ),
      const OrdersPage(),
      const GalleryPage(),
      _ContactUsPage(),
    ];
  }

  @override
  void dispose() {
    BasketService().removeListener(_onBasketChanged);
    super.dispose();
  }

  void _onBasketChanged() {
    if (mounted) setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Our Masterpieces';
      case 1:
        return 'Basket';
      case 2:
        return 'Orders';
      case 3:
        return 'Gallery';
      case 4:
        return 'Contact';
      default:
        return 'Craftelle';
    }
  }

  void _showProfileMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Header
              CircleAvatar(
                backgroundColor: const Color(0xFFFDA4AF),
                radius: 40,
                child: Text(
                  widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.userEmail,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Customer',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Divider(height: 32),

              // Menu Options
              ListTile(
                leading: const Icon(Icons.person_outline, color: Color(0xFFFDA4AF)),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(userEmail: widget.userEmail),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Color(0xFFFDA4AF)),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingsPage(userEmail: widget.userEmail),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.support_agent, color: Color(0xFFFDA4AF)),
                title: const Text('Support'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupportPage(
                        userEmail: widget.userEmail,
                        userRole: 'Customer',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.policy_outlined, color: Color(0xFFFDA4AF)),
                title: const Text('Payment Policy'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const _PaymentPolicyPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 20),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        centerTitle: true,
        backgroundColor: const Color(0xFFFDA4AF),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                _showProfileMenu(context);
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Text(
                  widget.userEmail.isNotEmpty ? widget.userEmail[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Color(0xFFFDA4AF),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFFDA4AF),
        unselectedItemColor: Colors.black54,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_basket),
                if (BasketService().itemCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '${BasketService().itemCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Basket',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.contact_mail),
            label: 'Contact',
          ),
        ],
      ),
    );
  }
}


// Contact Page with staggered animations
class _ContactUsPage extends StatefulWidget {
  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<_ContactUsPage> with TickerProviderStateMixin {
  static const _pink = Color(0xFFFDA4AF);

  late AnimationController _headerController;
  late AnimationController _hoursController;
  late AnimationController _sectionController;
  late List<AnimationController> _cardControllers;

  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _hoursFade;
  late Animation<Offset> _hoursSlide;
  late Animation<double> _sectionFade;
  late Animation<Offset> _sectionSlide;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));

    _hoursController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _hoursFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _hoursController, curve: Curves.easeOut));
    _hoursSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: _hoursController, curve: Curves.easeOutCubic));

    _sectionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _sectionFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _sectionController, curve: Curves.easeOut));
    _sectionSlide = Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero).animate(CurvedAnimation(parent: _sectionController, curve: Curves.easeOut));

    _cardControllers = List.generate(4, (i) =>
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500)),
    );
    _cardFades = _cardControllers.map((c) =>
      Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
    ).toList();
    _cardSlides = _cardControllers.map((c) =>
      Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
    ).toList();

    // Stagger the animations
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 150), () { if (mounted) _hoursController.forward(); });
    Future.delayed(const Duration(milliseconds: 350), () { if (mounted) _sectionController.forward(); });
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 450 + (i * 120)), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _hoursController.dispose();
    _sectionController.dispose();
    for (var c in _cardControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF1F2),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _pink.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront, size: 48, color: _pink),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Get in Touch',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Business Hours Card
            FadeTransition(
              opacity: _hoursFade,
              child: SlideTransition(
                position: _hoursSlide,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFDA4AF), Color(0xFFFB7185)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: _pink.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.access_time_filled, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Business Hours', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 4),
                            Text('Monday – Sunday', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
                            SizedBox(height: 2),
                            Text('9:00 AM – 8:00 PM', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section title
            FadeTransition(
              opacity: _sectionFade,
              child: SlideTransition(
                position: _sectionSlide,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text('Reach Us On', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                ),
              ),
            ),

            // WhatsApp Card
            _buildAnimatedCard(0, Icons.chat, "Let's Talk on WhatsApp", () => _launch('https://wa.me/233500301646')),
            const SizedBox(height: 12),

            // Email Card
            _buildAnimatedCard(1, Icons.email_outlined, 'Email Us', () => _launch('https://mail.google.com/mail/?view=cm&to=niinisasah@gmail.com')),
            const SizedBox(height: 12),

            // Instagram Card
            _buildAnimatedCard(2, Icons.camera_alt_outlined, 'Follow Us on Instagram', () => _launch('https://www.instagram.com/premiumgifting_brand?igsh=aW40YTBtcTZkZXEy&utm_source=qr')),
            const SizedBox(height: 12),

            // TikTok Card
            _buildAnimatedCard(3, Icons.music_note, 'Follow Us on TikTok', () => _launch('https://www.tiktok.com/@sasah_ni?_r=1&_t=ZS-93mZf2cbMSu')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(int index, IconData icon, String title, VoidCallback onTap) {
    return FadeTransition(
      opacity: _cardFades[index],
      child: SlideTransition(
        position: _cardSlides[index],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _pink.withOpacity(0.3), width: 1.2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: _pink, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Payment Policy Page
class _PaymentPolicyPage extends StatelessWidget {
  const _PaymentPolicyPage();

  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      appBar: AppBar(
        title: const Text('Payment Policy'),
        centerTitle: true,
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Header Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _pink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.policy, color: _pinkDark, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'PAYMENT POLICY',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),

            // Policy Points
            _buildPolicyCard(
              Icons.check_circle_outline,
              'Payment validates your order.',
            ),
            const SizedBox(height: 12),
            _buildPolicyCard(
              Icons.timer_off_outlined,
              'No refund 8 hours after your order has been placed.',
            ),
            const SizedBox(height: 24),

            // Payment Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _pink.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_pink, _pinkDark],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Payment Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Payment Number', '0500301646'),
                  const Divider(height: 20),
                  _buildDetailRow('Network', 'Telecel'),
                  const Divider(height: 20),
                  _buildDetailRow('Name', 'Niini Sasah'),
                  const Divider(height: 20),
                  _buildDetailRow('Reference', 'What you ordered'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildPolicyCard(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _pink.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _pinkDark, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }
}
