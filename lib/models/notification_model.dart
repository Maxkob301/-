import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String itemId;
  final String itemTitle;
  final String fromUserId;
  final String fromUserEmail;
  final String targetRole;
  final String targetUserId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.itemId,
    required this.itemTitle,
    required this.fromUserId,
    required this.fromUserEmail,
    required this.targetRole,
    required this.targetUserId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];

    return AppNotification(
      id: id,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      itemId: map['itemId'] as String? ?? '',
      itemTitle: map['itemTitle'] as String? ?? '',
      fromUserId: map['fromUserId'] as String? ?? '',
      fromUserEmail: map['fromUserEmail'] as String? ?? '',
      targetRole: map['targetRole'] as String? ?? 'admin',
      targetUserId: map['targetUserId'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : createdAtValue is String
              ? DateTime.tryParse(createdAtValue) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}
