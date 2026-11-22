import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

import '../models/product.dart';

// ID database Firestore (database mặc định)
const String kDatabaseId = '(default)';

class ProductService {
  final Logger _logger = Logger();
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  CollectionReference get _products => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: kDatabaseId,
      ).collection('products');

  // Lấy danh sách sản phẩm (tự cập nhật realtime)
  Stream<List<Product>> getProducts() {
    return _products.orderBy('timestamp', descending: true).snapshots().map(
        (QuerySnapshot query) => query.docs
            .map((doc) =>
                Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Thêm sản phẩm
  Future<void> addProduct({
    required String name,
    required double price,
    required File image,
  }) async {
    try {
      _firebaseStorage.setMaxUploadRetryTime(const Duration(seconds: 15));
      String ext = path.extension(image.path);
      final storageRef = _firebaseStorage
          .ref('products')
          .child('product-${DateTime.now().millisecondsSinceEpoch}$ext');
      _logger.i('Ref path: ${storageRef.fullPath}');

      await storageRef.putFile(image).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception(
                'Upload ảnh quá lâu: Storage Emulator chưa bật?'),
          );
      final downloadURL = await storageRef.getDownloadURL();
      _logger.i('File uploaded, download URL: $downloadURL');

      await _products.add({
        'name': name,
        'price': price,
        'imageUrl': downloadURL,
        'imagePath': storageRef.fullPath,
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception(
            'Lưu Firestore quá lâu: chưa tạo Firestore Database?'),
      );
      _logger.i('Insert product successfully');
    } catch (e) {
      _logger.e('Error during insert product: $e');
      rethrow;
    }
  }

  // Xóa sản phẩm và ảnh trên Storage
  Future<void> deleteProduct(Product product) async {
    try {
      await _products.doc(product.id).delete();
      if (product.imagePath.isNotEmpty) {
        await _firebaseStorage.ref(product.imagePath).delete();
      }
      _logger.i('Delete product ${product.id} successfully');
    } catch (e) {
      _logger.e('Error during delete product: $e');
      rethrow;
    }
  }
}
