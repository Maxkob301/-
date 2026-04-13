import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoadingFavorites = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);

      final user = authProvider.user;
      if (user != null) {
        await itemProvider.loadFavoriteItems(user.uid);
      }

      if (mounted) {
        setState(() {
          _isLoadingFavorites = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);

    final currentUser = authProvider.user;
    final favoriteItems = itemProvider.favoriteItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
      ),
      body: _isLoadingFavorites
          ? const Center(child: CircularProgressIndicator())
          : currentUser == null
              ? const Center(child: Text('Пользователь не авторизован'))
              : favoriteItems.isEmpty
                  ? const Center(child: Text('Нет избранных объявлений'))
                  : ListView.builder(
                      itemCount: favoriteItems.length,
                      itemBuilder: (ctx, index) {
                        final item = favoriteItems[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: Icon(
                              item.type == 'lost'
                                  ? Icons.search
                                  : Icons.check_circle,
                              color: item.type == 'lost'
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                            title: Text(item.title),
                            subtitle: Text('${item.category} • ${item.district}'),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.favorite,
                                color: Colors.black,
                              ),
                              onPressed: () async {
                                await itemProvider.toggleFavorite(
                                  currentUser.uid,
                                  item.id,
                                );
                              },
                            ),
                            onTap: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(item: item),
                                ),
                              );

                              if (!mounted) return;

                              if (result == true) {
                                await itemProvider.loadFavoriteItems(
                                  currentUser.uid,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}