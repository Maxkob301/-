import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../styles/app_styles.dart';
import 'detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, String> _itemTitles = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await itemProvider.loadNotifications(currentUser.uid);

      final titles = <String, String>{};
      for (final notification in itemProvider.notifications) {
        if (notification.itemId.isEmpty) continue;

        final item = await itemProvider.getItemById(notification.itemId);
        titles[notification.itemId] = notification.itemTitle.isNotEmpty
            ? notification.itemTitle
            : item?.title ?? 'Объявление не найдено';
      }

      if (!mounted) return;

      setState(() {
        _itemTitles
          ..clear()
          ..addAll(titles);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки уведомлений: $e')),
      );
    }
  }

  Future<void> _openNotification(AppNotification notification) async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    try {
      final item = await itemProvider.getItemById(notification.itemId);

      if (!mounted) return;

      if (item == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Объявление не найдено')),
        );
        return;
      }

      if (!notification.isRead) {
        await itemProvider.markNotificationAsRead(notification.id);
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailScreen(item: item),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка открытия уведомления: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<ItemProvider>().notifications;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Уведомления'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppStyles.primaryColor,
              ),
            )
          : notifications.isEmpty
              ? const Center(
                  child: Text(
                    'Новых уведомлений нет',
                    style: AppStyles.body,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final itemTitle = notification.itemTitle.isNotEmpty
                        ? notification.itemTitle
                        : _itemTitles[notification.itemId] ?? 'Загрузка...';

                    return Card(
                      color: AppStyles.cardColor,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: notification.isRead
                              ? AppStyles.borderColor
                              : AppStyles.primaryColor,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openNotification(notification),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    notification.isRead
                                        ? Icons.notifications_none
                                        : Icons.notifications_active,
                                    color: AppStyles.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: AppStyles.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                notification.message,
                                style: AppStyles.body,
                              ),
                              const SizedBox(height: 12),
                              _NotificationInfoRow(
                                icon: Icons.email_outlined,
                                text: notification.fromUserEmail.isEmpty
                                    ? 'Email не указан'
                                    : notification.fromUserEmail,
                              ),
                              const SizedBox(height: 8),
                              _NotificationInfoRow(
                                icon: Icons.article_outlined,
                                text: itemTitle,
                              ),
                              const SizedBox(height: 8),
                              _NotificationInfoRow(
                                icon: Icons.calendar_today_outlined,
                                text: _formatDate(notification.createdAt),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _NotificationInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NotificationInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppStyles.iconSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppStyles.small.copyWith(
              color: AppStyles.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
