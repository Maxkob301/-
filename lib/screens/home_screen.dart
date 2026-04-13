import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import 'detail_screen.dart';
import 'add_edit_screen.dart';
import 'favorites_screen.dart';
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
        itemProvider.listenToNotifications();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('findBack'),
        actions: [
          if (authProvider.isAdmin)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () => _showNotifications(context),
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
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                        ),
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
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              accountName: Text(
                authProvider.isAdmin ? 'Администратор' : 'Пользователь',
              ),
              accountEmail: Text(authProvider.user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.black),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Главная'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Избранное'),
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
              leading: const Icon(Icons.delete),
              title: const Text('Корзина'),
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
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Выйти'),
              onTap: () async {
                await authProvider.logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: itemProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => itemProvider.loadInitialItems(),
              child: ListView.builder(
                controller: _scrollController,
                itemCount:
                    itemProvider.items.length + (itemProvider.isFetchingMore ? 1 : 0),
                itemBuilder: (ctx, index) {
                  if (index == itemProvider.items.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final item = itemProvider.items[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Icon(
                        item.type == 'lost' ? Icons.search : Icons.check_circle,
                        color: item.type == 'lost' ? Colors.black : Colors.grey,
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${item.category} • ${item.district}',
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          itemProvider.favorites.contains(item.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.black,
                        ),
                        onPressed: currentUser == null
                            ? null
                            : () => itemProvider.toggleFavorite(
                                  currentUser.uid,
                                  item.id,
                                ),
                      ),
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
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
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
    );
  }

  void _showNotifications(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Уведомления'),
        content: Text(
          'Новых объявлений от пользователей: ${itemProvider.notificationCount}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}