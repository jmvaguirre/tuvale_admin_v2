import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coupon_model_source.dart';
import '../models/store_model_source.dart';
import '../models/company_model.dart';
import '../models/company_model_source.dart';
import '../models/user_model.dart';
import '../utils/qr_generator.dart';
import 'storage_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

final userProfileProvider = StreamProvider.family<AppUser?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).getUserStream(uid);
});

final companyCouponsProvider = StreamProvider.family<List<CouponModel>, String>((ref, companyId) {
  return ref.watch(firestoreServiceProvider).getCouponsStream(companyId);
});

final companyStoresProvider = StreamProvider.family<List<StoreModel>, String>((ref, companyId) {
  return ref.watch(firestoreServiceProvider).getStoresStream(companyId);
});

final companyProfileProvider = StreamProvider.family<CompanyEntity?, String>((ref, companyId) {
  return ref.watch(firestoreServiceProvider).getCompanyStream(companyId);
});

final companyUsersProvider = StreamProvider.family<List<AppUser>, String>((ref, companyId) {
  return ref.watch(firestoreServiceProvider).getCompanyUsersStream(companyId);
});

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  // User Methods
  Stream<AppUser?> getUserStream(String uid) {
    return _firestore.collection('admin_users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }

  Stream<List<AppUser>> getCompanyUsersStream(String companyId) {
    return _firestore
        .collection('admin_users')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<void> createOrUpdateUser(AppUser user) async {
    await _firestore.collection('admin_users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> toggleUserStatus(String uid, bool isActive) async {
    await _firestore.collection('admin_users').doc(uid).update({'isActive': isActive});
  }

  // Coupon Methods
  Stream<List<CouponModel>> getCouponsStream(String companyId) {
    return _firestore
        .collection('coupons')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CouponModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addCoupon(CouponModel coupon, {required StorageService storageService}) async {
    // 1. Generate QR Code
    String? qrUrl;
    try {
      final qrBytes = await QrGenerator.generateQrBytes(coupon.id);
      if (qrBytes != null) {
        // 2. Upload to Storage
        qrUrl = await storageService.uploadQrCode(
          data: qrBytes,
          path: 'coupons/qr_codes/${coupon.id}.png',
        );
      }
    } catch (e) {
      print('Error generating/uploading QR: $e');
    }

    // 3. Save to Firestore with QR URL
    final couponWithQr = CouponModel(
      id: coupon.id,
      companyId: coupon.companyId,
      productName: coupon.productName,
      description: coupon.description,
      originalPrice: coupon.originalPrice,
      discountedPrice: coupon.discountedPrice,
      discountPercentage: coupon.discountPercentage,
      imageUrl: coupon.imageUrl,
      validFrom: coupon.validFrom,
      validUntil: coupon.validUntil,
      stock: coupon.stock,
      enabledStoreIds: coupon.enabledStoreIds,
      isActive: coupon.isActive,
      barcode: coupon.barcode,
      isHero: coupon.isHero, // Ensure this property exists in your model if used
      tags: coupon.tags,
      viewCount: coupon.viewCount,
      qrUrl: qrUrl,
    );

    await _firestore.collection('coupons').doc(coupon.id).set(couponWithQr.toFirestore());
  }

  Future<void> updateCoupon(CouponModel coupon) async {
    await _firestore.collection('coupons').doc(coupon.id).update(coupon.toFirestore());
  }

  Future<void> deleteCoupon(String couponId) async {
    await _firestore.collection('coupons').doc(couponId).delete();
  }

  Future<void> initializeUserAndCompany(String uid, String email) async {
    final companyRef = _firestore.collection('companies').doc();
    final newCompanyId = companyRef.id;

    // 1. Create Default Company
    await companyRef.set({
      'name': 'Mi Empresa',
      'category': 'supermercado',
      'isFeatured': false,
      'priority': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Create Admin User Profile linked to Company
    await _firestore.collection('admin_users').doc(uid).set({
      'email': email,
      'role': 'admin',
      'companyId': newCompanyId,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  // Company Methods
  Stream<CompanyEntity?> getCompanyStream(String companyId) {
    return _firestore.collection('companies').doc(companyId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        // Use CompanyModel to properly map all fields
        final model = CompanyModel.fromFirestore(doc);
        return model.toEntity();
      }
      return null;
    });
  }

  Future<void> updateCompanyLogo(String companyId, String logoUrl) async {
    await _firestore.collection('companies').doc(companyId).update({'logoUrl': logoUrl});
  }

  Future<void> updateCompany(CompanyEntity company) async {
    final model = CompanyModel.fromEntity(company);
    await _firestore.collection('companies').doc(company.id).update(model.toFirestore());
  }

  // Store Methods
  Stream<List<StoreModel>> getStoresStream(String companyId) {
    return _firestore
        .collection('stores')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StoreModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addStore(StoreModel store, {required StorageService storageService}) async {
    // 1. Generate QR Code with branch name
    String? qrUrl;
    try {
      final qrBytes = await QrGenerator.generateQrBytesWithText(store.id, store.branchName);
      if (qrBytes != null) {
        // 2. Upload to Storage
        qrUrl = await storageService.uploadQrCode(
          data: qrBytes,
          path: 'stores/qr_codes/${store.id}.png',
        );
      }
    } catch (e) {
      print('Error generating/uploading store QR: $e');
    }

    // 3. Create store with QR URL
    final storeWithQr = StoreModel(
      id: store.id,
      companyId: store.companyId,
      branchName: store.branchName,
      address: store.address,
      latitude: store.latitude,
      longitude: store.longitude,
      phone: store.phone,
      isActive: store.isActive,
      qrUrl: qrUrl,
    );

    await _firestore.collection('stores').doc(store.id).set(storeWithQr.toFirestore());
  }

  Future<void> updateStore(StoreModel store) async {
    await _firestore.collection('stores').doc(store.id).update(store.toFirestore());
  }

  Future<void> deleteStore(String storeId) async {
    await _firestore.collection('stores').doc(storeId).delete();
  }
}
