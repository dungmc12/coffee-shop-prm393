import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Màn hình Chat hỗ trợ khách hàng (Thành viên 1).
/// - Tin nhắn lưu thật vào SQL Server qua API (bảng Messages).
/// - Cửa hàng trả lời tự động theo từ khóa (chatbot đơn giản ở backend).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;
  // Bộ đếm giờ tự kiểm tra tin mới (để tin admin trả lời hiện ngay).
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Cứ 3 giây hỏi server xem có tin mới không -> chat gần như thời gian thực.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollNewMessages(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel(); // dừng hỏi khi rời màn chat
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  int get _userId => context.read<AuthProvider>().currentUser!.id!;

  /// Nạp đoạn chat cũ từ server.
  Future<void> _loadMessages() async {
    try {
      final messages = await ApiService.instance.getMessages(_userId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Kiểm tra tin mới định kỳ. Chỉ cập nhật khi số tin thay đổi để
  /// không vẽ lại liên tục (vd admin vừa trả lời từ web).
  Future<void> _pollNewMessages() async {
    if (_sending) return; // đang gửi thì bỏ qua lượt này
    try {
      final messages = await ApiService.instance.getMessages(_userId);
      if (!mounted || messages.length == _messages.length) return;
      setState(() => _messages = messages);
      _scrollToBottom();
    } catch (_) {
      // Lỗi mạng tạm thời thì bỏ qua, lượt sau thử lại.
    }
  }

  /// Gửi tin nhắn -> server trả về tin của mình + tin trả lời của shop.
  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textCtrl.clear();
    try {
      final newMessages = await ApiService.instance.sendMessage(_userId, text);
      if (!mounted) return;
      setState(() => _messages.addAll(newMessages));
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi tin nhắn thất bại. Kiểm tra backend đã chạy chưa.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Cuộn xuống tin nhắn mới nhất (sau khi khung hình vẽ xong).
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Tiêu đề: logo shop + trạng thái "đang hoạt động".
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                gradient: AppTheme.coffeeGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.coffee, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Coffee Shop',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Đang hoạt động',
                    style: TextStyle(fontSize: 11, color: AppTheme.success)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Danh sách tin nhắn.
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) =>
                            _MessageBubble(message: _messages[i]),
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.message,
                size: 56, color: AppTheme.primary),
          ),
          const SizedBox(height: 18),
          const Text('Xin chào! Bạn cần hỗ trợ gì?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Hỏi về giờ mở cửa, giao hàng, giá, hủy đơn...',
            style: TextStyle(color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }

  /// Ô nhập tin nhắn + nút gửi ở đáy màn hình.
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  fillColor: AppTheme.background,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Nút gửi tròn màu nâu.
            InkWell(
              onTap: _send,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: const BoxDecoration(
                  gradient: AppTheme.coffeeGradient,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Iconsax.send_1, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bong bóng 1 tin nhắn: của mình (phải, nâu) / của shop (trái, trắng).
class _MessageBubble extends StatelessWidget {
  final Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        // Giới hạn 75% chiều rộng cho dễ đọc.
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? AppTheme.primary : Colors.white,
          // Bo 4 góc, góc sát đuôi tin nhắn bo ít hơn cho giống app chat.
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: mine ? Colors.white : AppTheme.textDark,
            height: 1.4,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }
}
