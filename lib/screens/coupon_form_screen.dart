import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/coupon_model_source.dart';
import '../models/store_model_source.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class CouponFormScreen extends ConsumerStatefulWidget {
  final CouponModel? coupon; // If null, we are creating
  const CouponFormScreen({super.key, this.coupon});

  @override
  ConsumerState<CouponFormScreen> createState() => _CouponFormScreenState();
}

class _CouponFormScreenState extends ConsumerState<CouponFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();
  
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _isLoading = false;
  List<String> _enabledStoreIds = [];
  
  File? _selectedImageFile;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.coupon != null) {
      // Edit mode
      final c = widget.coupon!;
      _productNameController.text = c.productName;
      _descriptionController.text = c.description ?? '';
      _originalPriceController.text = c.originalPrice.toString();
      _discountedPriceController.text = c.discountedPrice.toString();
      _stockController.text = c.stock.toString();
      _barcodeController.text = c.barcode;
      _validFrom = c.validFrom;
      _validUntil = c.validUntil;
      _isActive = c.isActive;
      _enabledStoreIds = List.from(c.enabledStoreIds);
      _currentImageUrl = c.imageUrl;
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () async {
                Navigator.pop(context);
                final file = await ref.read(storageServiceProvider).pickImage(source: ImageSource.gallery);
                if (file != null) {
                  setState(() => _selectedImageFile = File(file.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () async {
                Navigator.pop(context);
                final file = await ref.read(storageServiceProvider).pickImage(source: ImageSource.camera);
                if (file != null) {
                  setState(() => _selectedImageFile = File(file.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _validFrom : _validUntil,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _validFrom = picked;
        } else {
          _validUntil = picked;
        }
      });
    }
  }

  Future<void> _saveCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final userProfile = await ref.read(firestoreServiceProvider).getUserStream(user.uid).first;
      if (userProfile?.companyId == null) throw Exception('Usuario sin empresa');

      final originalPrice = double.parse(_originalPriceController.text);
      final discountedPrice = double.parse(_discountedPriceController.text);
      final discountPercentage = ((originalPrice - discountedPrice) / originalPrice * 100).round();

      // Upload Image if selected
      String? imageUrl = _currentImageUrl;
      final couponId = widget.coupon?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      if (_selectedImageFile != null) {
        imageUrl = await ref.read(storageServiceProvider).uploadImage(
          file: _selectedImageFile!,
          path: 'coupons/$couponId.jpg',
        );
      }

      final newCoupon = CouponModel(
        id: couponId,
        companyId: userProfile!.companyId!,
        productName: _productNameController.text.trim(),
        description: _descriptionController.text.trim(),
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        discountPercentage: discountPercentage,
        validFrom: _validFrom,
        validUntil: _validUntil,
        stock: int.parse(_stockController.text),
        enabledStoreIds: _enabledStoreIds, 
        barcode: _barcodeController.text.trim(),
        isActive: _isActive,
        viewCount: widget.coupon?.viewCount ?? 0,
        imageUrl: imageUrl,
      );

      if (widget.coupon == null) {
        await ref.read(firestoreServiceProvider).addCoupon(newCoupon);
      } else {
        await ref.read(firestoreServiceProvider).updateCoupon(newCoupon);
      }

      if (mounted) {
        Navigator.pop(context);
        UIHelpers.showSnackBar(context, 'Cupón guardado exitosamente');
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
        title: Text(widget.coupon == null ? 'Nuevo Cupón' : 'Editar Cupón'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      image: _selectedImageFile != null
                          ? DecorationImage(image: FileImage(_selectedImageFile!), fit: BoxFit.cover)
                          : (_currentImageUrl != null
                              ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover)
                              : null),
                    ),
                    child: _selectedImageFile == null && _currentImageUrl == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Agregar Foto', style: TextStyle(color: Colors.grey[600])),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Información Básica', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _productNameController,
                        decoration: const InputDecoration(labelText: 'Nombre del Producto', hintText: 'Ej. Coca Cola 2L'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Descripción', hintText: 'Detalles del producto...'),
                        maxLines: 3,
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
                      Text('Precios y Stock', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _originalPriceController,
                              decoration: const InputDecoration(labelText: 'Precio Original', prefixText: '\$', helperText: 'Antes'),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _discountedPriceController,
                              decoration: const InputDecoration(labelText: 'Precio Oferta', prefixText: '\$', helperText: 'Ahora'),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: const InputDecoration(labelText: 'Stock Disponible', prefixIcon: Icon(Icons.inventory_2_outlined)),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: const InputDecoration(labelText: 'Código de Barras', prefixIcon: Icon(Icons.qr_code)),
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Disponibilidad en Tienda', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // Store Selection Logic
                      Consumer(
                        builder: (context, ref, _) {
                          final user = ref.read(authServiceProvider).currentUser;
                          // Assume user has company, otherwise form wouldn't load or save check handles it
                          return StreamBuilder<AppUser?>(
                            stream: ref.watch(firestoreServiceProvider).getUserStream(user!.uid),
                            builder: (context, userSnap) {
                                if (!userSnap.hasData || userSnap.data?.companyId == null) return const SizedBox();
                                final companyId = userSnap.data!.companyId!;
                                
                                final storesAsync = ref.watch(companyStoresProvider(companyId));
                                return storesAsync.when(
                                  data: (stores) {
                                    if (stores.isEmpty) return const Text('No tienes sucursales registradas. Crea una primero.', style: TextStyle(color: Colors.red));
                                    
                                    return Column(
                                      children: stores.map((store) {
                                        final isSelected = _enabledStoreIds.contains(store.id);
                                        return CheckboxListTile(
                                          title: Text(store.branchName),
                                          subtitle: Text(store.address, maxLines: 1),
                                          value: isSelected,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _enabledStoreIds.add(store.id);
                                              } else {
                                                _enabledStoreIds.remove(store.id);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    );
                                  },
                                  loading: () => const LinearProgressIndicator(),
                                  error: (_,__) => const Text('Error cargando sucursales'),
                                );
                            }
                          );
                        }
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
                      Text('Vigencia y Estado', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Válido Desde'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(_validFrom)),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: () => _selectDate(context, true),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Válido Hasta'),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(_validUntil)),
                        trailing: const Icon(Icons.event_busy_outlined),
                        onTap: () => _selectDate(context, false),
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cupón Activo'),
                        subtitle: const Text('Visible para los usuarios'),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCoupon,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR CUPÓN'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
