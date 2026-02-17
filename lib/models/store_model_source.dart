import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_model.dart'; // Contains StoreEntity

/// Store model for Firestore data mapping
class StoreModel {
  final String id;
  final String companyId;
  final String branchName;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final bool isActive;
  final String? qrUrl;
  final String? businessHours;

  const StoreModel({
    required this.id,
    required this.companyId,
    required this.branchName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.isActive = true,
    this.qrUrl,
    this.businessHours,
  });

  /// Convert from Firestore document
  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      companyId: data['companyId'] ?? '',
      branchName: data['branchName'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      phone: data['phone'],
      isActive: data['isActive'] ?? true,
      qrUrl: data['qrUrl'],
      businessHours: data['businessHours'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'branchName': branchName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (phone != null) 'phone': phone,
      'isActive': isActive,
      if (qrUrl != null) 'qrUrl': qrUrl,
      if (businessHours != null) 'businessHours': businessHours,
    };
  }

  /// Convert to domain entity
  StoreEntity toEntity() {
    return StoreEntity(
      id: id,
      companyId: companyId,
      branchName: branchName,
      address: address,
      latitude: latitude,
      longitude: longitude,
      phone: phone,
      isActive: isActive,
      qrUrl: qrUrl,
      businessHours: businessHours,
    );
  }

  /// Create from domain entity
  factory StoreModel.fromEntity(StoreEntity entity) {
    return StoreModel(
      id: entity.id,
      companyId: entity.companyId,
      branchName: entity.branchName,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
      phone: entity.phone,
      isActive: entity.isActive,
      qrUrl: entity.qrUrl,
      businessHours: entity.businessHours,
    );
  }
}
