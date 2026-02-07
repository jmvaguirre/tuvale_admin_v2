import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/coupon_model_source.dart';
import 'coupon_form_screen.dart';
import 'store_list_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    // Debemos observar el perfil del usuario para obtener el companyId
    // Nota: Esto asume que el usuario tiene un perfil en 'users/{uid}' con un 'companyId'
    final userProfileAsync = ref.watch(userProfileProvider(user?.uid ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('TuVale Admin - Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: 'Mis Sucursales',
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreListScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (appUser) {
          if (appUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Usuario no encontrado', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (user != null && user.email != null) {
                        try {
                          await ref.read(firestoreServiceProvider).initializeUserAndCompany(user.uid, user.email!);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      }
                    },
                    child: const Text('Crear Perfil y Empresa'),
                  ),
                ],
              ),
            );
          }
          if (appUser.companyId == null || appUser.companyId!.isEmpty) {
            return const Center(child: Text('Sin empresa asignada.'));
          }

          final couponsAsync = ref.watch(companyCouponsProvider(appUser.companyId!));

          return couponsAsync.when(
            data: (coupons) {
              if (coupons.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No tienes cupones activos', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Presiona + para crear el primero'),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: coupons.length,
                itemBuilder: (context, index) {
                  final coupon = coupons[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CouponFormScreen(coupon: coupon)),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade200,
                            child: coupon.imageUrl != null 
                              ? Image.network(coupon.imageUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))
                              : Icon(Icons.shopping_bag_outlined, size: 32, color: Colors.grey.shade400),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          coupon.productName,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: coupon.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          coupon.isActive ? 'ACTIVO' : 'INACTIVO',
                                          style: TextStyle(
                                            color: coupon.isActive ? Colors.green.shade800 : Colors.grey.shade600,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    coupon.description ?? 'Sin descripción',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '${coupon.discountPercentage}% OFF',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '\$${coupon.discountedPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '\$${coupon.originalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CouponFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
