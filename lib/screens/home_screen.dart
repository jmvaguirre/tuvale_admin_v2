import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/coupon_model_source.dart';
import '../models/company_model.dart';
import 'coupon_form_screen.dart';
import 'store_list_screen.dart';
import 'company_profile_screen.dart';
import 'user_list_screen.dart';
import 'change_password_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'Todos'; // Options: Todos, Activos, Inactivos

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final userProfileAsync = ref.watch(userProfileProvider(user?.uid ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('TUVALE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          if (userProfileAsync.valueOrNull?.role == 'admin') ...[
            IconButton(
              icon: const Icon(Icons.business),
              tooltip: 'Mi Empresa',
               onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyProfileScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Gestionar Usuarios',
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const UserListScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.store),
              tooltip: 'Mis Sucursales',
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreListScreen()));
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'change_password') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'change_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Cambiar Contraseña'),
                    ],
                  ),
                ),
              ];
            },
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
              // Filter Logic
              final filteredCoupons = coupons.where((coupon) {
                final matchesSearch = coupon.productName.toLowerCase().contains(_searchController.text.toLowerCase());
                final matchesStatus = _statusFilter == 'Todos' ||
                    (_statusFilter == 'Activos' && coupon.isActive) ||
                    (_statusFilter == 'Inactivos' && !coupon.isActive);
                return matchesSearch && matchesStatus;
              }).toList();

              return Column(
                children: [
                  // Filter Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).cardColor,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Buscar por nombre...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _statusFilter,
                          underline: const SizedBox(),
                          items: ['Todos', 'Activos', 'Inactivos'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() => _statusFilter = newValue);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  
                  // List
                  Expanded(
                    child: filteredCoupons.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  coupons.isEmpty ? 'No tienes cupones' : 'No hay resultados',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredCoupons.length,
                            itemBuilder: (context, index) {
                              final coupon = filteredCoupons[index];
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
                          ),
                  ),
                ],
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
