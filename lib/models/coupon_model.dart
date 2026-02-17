/// Coupon entity representing a discount offer
class CouponEntity {
  final String id;
  final String companyId;
  final String productName;
  final String? description;
  final double originalPrice;
  final double discountedPrice;
  final int discountPercentage;
  final String? imageUrl;
  final DateTime validFrom;
  final DateTime validUntil;
  final int stock;
  final List<String> enabledStoreIds; // IDs of stores where this coupon is valid
  final bool isActive;
  final String? barcode; // Barcode for scanning at checkout (optional)
  final bool isHero;
  final List<String> tags;
  final int viewCount;
  final String? qrUrl;

  const CouponEntity({
    required this.id,
    required this.companyId,
    required this.productName,
    this.description,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercentage,
    this.imageUrl,
    required this.validFrom,
    required this.validUntil,
    required this.stock,
    required this.enabledStoreIds,
    this.isActive = true,
    this.barcode,
    this.isHero = false,
    this.tags = const [],
    this.viewCount = 0,
    this.qrUrl,
  });

  /// Check if coupon is currently valid
  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        stock > 0 &&
        now.isAfter(validFrom) &&
        now.isBefore(validUntil);
  }

  /// Calculate savings amount
  double get savings => originalPrice - discountedPrice;

  /// Check if coupon is valid for a specific store
  bool isValidForStore(String storeId) {
    return enabledStoreIds.contains(storeId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CouponEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CouponEntity{id: $id, productName: $productName, discount: $discountPercentage%, isHero: $isHero}';
  }
}
