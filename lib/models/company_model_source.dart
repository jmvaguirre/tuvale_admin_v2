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

  // New fields
  final String? description;
  final String? email;
  final String? phone;
  final String? website;
  final String? businessHours;
  final Map<String, dynamic>? socialMedia;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyModel({
    required this.id,
    required this.name,
    required this.category,
    this.logoUrl,
    this.isFeatured = false,
    this.priority = 0,
    this.description,
    this.email,
    this.phone,
    this.website,
    this.businessHours,
    this.socialMedia,
    this.createdAt,
    this.updatedAt,
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
      description: data['description'],
      email: data['email'],
      phone: data['phone'],
      website: data['website'],
      businessHours: data['businessHours'],
      socialMedia: data['socialMedia'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
      if (description != null) 'description': description,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (website != null) 'website': website,
      if (businessHours != null) 'businessHours': businessHours,
      if (socialMedia != null) 'socialMedia': socialMedia,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(), // Always update this on write
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
      description: description,
      email: email,
      phone: phone,
      website: website,
      businessHours: businessHours,
      socialMedia: socialMedia != null
          ? SocialMedia(
              facebook: socialMedia!['facebook'],
              instagram: socialMedia!['instagram'],
              twitter: socialMedia!['twitter'],
              whatsapp: socialMedia!['whatsapp'],
            )
          : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
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
      description: entity.description,
      email: entity.email,
      phone: entity.phone,
      website: entity.website,
      businessHours: entity.businessHours,
      socialMedia: entity.socialMedia != null
          ? {
              'facebook': entity.socialMedia!.facebook,
              'instagram': entity.socialMedia!.instagram,
              'twitter': entity.socialMedia!.twitter,
              'whatsapp': entity.socialMedia!.whatsapp,
            }
          : null,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
