import 'package:cloud_firestore/cloud_firestore.dart';

class ItemRequest {
  final String id;
  final String itemId;
  final String ownerUserId;
  final String requesterUserId;
  final String requesterEmail;
  final String message;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;
  final List<String> imageUrls;
  

  ItemRequest({
    required this.id,
    required this.itemId,
    required this.ownerUserId,
    required this.requesterUserId,
    required this.requesterEmail,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.imageUrls,
    
  });

  factory ItemRequest.fromMap(String id, Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];

    return ItemRequest(
      id: id,
      itemId: map['itemId'] as String? ?? '',
      ownerUserId: map['ownerUserId'] as String? ?? '',
      requesterUserId: map['requesterUserId'] as String? ?? '',
      requesterEmail: map['requesterEmail'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : createdAtValue is String
              ? DateTime.tryParse(createdAtValue) ?? DateTime.now()
              : DateTime.now(),
      imageUrls: (map['imageUrls'] as List<dynamic>? ?? [])
          .map((url) => url.toString())
          .toList(),
    );
  }
}