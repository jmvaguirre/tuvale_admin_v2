import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/company_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isInitialized = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _businessHoursController;
  
  // Social Media Controllers
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _twitterController;
  late TextEditingController _whatsappController;

  StoreCategory _selectedCategory = StoreCategory.supermercado;
  String? _logoUrl;
  int _currentPriority = 0; // Store the current priority to preserve it

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _websiteController = TextEditingController();
    _businessHoursController = TextEditingController();
    
    _facebookController = TextEditingController();
    _instagramController = TextEditingController();
    _twitterController = TextEditingController();
    _whatsappController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _businessHoursController.dispose();
    
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _initializeControllers(CompanyEntity company) {
    if (_isInitialized) return;
    
    _nameController.text = company.name;
    _descriptionController.text = company.description ?? '';
    _emailController.text = company.email ?? '';
    _phoneController.text = company.phone ?? '';
    _websiteController.text = company.website ?? '';
    _businessHoursController.text = company.businessHours ?? '';
    _currentPriority = company.priority;
    
    // Social Media
    _facebookController.text = company.socialMedia?.facebook ?? '';
    _instagramController.text = company.socialMedia?.instagram ?? '';
    _twitterController.text = company.socialMedia?.twitter ?? '';
    _whatsappController.text = company.socialMedia?.whatsapp ?? '';

    _selectedCategory = company.category;
    _logoUrl = company.logoUrl;
    
    _isInitialized = true;
  }

  Future<void> _updateLogo(String companyId) async {
    try {
      final file = await ref.read(storageServiceProvider).pickImage(source: ImageSource.gallery);
      if (file == null) return;

      setState(() => _isLoading = true);

      final downloadUrl = await ref.read(storageServiceProvider).uploadImage(
        file: File(file.path),
        path: 'companies/$companyId.jpg',
      );

      // We update the local state to show the new image immediately, 
      // but the final save is done via the "Save" button for other fields.
      // However, for the logo, we usually want it to persist immediately or we need to handle it in save.
      // To keep it simple and consistent with previous logic, we update Firestore immediately for logo.
      await ref.read(firestoreServiceProvider).updateCompanyLogo(companyId, downloadUrl);
      
      setState(() {
        _logoUrl = downloadUrl;
      });

      if (mounted) {
        UIHelpers.showSnackBar(context, 'Logo actualizado exitosamente');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Error actualizando logo: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCompany(String companyId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedCompany = CompanyEntity(
        id: companyId,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        // Logo URL is managed separately or preserved
        logoUrl: _logoUrl, 
        priority: _currentPriority, // Preserve existing priority
        description: _descriptionController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        businessHours: _businessHoursController.text.trim(),
        socialMedia: SocialMedia(
          facebook: _facebookController.text.trim(),
          instagram: _instagramController.text.trim(),
          twitter: _twitterController.text.trim(),
          whatsapp: _whatsappController.text.trim(),
        ),
      );

      await ref.read(firestoreServiceProvider).updateCompany(updatedCompany);

      if (mounted) {
        UIHelpers.showSnackBar(context, 'Empresa actualizada exitosamente');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Error actualizando empresa: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    // We assume user is not null here usually, but good to check
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final userProfileAsync = ref.watch(userProfileProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Empresa')),
      body: userProfileAsync.when(
        data: (userProfile) {
           if (userProfile?.companyId == null) return const Center(child: Text('Sin empresa asignada'));
           
           final companyAsync = ref.watch(companyProfileProvider(userProfile!.companyId!));
           
           return companyAsync.when(
             data: (company) {
               if (company == null) return const Center(child: Text('Empresa no encontrada'));

               // Initialize form fields once
               _initializeControllers(company);

               return SingleChildScrollView(
                 padding: const EdgeInsets.all(16),
                 child: Form(
                   key: _formKey,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Center(
                         child: Stack(
                           children: [
                             Container(
                               width: 150,
                               height: 150,
                               decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 color: Colors.grey[200],
                                 border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                                 image: _logoUrl != null
                                   ? DecorationImage(
                                       image: NetworkImage(_logoUrl!),
                                       fit: BoxFit.cover,
                                     )
                                   : null,
                               ),
                               child: _logoUrl == null
                                 ? Icon(Icons.business, size: 64, color: Colors.grey[400])
                                 : null,
                             ),
                             if (_isLoading)
                               const Positioned.fill(
                                 child: CircularProgressIndicator(),
                               ),
                             Positioned(
                               bottom: 0,
                               right: 0,
                               child: CircleAvatar(
                                 backgroundColor: Theme.of(context).primaryColor,
                                 child: IconButton(
                                   icon: const Icon(Icons.camera_alt, color: Colors.white),
                                   onPressed: _isLoading ? null : () => _updateLogo(company.id),
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 24),
                       
                       // Basic Info
                       Card(
                         child: Padding(
                           padding: const EdgeInsets.all(16),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text('Información Básica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                               const SizedBox(height: 16),
                               TextFormField(
                                 controller: _nameController,
                                 decoration: const InputDecoration(labelText: 'Nombre de la Empresa'),
                                 validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                               ),
                               const SizedBox(height: 16),
                                DropdownButtonFormField<StoreCategory>(
                                  value: _selectedCategory,
                                  decoration: const InputDecoration(labelText: 'Categoría'),
                                  isExpanded: true,
                                  items: StoreCategory.values.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                 onChanged: (v) {
                                   if (v != null) setState(() => _selectedCategory = v);
                                 },
                               ),
                               const SizedBox(height: 16),
                               TextFormField(
                                 controller: _descriptionController,
                                 decoration: const InputDecoration(labelText: 'Descripción'),
                                 maxLines: 3,
                               ),
                               const SizedBox(height: 16),
                               TextFormField(
                                 controller: _businessHoursController,
                                 decoration: const InputDecoration(labelText: 'Horario de Atención'),
                               ),
                             ],
                           ),
                         ),
                       ),
                       const SizedBox(height: 16),

                       // Contact Info
                       Card(
                         child: Padding(
                           padding: const EdgeInsets.all(16),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text('Contacto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                               const SizedBox(height: 16),
                               TextFormField(
                                 controller: _emailController,
                                 decoration: const InputDecoration(labelText: 'Email Público'),
                                 keyboardType: TextInputType.emailAddress,
                               ),
                               const SizedBox(height: 16),
                               TextFormField(
                                 controller: _phoneController,
                                 decoration: const InputDecoration(labelText: 'Teléfono'),
                                 keyboardType: TextInputType.phone,
                               ),
                               const SizedBox(height: 16),
                               TextFormField(
                                 controller: _websiteController,
                                 decoration: const InputDecoration(labelText: 'Sitio Web'),
                                 keyboardType: TextInputType.url,
                               ),
                             ],
                           ),
                         ),
                       ),
                       const SizedBox(height: 16),

                       // Social Media
                       Card(
                         child: Padding(
                           padding: const EdgeInsets.all(16),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text('Redes Sociales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                               const SizedBox(height: 16),
                               TextFormField(
                                 controller: _facebookController,
                                 decoration: const InputDecoration(labelText: 'Facebook (URL)'),
                               ),
                               const SizedBox(height: 16),
                               TextFormField(
                                 controller: _instagramController,
                                 decoration: const InputDecoration(labelText: 'Instagram (URL)'),
                               ),
                               const SizedBox(height: 16),
                               TextFormField(
                                 controller: _twitterController,
                                 decoration: const InputDecoration(labelText: 'Twitter (URL)'),
                               ),
                               const SizedBox(height: 16),
                               TextFormField(
                                 controller: _whatsappController,
                                 decoration: const InputDecoration(labelText: 'WhatsApp (Número)'),
                               ),
                             ],
                           ),
                         ),
                       ),
                       
                       const SizedBox(height: 32),
                       SizedBox(
                         width: double.infinity,
                         height: 50,
                         child: ElevatedButton(
                           onPressed: _isLoading ? null : () => _saveCompany(company.id),
                           child: _isLoading 
                             ? const CircularProgressIndicator(color: Colors.white)
                             : const Text('Guardar Cambios'),
                         ),
                       ),
                       const SizedBox(height: 32),
                     ],
                   ),
                 ),
               );
             },
             loading: () => const Center(child: CircularProgressIndicator()),
             error: (e,s) => Center(child: Text('Error: $e')),
           );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
