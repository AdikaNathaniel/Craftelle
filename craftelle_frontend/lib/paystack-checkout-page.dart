import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaystackCheckoutPage extends StatefulWidget {
  final String authorizationUrl;
  final String callbackUrl;

  const PaystackCheckoutPage({
    Key? key,
    required this.authorizationUrl,
    required this.callbackUrl,
  }) : super(key: key);

  @override
  _PaystackCheckoutPageState createState() => _PaystackCheckoutPageState();
}

class _PaystackCheckoutPageState extends State<PaystackCheckoutPage> {
  static const _pink = Color(0xFFFDA4AF);
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            // Detect callback redirect from Paystack
            if (url.startsWith(widget.callbackUrl)) {
              final uri = Uri.parse(url);
              final reference = uri.queryParameters['reference'] ??
                  uri.queryParameters['trxref'];
              // Return the reference to the calling page
              Navigator.pop(context, reference);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        centerTitle: true,
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // User cancelled — return null
            Navigator.pop(context, null);
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: _pink),
            ),
        ],
      ),
    );
  }
}
