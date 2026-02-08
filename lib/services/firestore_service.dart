import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coupon_model_source.dart';
import '../models/store_model_source.dart';
import '../models/company_model.dart';
import '../models/company_model_source.dart';
import '../models/user_model.dart';

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
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }

  Stream<List<AppUser>> getCompanyUsersStream(String companyId) {
    return _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<void> createOrUpdateUser(AppUser user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> toggleUserStatus(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).update({'isActive': isActive});
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

  Future<void> addCoupon(CouponModel coupon) async {
    // We remove ID from map becase it is auto-generated or set in docRef
    // But coupon.toFirestore() might include data we want.
    // Ideally we generate ID first.
    await _firestore.collection('coupons').doc(coupon.id).set(coupon.toFirestore());
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

    // 2. Create User Profile linked to Company
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'role': 'admin',
      'companyId': newCompanyId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  // Company Methods
  Stream<CompanyEntity?> getCompanyStream(String companyId) {
    return _firestore.collection('companies').doc(companyId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return CompanyEntity(
          id: doc.id,
          name: data['name'] ?? '',
          category: StoreCategory.fromString(data['category'] ?? ''),
          logoUrl: data['logoUrl'],
          isFeatured: data['isFeatured'] ?? false,
          priority: data['priority'] ?? 0,
        );
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

  Future<void> addStore(StoreModel store) async {
    await _firestore.collection('stores').doc(store.id).set(store.toFirestore());
  }

  Future<void> updateStore(StoreModel store) async {
    await _firestore.collection('stores').doc(store.id).update(store.toFirestore());
  }

  Future<void> deleteStore(String storeId) async {
    await _firestore.collection('stores').doc(storeId).delete();
  }
}
