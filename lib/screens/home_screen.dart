import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../styles/app_styles.dart';
import 'detail_screen.dart';
import 'add_edit_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'trash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);

      await itemProvider.loadInitialItems();

      final currentUser = authProvider.user;
      if (currentUser != null) {
        await itemProvider.loadFavorites(currentUser.uid);
      }

      if (authProvider.isAdmin) {
        itemProvider.listenToNotifications(currentUser?.uid ?? '');
      }
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      itemProvider.loadMoreItems();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);
    final currentUser = authProvider.user;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppStyles.primaryColor,
              secondary: AppStyles.primaryColor,
            ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('findBack', style: AppStyles.title),
          backgroundColor: AppStyles.primaryColor,
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (authProvider.isAdmin)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                      ),
                      if (itemProvider.notificationCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${itemProvider.notificationCount}',
                              style:
                                  AppStyles.small.copyWith(color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.white),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    );

                    if (!context.mounted) return;

                    if (currentUser != null) {
                      await Provider.of<ItemProvider>(context, listen: false)
                          .loadFavorites(currentUser.uid);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: AppStyles.primaryColor),
                accountName: Text(
                  authProvider.isAdmin ? 'Администратор' : 'Пользователь',
                  style: AppStyles.subtitle.copyWith(color: Colors.white),
                ),
                accountEmail: Text(
                  authProvider.user?.email ?? '',
                  style: AppStyles.body.copyWith(color: Colors.white70),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.black),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: AppStyles.primaryColor),
                title: const Text('Главная', style: AppStyles.body),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading:
                    const Icon(Icons.favorite, color: AppStyles.primaryColor),
                title: const Text('Избранное', style: AppStyles.body),
                onTap: () async {
                  Navigator.pop(context);

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FavoritesScreen(),
                    ),
                  );

                  if (!context.mounted) return;

                  if (currentUser != null) {
                    await Provider.of<ItemProvider>(context, listen: false)
                        .loadFavorites(currentUser.uid);
                  }
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete, color: AppStyles.primaryColor),
                title: const Text('Корзина', style: AppStyles.body),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrashScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.exit_to_app,
                    color: AppStyles.primaryColor),
                title: const Text('Выйти', style: AppStyles.body),
                onTap: () async {
                  await authProvider.logout();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
        body: itemProvider.isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppStyles.primaryColor,
                ),
              )
            : RefreshIndicator(
                color: AppStyles.primaryColor,
                onRefresh: () => itemProvider.loadInitialItems(),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: itemProvider.items.length +
                      (itemProvider.isFetchingMore ? 1 : 0),
                  itemBuilder: (ctx, index) {
                    if (index == itemProvider.items.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: AppStyles.primaryColor,
                          ),
                        ),
                      );
                    }

                    final item = itemProvider.items[index];
                    final isFavorite = itemProvider.favorites.contains(item.id);
                    final isLost = item.type == 'lost';
                    final isActive = item.status == 'active';
                    final typeText = isLost ? 'Потеряно' : 'Найдено';
                    final statusText = isActive ? 'active' : 'resolved';
                    final dateText =
                        '${item.date.day}.${item.date.month}.${item.date.year}';

                    return Card(
                      color: AppStyles.cardColor,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: AppStyles.borderColor,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(item: item),
                            ),
                          );

                          if (!context.mounted) return;

                          if (result == true) {
                            await Provider.of<ItemProvider>(
                              context,
                              listen: false,
                            ).loadInitialItems();

                            if (!context.mounted) return;

                            if (currentUser != null) {
                              await Provider.of<ItemProvider>(
                                context,
                                listen: false,
                              ).loadFavorites(currentUser.uid);
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppStyles.backgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppStyles.borderColor,
                                      ),
                                    ),
                                    child: Icon(
                                      isLost
                                          ? Icons.search
                                          : Icons.check_circle_outline,
                                      color: AppStyles.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: AppStyles.subtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              isLost
                                                  ? Icons.error_outline
                                                  : Icons.task_alt,
                                              size: 16,
                                              color: AppStyles.iconSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              typeText,
                                              style: AppStyles.small.copyWith(
                                                color: AppStyles.primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    color: AppStyles.primaryColor,
                                    disabledColor: AppStyles.iconSecondary,
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                    ),
                                    onPressed: currentUser == null
                                        ? null
                                        : () => itemProvider.toggleFavorite(
                                              currentUser.uid,
                                              item.id,
                                            ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.description,
                                style: AppStyles.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppStyles.backgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppStyles.borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.category_outlined,
                                          size: 16,
                                          color: AppStyles.iconSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.category,
                                          style: AppStyles.small.copyWith(
                                            color: AppStyles.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppStyles.backgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppStyles.borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.place_outlined,
                                          size: 16,
                                          color: AppStyles.iconSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.district,
                                          style: AppStyles.small.copyWith(
                                            color: AppStyles.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppStyles.backgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppStyles.borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: AppStyles.iconSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          dateText,
                                          style: AppStyles.small.copyWith(
                                            color: AppStyles.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppStyles.cardColor
                                          : AppStyles.backgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isActive
                                            ? AppStyles.primaryColor
                                            : AppStyles.borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isActive
                                              ? Icons.radio_button_checked
                                              : Icons.check_circle_outline,
                                          size: 16,
                                          color: isActive
                                              ? AppStyles.primaryColor
                                              : AppStyles.iconSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          statusText,
                                          style: AppStyles.small.copyWith(
                                            color: isActive
                                                ? AppStyles.primaryColor
                                                : AppStyles.iconSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.touch_app_outlined,
                                    size: 16,
                                    color: AppStyles.iconSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Нажмите для подробностей',
                                    style: AppStyles.small,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const AddEditScreen(),
              ),
            );

            if (!context.mounted) return;

            if (result == true) {
              await Provider.of<ItemProvider>(context, listen: false)
                  .loadInitialItems();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
