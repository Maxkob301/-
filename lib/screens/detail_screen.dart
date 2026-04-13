import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import 'add_edit_screen.dart';

class DetailScreen extends StatefulWidget {
  final LostFoundItem item;

  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late LostFoundItem currentItem;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    currentItem = widget.item;
  }

  Future<void> _resolveItem() async {
    try {
      await Provider.of<ItemProvider>(
        context,
        listen: false,
      ).resolveItem(currentItem.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Объявление отмечено как решённое'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при завершении объявления: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = authProvider.user?.uid == currentItem.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentItem.title),
        actions: [
          if ((isOwner || authProvider.isAdmin) && currentItem.status == 'active')
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _openEditScreen,
            ),
          if ((isOwner || authProvider.isAdmin) && currentItem.status == 'active')
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _isDeleting ? null : _showDeleteDialog,
            ),
          if ((isOwner || authProvider.isAdmin) && currentItem.status == 'active')
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
            if (currentItem.imageUrl != null && currentItem.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  currentItem.imageUrl!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Text('Не удалось загрузить изображение'),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Chip(
              label: Text(
                currentItem.type == 'lost' ? 'Потеряно' : 'Найдено',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor:
                  currentItem.type == 'lost' ? Colors.black : Colors.grey,
            ),
            const SizedBox(height: 16),
            _buildSection('Описание:', currentItem.description),
            _buildSection('Место:', currentItem.location),
            _buildSection('Категория:', currentItem.category),
            _buildSection('Район:', currentItem.district),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
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
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.black),
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
}