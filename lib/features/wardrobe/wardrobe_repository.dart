import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WardrobeRepository {
  WardrobeRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _clothesCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('clothes');
  }

  CollectionReference<Map<String, dynamic>> _suggestionsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('suggestions');
  }

  CollectionReference<Map<String, dynamic>> _savedOutfitsCollection(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).collection('savedOutfits');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchClothes() {
    final uid = userId;
    if (uid == null) {
      return const Stream.empty();
    }

    return _clothesCollection(
      uid,
    ).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> createClothingItem({
    required String imageRef,
    required String type,
    required String color,
    required String season,
    List<String> tags = const [],
    Map<String, dynamic> visionAttributes = const {},
  }) async {
    final uid = userId;
    if (uid == null) return;

    await _clothesCollection(uid).add({
      'imageRef': imageRef,
      'type': type,
      'color': color,
      'season': season,
      'tags': tags,
      'visionAttributes': visionAttributes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'manual_upload',
    });
  }

  Future<void> updateClothingItem({
    required String clothingId,
    String? type,
    String? color,
    String? season,
    List<String>? tags,
    Map<String, dynamic>? visionAttributes,
  }) async {
    final uid = userId;
    if (uid == null) return;

    await _clothesCollection(uid).doc(clothingId).update({
      if (type != null) 'type': type,
      if (color != null) 'color': color,
      if (season != null) 'season': season,
      if (tags != null) 'tags': tags,
      if (visionAttributes != null) 'visionAttributes': visionAttributes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteClothingItem(String clothingId) async {
    final uid = userId;
    if (uid == null) return;

    await _clothesCollection(uid).doc(clothingId).delete();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getWardrobeItems() async {
    final uid = userId;
    if (uid == null) return [];

    final snapshot = await _clothesCollection(uid).get();
    return snapshot.docs;
  }

  Future<String?> createSuggestion({
    required String title,
    required List<String> clothingIds,
    String generatedBy = 'genkit:v1',
    double confidence = 0.7,
  }) async {
    final uid = userId;
    if (uid == null) return null;

    final ref = await _suggestionsCollection(uid).add({
      'title': title,
      'clothingIds': clothingIds,
      'generatedBy': generatedBy,
      'confidence': confidence,
      'status': 'suggested',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSuggestions() {
    final uid = userId;
    if (uid == null) {
      return const Stream.empty();
    }

    return _suggestionsCollection(
      uid,
    ).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> saveSuggestedOutfit({
    required String suggestionId,
    required String title,
    required List<String> clothingIds,
  }) async {
    final uid = userId;
    if (uid == null) return;

    await _savedOutfitsCollection(uid).add({
      'suggestionId': suggestionId,
      'title': title,
      'clothingIds': clothingIds,
      'savedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _suggestionsCollection(uid).doc(suggestionId).update({
      'status': 'saved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
