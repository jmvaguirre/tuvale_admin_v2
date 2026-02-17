/// Store category enum
enum StoreCategory {
  supermercado('Supermercado', 'supermercado'),
  farmacia('Farmacia', 'farmacia'),
  restaurante('Restaurante', 'restaurante'),
  moda('Moda', 'moda'),
  ferreteria('Ferretería', 'ferreteria');

  final String label;
  final String value;

  const StoreCategory(this.label, this.value);

  static StoreCategory fromString(String value) {
    return StoreCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => StoreCategory.supermercado,
    );
  }
}

/// Company entity representing a business with multiple store branches
class CompanyEntity {
  final String id;
  final String name;
  final StoreCategory category;
  final String? logoUrl;
  final bool isFeatured;
  final int priority;
  
  // New fields
  final String? description;
  final String? email;
  final String? phone;
  final String? website;
  final String? businessHours;
  final SocialMedia? socialMedia;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyEntity({
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

  CompanyEntity copyWith({
    String? id,
    String? name,
    StoreCategory? category,
    String? logoUrl,
    bool? isFeatured,
    int? priority,
    String? description,
    String? email,
    String? phone,
    String? website,
    String? businessHours,
    SocialMedia? socialMedia,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      businessHours: businessHours ?? this.businessHours,
      socialMedia: socialMedia ?? this.socialMedia,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CompanyEntity{id: $id, name: $name, category: ${category.label}, isFeatured: $isFeatured}';
  }
}

class SocialMedia {
  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? whatsapp;

  const SocialMedia({
    this.facebook,
    this.instagram,
    this.twitter,
    this.whatsapp,
  });
  
  SocialMedia copyWith({
    String? facebook,
    String? instagram,
    String? twitter,
    String? whatsapp,
  }) {
    return SocialMedia(
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      twitter: twitter ?? this.twitter,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }
}
