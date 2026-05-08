class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String? content;
  final String? imageUrl;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
    this.content,
    this.imageUrl,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String,
        senderId: j['sender_id'] as String,
        receiverId: j['receiver_id'] as String,
        content: j['content'] as String?,
        imageUrl: j['image_url'] as String?,
        createdAt:
            DateTime.parse(j['created_at'] as String).toLocal(),
      );

  bool get isImage => imageUrl != null;
}
