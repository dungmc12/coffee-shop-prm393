/// Model Message - 1 tin nhắn trong đoạn chat hỗ trợ.
/// sender = 'user' (mình gửi) hoặc 'shop' (cửa hàng trả lời).
class Message {
  final int? id;
  final int userId;
  final String sender;
  final String text;
  final String createdAt;

  Message({
    this.id,
    required this.userId,
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  /// Tin nhắn này do mình (khách) gửi hay không.
  bool get isMine => sender == 'user';

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        userId: json['userId'],
        sender: json['sender'] ?? 'user',
        text: json['text'] ?? '',
        createdAt: json['createdAt'] ?? '',
      );
}
