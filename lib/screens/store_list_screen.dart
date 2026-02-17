import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'store_form_screen.dart';

// Download QR helper function
Future<void> _downloadQr(BuildContext context, String qrUrl, String branchName) async {
  try {
    final response = await http.get(Uri.parse(qrUrl));
    if (response.statusCode == 200) {
      await Gal.putImageBytes(response.bodyBytes, album: 'TuVale');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR de "$branchName" descargado')),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar QR: $e')),
      );
    }
  }
}

class StoreListScreen extends ConsumerWidget {
  const StoreListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    // We assume user is logged in here because this screen is accessed from Home
    final userProfileAsync = ref.watch(userProfileProvider(user!.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Sucursales')),
      body: userProfileAsync.when(
        data: (appUser) {
          if (appUser?.companyId == null) return const Center(child: Text('Error: Sin empresa'));
          
          final storesAsync = ref.watch(companyStoresProvider(appUser!.companyId!));
          return storesAsync.when(
            data: (stores) {
              if (stores.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No hay sucursales registradas', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: stores.length,
                itemBuilder: (context, index) {
                  final store = stores[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade100,
                        child: Icon(Icons.store, color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(store.branchName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(store.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (store.qrUrl != null)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'download_qr') {
                                  _downloadQr(context, store.qrUrl!, store.branchName);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'download_qr',
                                  child: Row(
                                    children: [
                                      Icon(Icons.download, size: 20),
                                      SizedBox(width: 8),
                                      Text('Descargar QR'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StoreFormScreen(store: store)),
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: userProfileAsync.valueOrNull?.role == 'admin' 
        ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StoreFormScreen()),
              );
            },
            child: const Icon(Icons.add),
          )
        : null,
    );
  }
}
