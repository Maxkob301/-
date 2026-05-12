import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../styles/app_styles.dart';
import 'detail_screen.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  bool _isLoadingTrash = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<ItemProvider>(context, listen: false).loadDeletedItems();

      if (mounted) {
        setState(() {
          _isLoadingTrash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Корзина'),
      ),
      body: _isLoadingTrash
          ? const Center(
              child: CircularProgressIndicator(
                color: AppStyles.primaryColor,
              ),
            )
          : itemProvider.deletedItems.isEmpty
              ? const Center(child: Text('Корзина пуста'))
              : ListView.builder(
                  itemCount: itemProvider.deletedItems.length,
                  itemBuilder: (ctx, index) {
                    final item = itemProvider.deletedItems[index];

                    return Card(
                      color: AppStyles.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppStyles.borderColor),
                      ),
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
                              ? AppStyles.iconColor
                              : AppStyles.iconSecondary,
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${item.category} • ${item.district}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.restore,
                            color: AppStyles.iconColor,
                          ),
                          onPressed: () async {
                            try {
                              await itemProvider.restoreItem(item.id);

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Объявление восстановлено'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ошибка восстановления: $e'),
                                ),
                              );
                            }
                          },
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(item: item),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
