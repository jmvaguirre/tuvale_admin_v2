import 'package:cloud_firestore/cloud_firestore.dart';
import 'coupon_model.dart'; // Contains CouponEntity

/// Coupon model for Firestore data mapping
class CouponModel {
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
  final List<String> enabledStoreIds;
  final bool isActive;
  final String? barcode;
  final bool isHero;
  final List<String> tags;
  final int viewCount;
  final String? qrUrl;

  const CouponModel({
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

  /// Convert from Firestore document
  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      companyId: data['companyId'] ?? '',
      productName: data['productName'] ?? '',
      description: data['description'],
      originalPrice: (data['originalPrice'] ?? 0.0).toDouble(),
      discountedPrice: (data['discountedPrice'] ?? 0.0).toDouble(),
      discountPercentage: data['discountPercentage'] ?? 0,
      imageUrl: data['imageUrl'],
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validUntil: (data['validUntil'] as Timestamp).toDate(),
      stock: data['stock'] ?? 0,
      enabledStoreIds: List<String>.from(data['enabledStoreIds'] ?? []),
      isActive: data['isActive'] ?? true,
      barcode: data['barcode'],
      isHero: data['isHero'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      viewCount: data['viewCount'] ?? 0,
      qrUrl: data['qrUrl'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'productName': productName,
      if (description != null) 'description': description,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountPercentage': discountPercentage,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'stock': stock,
      'enabledStoreIds': enabledStoreIds,
      'isActive': isActive,
      if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
      'isHero': isHero,
      'tags': tags,
      'viewCount': viewCount,
      if (qrUrl != null) 'qrUrl': qrUrl,
    };
  }

  /// Convert to domain entity
  CouponEntity toEntity() {
    return CouponEntity(
      id: id,
      companyId: companyId,
      productName: productName,
      description: description,
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
      discountPercentage: discountPercentage,
      imageUrl: imageUrl,
      validFrom: validFrom,
      validUntil: validUntil,
      stock: stock,
      enabledStoreIds: enabledStoreIds,
      isActive: isActive,
      barcode: barcode,
      isHero: isHero,
      tags: tags,
      viewCount: viewCount,
      qrUrl: qrUrl,
    );
  }

  /// Create from domain entity
  factory CouponModel.fromEntity(CouponEntity entity) {
    return CouponModel(
      id: entity.id,
      companyId: entity.companyId,
      productName: entity.productName,
      description: entity.description,
      originalPrice: entity.originalPrice,
      discountedPrice: entity.discountedPrice,
      discountPercentage: entity.discountPercentage,
      imageUrl: entity.imageUrl,
      validFrom: entity.validFrom,
      validUntil: entity.validUntil,
      stock: entity.stock,
      enabledStoreIds: entity.enabledStoreIds,
      isActive: entity.isActive,
      barcode: entity.barcode,
      isHero: entity.isHero,
      tags: entity.tags,
      viewCount: entity.viewCount,
      qrUrl: entity.qrUrl,
    );
  }
}
