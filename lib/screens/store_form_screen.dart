import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/store_model_source.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'location_picker_screen.dart';

class StoreFormScreen extends ConsumerStatefulWidget {
  final StoreModel? store;
  const StoreFormScreen({super.key, this.store});

  @override
  ConsumerState<StoreFormScreen> createState() => _StoreFormScreenState();
}

class _StoreFormScreenState extends ConsumerState<StoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _branchNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.store != null) {
      final s = widget.store!;
      _branchNameController.text = s.branchName;
      _addressController.text = s.address;
      _phoneController.text = s.phone ?? '';
      _latController.text = s.latitude.toString();
      _lngController.text = s.longitude.toString();
      _isActive = s.isActive;
    }
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLat: lat,
          initialLng: lng,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latController.text = result.latitude.toString();
        _lngController.text = result.longitude.toString();
      });
    }
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final userProfile = await ref.read(firestoreServiceProvider).getUserStream(user.uid).first;
      if (userProfile?.companyId == null) throw Exception('Usuario sin empresa');

      final newStore = StoreModel(
        id: widget.store?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        companyId: userProfile!.companyId!,
        branchName: _branchNameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: double.tryParse(_latController.text) ?? 0.0,
        longitude: double.tryParse(_lngController.text) ?? 0.0,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
        isActive: _isActive,
      );

      if (widget.store == null) {
        await ref.read(firestoreServiceProvider).addStore(
          newStore,
          storageService: ref.read(storageServiceProvider),
        );
      } else {
        await ref.read(firestoreServiceProvider).updateStore(newStore);
      }

      if (mounted) {
        Navigator.pop(context);
        UIHelpers.showSnackBar(context, 'Sucursal guardada exitosamente');
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
      appBar: AppBar(
        title: Text(widget.store == null ? 'Nueva Sucursal' : 'Editar Sucursal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Datos de la Sucursal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _branchNameController,
                        decoration: const InputDecoration(labelText: 'Nombre de Sucursal', hintText: 'Ej. Centro, Norte, Matriz'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Dirección Completa', prefixIcon: Icon(Icons.location_on_outlined)),
                        maxLines: 2,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Teléfono (Opcional)', prefixIcon: Icon(Icons.phone_outlined)),
                        keyboardType: TextInputType.phone,
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
                      Text('Ubicación (Coordenadas)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Toca el mapa para ubicar tu sucursal.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickLocation,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map, size: 48, color: Colors.blue),
                              const SizedBox(height: 8),
                              Text(
                                _latController.text.isNotEmpty && _lngController.text.isNotEmpty && _latController.text != '0.0'
                                    ? 'Ubicación seleccionada\n${_latController.text}, ${_lngController.text}'
                                    : 'Seleccionar en Mapa',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Hidden text fields for debug/validation if needed, or just keep controllers updated
                      // We can keep them visible but read-only if preferred, but UI requested map
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              decoration: const InputDecoration(labelText: 'Latitud'),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              decoration: const InputDecoration(labelText: 'Longitud'),
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: const Text('Sucursal Activa'),
                  subtitle: const Text('Visible para asignar cupones'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveStore,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR SUCURSAL'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
