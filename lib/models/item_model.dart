import 'package:cloud_firestore/cloud_firestore.dart';

class LostFoundItem {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String type;
  final String? imageUrl;
  final String userId;
  final String status;
  final DateTime createdAt;
  final String authorEmail;
  final String category;
  final String district;

  LostFoundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.type,
    this.imageUrl,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.authorEmail,
    required this.category,
    required this.district,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'type': type,
      'imageUrl': imageUrl,
      'userId': userId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorEmail': authorEmail,
      'category': category,
      'district': district,
    };
  }

  factory LostFoundItem.fromMap(String id, Map<String, dynamic> map) {
    final dateValue = map['date'];
    final createdAtValue = map['createdAt'];

    return LostFoundItem(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      date: dateValue is Timestamp
          ? dateValue.toDate()
          : dateValue is String
              ? DateTime.tryParse(dateValue) ?? DateTime.now()
              : DateTime.now(),
      type: map['type'] as String? ?? 'lost',
      imageUrl: map['imageUrl'] as String?,
      userId: map['userId'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : createdAtValue is String
              ? DateTime.tryParse(createdAtValue) ?? DateTime.now()
              : DateTime.now(),
      authorEmail: map['authorEmail'] as String? ?? '',
      category: map['category'] as String? ?? 'Другое',
      district: map['district'] as String? ?? 'Не указан',
    );
  }
}