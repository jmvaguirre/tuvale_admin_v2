import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  const UserFormScreen({super.key});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // Only for creation
  String _selectedRole = 'user'; // Default role
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(authServiceProvider).currentUser;
      final adminProfile = await ref.read(firestoreServiceProvider).getUserStream(currentUser!.uid).first;
      
      if (adminProfile?.companyId == null) {
        throw Exception('No tienes una empresa asignada para crear usuarios');
      }

      // 1. Create Auth User (via Secondary App)
      final newUserId = await ref.read(authServiceProvider).createUser(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      // 2. Create Firestore Profile
      final newUser = AppUser(
        id: newUserId,
        email: _emailController.text.trim(),
        companyId: adminProfile!.companyId,
        role: _selectedRole,
      );
      
      await ref.read(firestoreServiceProvider).createOrUpdateUser(newUser);

      if (mounted) {
        Navigator.pop(context);
        UIHelpers.showSnackBar(context, 'Usuario creado exitosamente');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Credenciales', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty || !v.contains('@') ? 'Correo inválido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña Inicial',
                          prefixIcon: Icon(Icons.lock_outline),
                          helperText: 'Mínimo 6 caracteres',
                        ),
                        obscureText: false, // Visible for admin creating it
                        validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Permisos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        isExpanded: true, // Fix permissions UI overflow
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          prefixIcon: Icon(Icons.manage_accounts_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('Usuario (Solo Cupones)', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'admin', child: Text('Administrador (Todo)', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createUser,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CREAR USUARIO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
