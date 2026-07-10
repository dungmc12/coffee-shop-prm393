import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme/app_theme.dart';

/// Màn thanh toán trong app bằng WebView (Thành viên 3).
/// Mở trang cổng thanh toán (VNPay thật hoặc trang mô phỏng của backend)
/// ngay trong app - không cần trình duyệt ngoài.
///
/// Tự phát hiện khi thanh toán xong: URL trả về của backend chứa
/// "vnpay-return" hoặc "mock-confirm" -> báo cho màn trước biết để tải lại đơn.
class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _paid = false; // đã đi tới trang kết quả thanh toán chưa

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (url) {
          setState(() => _loading = false);
          // Trang kết quả của backend -> coi như đã thanh toán xong.
          if (url.contains('vnpay-return') || url.contains('mock-confirm')) {
            _paid = true;
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    // PopScope: khi thoát màn, báo kết quả (_paid) về màn Đơn hàng.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _paid);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cổng thanh toán'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, _paid),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}
