/// Store category enum
enum StoreCategory {
  supermercado('Supermercado', 'supermercado'),
  farmacia('Farmacia', 'farmacia'),
  restaurante('Restaurante', 'restaurante'),
  moda('Moda', 'moda');

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

  const CompanyEntity({
    required this.id,
    required this.name,
    required this.category,
    this.logoUrl,
    this.isFeatured = false,
    this.priority = 0,
  });

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
