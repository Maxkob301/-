import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/item_model.dart';
import '../models/request_model.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../services/cloudinary_service.dart';
import '../styles/app_styles.dart';
import 'add_edit_screen.dart';
import 'map_view_screen.dart';

class DetailScreen extends StatefulWidget {
  final LostFoundItem item;

  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late LostFoundItem currentItem;
  bool _isDeleting = false;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    currentItem = widget.item;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequestsIfNeeded();
    });
  }

  Future<void> _loadRequestsIfNeeded() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.user?.uid == currentItem.userId;

    if (isOwner || authProvider.isAdmin) {
      await Provider.of<ItemProvider>(context, listen: false)
          .loadRequestsForItem(currentItem.id);
    }
  }

  Future<void> _resolveItem() async {
    try {
      await Provider.of<ItemProvider>(
        context,
        listen: false,
      ).resolveItem(currentItem.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Объявление отмечено как решённое')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при завершении объявления: $e')),
      );
    }
  }

  Future<void> _openEditScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(item: currentItem),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      final updatedItems =
          Provider.of<ItemProvider>(context, listen: false).items;

      try {
        final updatedItem =
            updatedItems.firstWhere((item) => item.id == currentItem.id);

        setState(() {
          currentItem = updatedItem;
        });
      } catch (_) {}
    }
  }

  Future<void> _showDeleteDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить объявление?'),
        content: const Text('Объявление будет перемещено в корзину'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppStyles.primaryColor,
            ),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppStyles.primaryColor,
            ),
            child: const Text(
              'Удалить',
              style: TextStyle(color: AppStyles.primaryColor),
            ),
          ),
        ],
      ),
    );

    if (!mounted || shouldDelete != true) return;

    setState(() => _isDeleting = true);

    try {
      await Provider.of<ItemProvider>(
        context,
        listen: false,
      ).deleteItem(currentItem.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Объявление удалено')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _showRequestDialog() async {
    final controller = TextEditingController();
    final List<XFile> selectedImages = [];
    bool isUploading = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: !isUploading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImages() async {
              if (selectedImages.length >= 3) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Можно прикрепить не больше 3 фото'),
                  ),
                );
                return;
              }

              final images = await _picker.pickMultiImage();

              if (images.isEmpty) return;

              final freeSlots = 3 - selectedImages.length;
              selectedImages.addAll(images.take(freeSlots));

              setDialogState(() {});
            }

            return AlertDialog(
              title: const Text('Отклик на объявление'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: AppStyles.inputDecoration(
                        'Сообщение',
                      ).copyWith(
                        hintText: 'Напишите короткое сообщение владельцу',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isUploading ? null : pickImages,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppStyles.primaryColor,
                        ),
                        icon: const Icon(
                          Icons.photo,
                          color: AppStyles.iconColor,
                        ),
                        label: Text(
                          selectedImages.isEmpty
                              ? 'Прикрепить фото'
                              : 'Фото выбрано: ${selectedImages.length}/3',
                        ),
                      ),
                    ),
                    if (selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedImages.map((image) {
                          final index = selectedImages.indexOf(image);

                          return Chip(
                            label: Text('Фото ${index + 1}'),
                            deleteIcon: const Icon(
                              Icons.close,
                              color: AppStyles.iconColor,
                            ),
                            onDeleted: isUploading
                                ? null
                                : () {
                                    selectedImages.removeAt(index);
                                    setDialogState(() {});
                                  },
                          );
                        }).toList(),
                      ),
                    ],
                    if (isUploading) ...[
                      const SizedBox(height: 12),
                      const CircularProgressIndicator(
                        color: AppStyles.primaryColor,
                      ),
                      const SizedBox(height: 8),
                      const Text('Загрузка фото...'),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppStyles.primaryColor,
                  ),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          final text = controller.text.trim();

                          if (text.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Введите сообщение перед отправкой'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isUploading = true;
                          });

                          try {
                            final imageUrls = await _cloudinaryService
                                .uploadImages(selectedImages);

                            if (!dialogContext.mounted) return;

                            Navigator.of(dialogContext).pop({
                              'message': text,
                              'imageUrls': imageUrls,
                            });
                          } catch (e) {
                            setDialogState(() {
                              isUploading = false;
                            });

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка загрузки фото: $e'),
                              ),
                            );
                          }
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: AppStyles.primaryColor,
                  ),
                  child: const Text('Отправить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    final message = result['message'] as String? ?? '';
    final imageUrls = (result['imageUrls'] as List<dynamic>? ?? [])
        .map((url) => url.toString())
        .toList();

    if (message.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите сообщение для владельца')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) return;

    try {
      await Provider.of<ItemProvider>(context, listen: false).createRequest(
        itemId: currentItem.id,
        ownerUserId: currentItem.userId,
        requesterUserId: currentUser.uid,
        requesterEmail: currentUser.email ?? '',
        message: message,
        imageUrls: imageUrls,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка отправлена')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки заявки: $e')),
      );
    }
  }

  Future<void> _acceptRequest(ItemRequest request) async {
    try {
      await Provider.of<ItemProvider>(context, listen: false).acceptRequest(
        requestId: request.id,
        itemId: currentItem.id,
        requesterUserId: request.requesterUserId,
      );

      if (!mounted) return;

      setState(() {
        currentItem = LostFoundItem(
          id: currentItem.id,
          title: currentItem.title,
          description: currentItem.description,
          location: currentItem.location,
          date: currentItem.date,
          type: currentItem.type,
          imageUrl: currentItem.imageUrl,
          imageUrls: currentItem.imageUrls,
          userId: currentItem.userId,
          status: currentItem.status,
          createdAt: currentItem.createdAt,
          authorEmail: currentItem.authorEmail,
          category: currentItem.category,
          district: currentItem.district,
          acceptedHelperId: request.requesterUserId,
          isLocationHidden: currentItem.isLocationHidden,
          latitude: currentItem.latitude,
          longitude: currentItem.longitude,
          addressText: currentItem.addressText,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка принята')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка принятия заявки: $e')),
      );
    }
  }

  Future<void> _rejectRequest(ItemRequest request) async {
    try {
      await Provider.of<ItemProvider>(context, listen: false).rejectRequest(
        requestId: request.id,
        itemId: currentItem.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка отклонена')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отклонения заявки: $e')),
      );
    }
  }

  Widget _buildSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.subtitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppStyles.body.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestImages(List<String> imageUrls) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: imageUrls.map((url) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: AppStyles.borderColor,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image,
                    color: AppStyles.iconColor,
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Активно';
      case 'resolved':
        return 'Решено';
      case 'deleted':
        return 'Удалено';
      default:
        return status;
    }
  }

  String _getRequestStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Ожидает';
      case 'accepted':
        return 'Принята';
      case 'rejected':
        return 'Отклонена';
      default:
        return status;
    }
  }

  void _openImageViewer(String imageUrl) {
  showDialog(
    context: context,
    builder: (_) => GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: AppStyles.primaryColor,
        child: Center(
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildRequestsSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);

    final isOwner = authProvider.user?.uid == currentItem.userId;
    if (!isOwner && !authProvider.isAdmin) {
      return const SizedBox.shrink();
    }

    if (itemProvider.isLoadingRequests) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppStyles.primaryColor,
        ),
      );
    }

    if (itemProvider.requests.isEmpty) {
      return const Text('Заявок пока нет');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Заявки',
          style: AppStyles.title,
        ),
        const SizedBox(height: 12),
        ...itemProvider.requests.map((request) {
          return Card(
            color: AppStyles.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppStyles.borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  request.requesterEmail.isEmpty
                      ? 'Пользователь'
                      : request.requesterEmail,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.message),
                    const SizedBox(height: 4),
                    Text('Статус: ${_getRequestStatusText(request.status)}'),
                    _buildRequestImages(request.imageUrls),
                  ],
                ),
                isThreeLine: true,
                trailing: request.status == 'pending'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppStyles.iconColor,
                            ),
                            onPressed: () => _rejectRequest(request),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: AppStyles.iconColor,
                            ),
                            onPressed: () => _acceptRequest(request),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    final isOwner = currentUser?.uid == currentItem.userId;

    final canSeeLocation =
        authProvider.isAdmin ||
        currentUser?.uid == currentItem.userId ||
        currentItem.acceptedHelperId == currentUser?.uid ||
        currentItem.isLocationHidden == false;

    final canSendRequest =
        currentUser != null &&
        currentUser.uid != currentItem.userId &&
        !authProvider.isAdmin &&
        currentItem.status == 'active' &&
        currentItem.acceptedHelperId.isEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        title: Text(currentItem.title),
        actions: [
          if ((isOwner || authProvider.isAdmin) &&
              currentItem.status == 'active')
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _openEditScreen,
            ),
          if ((isOwner || authProvider.isAdmin) &&
              currentItem.status == 'active')
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _isDeleting ? null : _showDeleteDialog,
            ),
          if ((isOwner || authProvider.isAdmin) &&
              currentItem.status == 'active')
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              onPressed: _resolveItem,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentItem.imageUrls.isNotEmpty) ...[
  GestureDetector(
    onTap: () => _openImageViewer(currentItem.imageUrls[_selectedImageIndex]),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 250,
        width: double.infinity,
        color: AppStyles.primaryColor,
        child: Image.network(
          currentItem.imageUrls[_selectedImageIndex],
          fit: BoxFit.contain,
        ),
      ),
    ),
  ),

  const SizedBox(height: 8),

  SizedBox(
    height: 70,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: currentItem.imageUrls.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final url = currentItem.imageUrls[index];

        final isSelected = index == _selectedImageIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedImageIndex = index;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? AppStyles.primaryColor
                    : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                url,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    ),
  ),
  const SizedBox(height: 16),
],

            const SizedBox(height: 16),
            Chip(
              label: Text(
                currentItem.type == 'lost' ? 'Потеряно' : 'Найдено',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor:
                  currentItem.type == 'lost'
                      ? AppStyles.primaryColor
                      : AppStyles.iconSecondary,
            ),
            const SizedBox(height: 16),
            _buildSection('Описание:', currentItem.description),
            _buildSection(
              'Район:',
              canSeeLocation ? currentItem.district : 'Скрыто',
            ),
            _buildSection(
              'Место:',
              canSeeLocation ? currentItem.location : 'Скрыто',
            ),
            _buildSection('Категория:', currentItem.category),
            _buildSection(
              'Автор:',
              currentItem.authorEmail.isEmpty
                  ? 'Не указан'
                  : currentItem.authorEmail,
            ),
            _buildSection('Статус:', _getStatusText(currentItem.status)),
            _buildSection(
              'Дата:',
              '${currentItem.date.day}.${currentItem.date.month}.${currentItem.date.year}',
            ),
            _buildSection(
              'Адрес:',
              canSeeLocation
                  ? (currentItem.addressText.isEmpty
                      ? 'Не указан'
                      : currentItem.addressText)
                  : 'Скрыто',
            ),
            if (canSeeLocation &&
                currentItem.latitude != null &&
                currentItem.longitude != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppStyles.primaryColor,
                  ),
                  icon: const Icon(Icons.map, color: AppStyles.iconColor),
                  label: const Text('Показать на карте'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapViewScreen(
                          latitude: currentItem.latitude!,
                          longitude: currentItem.longitude!,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (canSendRequest) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showRequestDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Откликнуться'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildRequestsSection(),
          ],
        ),
      ),
    );
  }
}
