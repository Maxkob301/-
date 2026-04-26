import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import '../models/request_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String> getUserRole(String uid) async {
    try {
      final documentSnapshot =
          await _firestore.collection('users').doc(uid).get();

      final data = documentSnapshot.data();
      if (data == null) return 'user';

      return data['role'] as String? ?? 'user';
    } catch (e) {
      return 'user';
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getItems(int limit) {
    return _firestore
        .collection('items')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getMoreItems(
    DocumentSnapshot<Map<String, dynamic>> lastDoc,
    int limit,
  ) async {
    return _firestore
        .collection('items')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastDoc)
        .limit(limit)
        .get();
  }

  Future<void> addItem(LostFoundItem item, String userId) async {
    final docRef = await _firestore.collection('items').add({
      'title': item.title,
      'description': item.description,
      'location': item.location,
      'date': Timestamp.fromDate(item.date),
      'type': item.type,
      'imageUrl': item.imageUrl,
      'userId': userId,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'authorEmail': item.authorEmail,
      'category': item.category,
      'district': item.district,
      'acceptedHelperId':'',
      'isLocationHidden': item.isLocationHidden,
      'latitude': item.latitude,
      'longitude': item.longitude,
      'addressText': item.addressText,
    });

    await _firestore.collection('notifications').add({
      'message': 'Новое объявление: ${item.title}',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'itemId': docRef.id,
    });
  }

  Future<void> updateItem(String docId, Map<String, dynamic> data) async {
    await _firestore.collection('items').doc(docId).update(data);
  }

  Future<void> deleteItem(String docId) async {
    await _firestore.collection('items').doc(docId).update({
      'status': 'deleted',
    });
  }

  Future<void> restoreItem(String docId) async {
    await _firestore.collection('items').doc(docId).update({
      'status': 'active',
    });
  }

  Future<void> addToFavorites(String userId, String itemId) async {
    await _firestore.collection('users').doc(userId).update({
      'favorites': FieldValue.arrayUnion([itemId]),
    });
  }

  Future<void> removeFromFavorites(String userId, String itemId) async {
    await _firestore.collection('users').doc(userId).update({
      'favorites': FieldValue.arrayRemove([itemId]),
    });
  }

  Future<List<String>> getFavorites(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();

    if (data == null) return [];

    final favorites = data['favorites'] as List<dynamic>? ?? [];
    return favorites.cast<String>();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUnreadNotifications() {
    return _firestore
        .collection('notifications')
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<List<LostFoundItem>> getDeletedItems() async {
    final snapshot = await _firestore
        .collection('items')
        .where('status', isEqualTo: 'deleted')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LostFoundItem.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<LostFoundItem>> getFavoriteItems(String userId) async {
    final favoriteIds = await getFavorites(userId);

    if (favoriteIds.isEmpty) return [];

    final snapshot = await _firestore.collection('items').get();

    return snapshot.docs
        .where((doc) => favoriteIds.contains(doc.id))
        .map((doc) => LostFoundItem.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> ensureUserDocument(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'email': user.email ?? '',
        'role': user.email == 'admin@test.com' ? 'admin' : 'user',
        'favorites': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> resolveItem(String docId) async {
    await _firestore.collection('items').doc(docId).update({
      'status': 'resolved',
    });

    await cleanupResolvedItems();
  }

  Future<void> cleanupResolvedItems() async {
    final snapshot = await _firestore
        .collection('items')
        .where('status', isEqualTo: 'resolved')
        .orderBy('createdAt', descending: false)
        .get();

    if (snapshot.docs.length > 5) {
      final docsToArchive = snapshot.docs.take(snapshot.docs.length - 5);

      for (final doc in docsToArchive) {
        await _firestore.collection('items').doc(doc.id).update({
          'status': 'deleted',
        });
      }
    }
  }

  Future<void> createRequest({
    required String itemId,
    required String ownerUserId,
    required String requesterUserId,
    required String requesterEmail,
    required String message,
    required List<String> imageUrls,
  }) async {
    final existing = await _firestore
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .where('requesterUserId', isEqualTo: requesterUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('У вас уже есть активная заявка на это объявление');
    }

    await _firestore.collection('requests').add({
      'itemId': itemId,
      'ownerUserId': ownerUserId,
      'requesterUserId': requesterUserId,
      'requesterEmail': requesterEmail,
      'message': message,
      'status': 'pending',
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<ItemRequest>> getRequestsForItem(String itemId) async {
    final snapshot = await _firestore
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ItemRequest.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> acceptRequest({
    required String requestId,
    required String itemId,
    required String requesterUserId,
  }) async {
    final batch = _firestore.batch();

    final requestRef = _firestore.collection('requests').doc(requestId);
    final itemRef = _firestore.collection('items').doc(itemId);

    batch.update(requestRef, {
      'status': 'accepted',
    });

    batch.update(itemRef, {
      'acceptedHelperId': requesterUserId,
    });

    final otherRequests = await _firestore
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in otherRequests.docs) {
      if (doc.id != requestId) {
        batch.update(doc.reference, {
          'status': 'rejected',
        });
      }
    }

    await batch.commit();
  }

  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'rejected',
    });
  }
}