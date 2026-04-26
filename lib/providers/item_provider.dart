import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../services/firebase_service.dart';
import '../models/request_model.dart';

class ItemProvider extends ChangeNotifier {
  final FirebaseService _service = FirebaseService();

  List<LostFoundItem> _items = [];
  List<LostFoundItem> _deletedItems = [];
  List<String> _favorites = [];
  List<LostFoundItem> _favoriteItems = [];

  List<ItemRequest> _requests = [];
  bool _isLoadingRequests = false;

  List<ItemRequest> get requests => List.unmodifiable(_requests);
  bool get isLoadingRequests => _isLoadingRequests;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  int _notificationCount = 0;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationSubscription;

  List<LostFoundItem> get items => List.unmodifiable(_items);
  List<LostFoundItem> get deletedItems => List.unmodifiable(_deletedItems);
  List<String> get favorites => List.unmodifiable(_favorites);
  List<LostFoundItem> get favoriteItems => List.unmodifiable(_favoriteItems);

  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  int get notificationCount => _notificationCount;

  Future<void> loadInitialItems() async {
    _isLoading = true;
    _items = [];
    _lastDocument = null;
    _hasMore = true;
    notifyListeners();

    try {
      final snapshot = await _service.getItems(5).first;

      _items = snapshot.docs
          .map((doc) => LostFoundItem.fromMap(doc.id, doc.data()))
          .toList();

      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMore = snapshot.docs.length == 5;
    } catch (e) {
      debugPrint('Ошибка загрузки объявлений: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreItems() async {
    if (!_hasMore || _lastDocument == null || _isFetchingMore) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      final snapshot = await _service.getMoreItems(_lastDocument!, 5);

      final newItems = snapshot.docs
          .map((doc) => LostFoundItem.fromMap(doc.id, doc.data()))
          .toList();

      _items.addAll(newItems);
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMore = snapshot.docs.length == 5;
    } catch (e) {
      debugPrint('Ошибка подгрузки объявлений: $e');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> addItem(LostFoundItem item, String userId) async {
    try {
      debugPrint('PROVIDER addItem: '
          'authorEmail=${item.authorEmail}, '
          'category=${item.category}, '
          'district=${item.district}');
      await _service.addItem(item, userId);
      await loadInitialItems();
    } catch (e) {
      debugPrint('Ошибка добавления объявления: $e');
      rethrow;
    }
  }

  Future<void> resolveItem(String id) async {
  try {
    await _service.resolveItem(id);
    await loadInitialItems();
    await loadDeletedItems();
    await refreshFavoriteItemsAfterChange(id);
  } catch (e) {
    debugPrint('Ошибка завершения объявления: $e');
    rethrow;
  }
}

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateItem(id, data);
      await loadInitialItems();
    } catch (e) {
      debugPrint('Ошибка обновления объявления: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _service.deleteItem(id);
      await loadInitialItems();
      await loadDeletedItems();
      await refreshFavoriteItemsAfterChange(id);
    } catch (e) {
      debugPrint('Ошибка удаления объявления: $e');
      rethrow;
    }
  }

  Future<void> restoreItem(String id) async {
    try {
      await _service.restoreItem(id);
      await loadInitialItems();
      await loadDeletedItems();
      await refreshFavoriteItems();
    } catch (e) {
      debugPrint('Ошибка восстановления объявления: $e');
      rethrow;
    }
  }

  Future<void> loadDeletedItems() async {
    try {
      _deletedItems = await _service.getDeletedItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка загрузки удалённых объявлений: $e');
    }
  }

  Future<void> loadFavorites(String userId) async {
    try {
      _favorites = await _service.getFavorites(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка загрузки избранного: $e');
    }
  }

  Future<void> loadFavoriteItems(String userId) async {
    try {
      _favoriteItems = await _service.getFavoriteItems(userId);
      _favorites = _favoriteItems.map((item) => item.id).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка загрузки избранных объявлений: $e');
    }
  }

  Future<void> toggleFavorite(String userId, String itemId) async {
    try {
      if (_favorites.contains(itemId)) {
        await _service.removeFromFavorites(userId, itemId);
        _favorites.remove(itemId);
        _favoriteItems.removeWhere((item) => item.id == itemId);
      } else {
        await _service.addToFavorites(userId, itemId);
        _favorites.add(itemId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка изменения избранного: $e');
      rethrow;
    }
  }

  Future<void> refreshFavoriteItems() async {
    _favoriteItems = _favoriteItems
        .where((item) => item.status == 'active')
        .toList();
    notifyListeners();
  }

  Future<void> refreshFavoriteItemsAfterChange(String removedItemId) async {
    _favoriteItems.removeWhere((item) => item.id == removedItemId);
    _favorites.remove(removedItemId);
    notifyListeners();
  }

  void listenToNotifications() {
    _notificationSubscription?.cancel();

    _notificationSubscription =
        _service.getUnreadNotifications().listen((snapshot) {
      _notificationCount = snapshot.docs.length;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> createRequest({
  required String itemId,
  required String ownerUserId,
  required String requesterUserId,
  required String requesterEmail,
  required String message,
  required List<String> imageUrls,
}) async {
  try {
    await _service.createRequest(
      itemId: itemId,
      ownerUserId: ownerUserId,
      requesterUserId: requesterUserId,
      requesterEmail: requesterEmail,
      message: message,
      imageUrls: imageUrls,
    );
  } catch (e) {
    debugPrint('Ошибка создания заявки: $e');
    rethrow;
  }
}

Future<void> loadRequestsForItem(String itemId) async {
  _isLoadingRequests = true;
  notifyListeners();

  try {
    _requests = await _service.getRequestsForItem(itemId);
  } catch (e) {
    debugPrint('Ошибка загрузки заявок: $e');
  } finally {
    _isLoadingRequests = false;
    notifyListeners();
  }
}

Future<void> acceptRequest({
  required String requestId,
  required String itemId,
  required String requesterUserId,
}) async {
  try {
    await _service.acceptRequest(
      requestId: requestId,
      itemId: itemId,
      requesterUserId: requesterUserId,
    );
    await loadRequestsForItem(itemId);
    await loadInitialItems();
  } catch (e) {
    debugPrint('Ошибка принятия заявки: $e');
    rethrow;
  }
}

Future<void> rejectRequest({
  required String requestId,
  required String itemId,
}) async {
  try {
    await _service.rejectRequest(requestId);
    await loadRequestsForItem(itemId);
  } catch (e) {
    debugPrint('Ошибка отклонения заявки: $e');
    rethrow;
  }
}
}