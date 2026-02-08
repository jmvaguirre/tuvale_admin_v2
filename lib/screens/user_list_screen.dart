import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'user_form_screen.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final userProfileAsync = ref.watch(userProfileProvider(user!.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Usuarios')),
      body: userProfileAsync.when(
        data: (adminProfile) {
          if (adminProfile?.companyId == null) return const Center(child: Text('Error: Sin empresa asignada'));

          final usersAsync = ref.watch(companyUsersProvider(adminProfile!.companyId!));

          return usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const Center(child: Text('No hay usuarios registrados'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final appUser = users[index];
                  final isMe = appUser.id == user.uid;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: appUser.isActive 
                          ? (appUser.role == 'admin' ? Colors.purple.shade100 : Colors.blue.shade100)
                          : Colors.grey.shade300,
                        child: Icon(
                          appUser.role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                          color: appUser.isActive 
                            ? (appUser.role == 'admin' ? Colors.purple : Colors.blue) 
                            : Colors.grey,
                        ),
                      ),
                      title: Text(
                        appUser.email, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: appUser.isActive ? Colors.black : Colors.grey,
                          decoration: appUser.isActive ? null : TextDecoration.lineThrough,
                        )
                      ),
                      subtitle: Text('Rol: ${appUser.role.toUpperCase()} ${!appUser.isActive ? '(BLOQUEADO)' : ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMe) const Chip(label: Text('Yo')),
                          if (!isMe) 
                            Switch(
                              value: appUser.isActive,
                              onChanged: (val) async {
                                await ref.read(firestoreServiceProvider).toggleUserStatus(appUser.id, val);
                              },
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error al cargar usuarios: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error de perfil: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserFormScreen()),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
