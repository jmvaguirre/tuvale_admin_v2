import 'company_model.dart'; // Contains CompanyEntity

/// Store entity representing a physical store branch
class StoreEntity {
  final String id;
  final String companyId;
  final String branchName;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final bool isActive;
  final String? qrUrl;

  const StoreEntity({
    required this.id,
    required this.companyId,
    required this.branchName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.isActive = true,
    this.qrUrl,
  });

  /// Get full store name (Company - Branch)
  String getFullName(String companyName) => '$companyName - $branchName';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'StoreEntity{id: $id, branchName: $branchName, address: $address}';
  }
}
