import 'package:cloud_firestore/cloud_firestore.dart';
import 'company_model.dart'; // Contains CompanyEntity

/// Company model for Firestore data mapping
class CompanyModel {
  final String id;
  final String name;
  final String category;
  final String? logoUrl;
  final bool isFeatured;
  final int priority;

  const CompanyModel({
    required this.id,
    required this.name,
    required this.category,
    this.logoUrl,
    this.isFeatured = false,
    this.priority = 0,
  });

  /// Convert from Firestore document
  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompanyModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'supermercado',
      logoUrl: data['logoUrl'],
      isFeatured: data['isFeatured'] ?? false,
      priority: data['priority'] ?? 0,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      if (logoUrl != null) 'logoUrl': logoUrl,
      'isFeatured': isFeatured,
      'priority': priority,
    };
  }

  /// Convert to domain entity
  CompanyEntity toEntity() {
    return CompanyEntity(
      id: id,
      name: name,
      category: StoreCategory.fromString(category),
      logoUrl: logoUrl,
      isFeatured: isFeatured,
      priority: priority,
    );
  }

  /// Create from domain entity
  factory CompanyModel.fromEntity(CompanyEntity entity) {
    return CompanyModel(
      id: entity.id,
      name: entity.name,
      category: entity.category.value,
      logoUrl: entity.logoUrl,
      isFeatured: entity.isFeatured,
      priority: entity.priority,
    );
  }
}
