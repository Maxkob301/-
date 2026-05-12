import 'package:cloud_firestore/cloud_firestore.dart';

class LostFoundItem {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String type;

  
  final String? imageUrl;

  
  final List<String> imageUrls;

  final String userId;
  final String status;
  final DateTime createdAt;

  final String authorEmail;
  final String category;
  final String district;

  final String acceptedHelperId;
  final bool isLocationHidden;

  final double? latitude;
  final double? longitude;

  final String addressText;

  LostFoundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.type,
    this.imageUrl,
    required this.imageUrls,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.authorEmail,
    required this.category,
    required this.district,
    required this.acceptedHelperId,
    required this.isLocationHidden,
    this.latitude,
    this.longitude,
    required this.addressText,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'type': type,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : imageUrl,
      'imageUrls': imageUrls,
      'userId': userId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorEmail': authorEmail,
      'category': category,
      'district': district,
      'acceptedHelperId': acceptedHelperId,
      'isLocationHidden': isLocationHidden,
      'latitude': latitude,
      'longitude': longitude,
      'addressText': addressText,
    };
  }

  factory LostFoundItem.fromMap(String id, Map<String, dynamic> map) {
    final dateValue = map['date'];
    final createdAtValue = map['createdAt'];

    final List<String> parsedImageUrls =
        (map['imageUrls'] as List<dynamic>? ?? [])
            .map((url) => url.toString())
            .where((url) => url.isNotEmpty)
            .toList();

    final String? oldImageUrl = map['imageUrl'] as String?;

    final List<String> finalImageUrls = parsedImageUrls.isNotEmpty
        ? parsedImageUrls
        : oldImageUrl != null && oldImageUrl.isNotEmpty
            ? [oldImageUrl]
            : [];

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
      imageUrl: finalImageUrls.isNotEmpty ? finalImageUrls.first : oldImageUrl,
      imageUrls: finalImageUrls,
      userId: map['userId'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : createdAtValue is String
              ? DateTime.tryParse(createdAtValue) ?? DateTime.now()
              : DateTime.now(),
      authorEmail: map['authorEmail'] as String? ?? '',
      category: map['category'] as String? ?? 'Другое',
      district: map['district'] as String? ?? 'Другой',
      acceptedHelperId: map['acceptedHelperId'] as String? ?? '',
      isLocationHidden: map['isLocationHidden'] as bool? ?? true,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      addressText: map['addressText'] as String? ?? '',
    );
  }
}