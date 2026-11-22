import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/format.dart';
import 'product_form_screen.dart';

const Color kPurple = Color(0xFF6C4EF2);

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _service = ProductService();
  late final Stream<List<Product>> _stream = _service.getProducts();

  Future<bool> _confirmDelete(Product p) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc muốn xóa "${p.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _delete(Product p) async {
    try {
      await _service.deleteProduct(p);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đã xóa ${p.name}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        leadingWidth: 90,
        leading: TextButton.icon(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
          label: const Text('Back', style: TextStyle(color: Colors.white)),
        ),
        title: const Text('Products',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Text('Cart', style: TextStyle(color: Colors.white)),
            label: const Icon(Icons.shopping_cart_outlined,
                color: Colors.white, size: 20),
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Lỗi: ${snapshot.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!;
          if (products.isEmpty) {
            return const Center(
              child: Text('Chưa có sản phẩm nào.\nNhấn + để thêm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: products.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 88, endIndent: 16),
            itemBuilder: (context, i) => _buildItem(products[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPurple,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItem(Product p) {
    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(p),
      onDismissed: (_) => _delete(p),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE8FF),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: p.imageUrl.isEmpty
              ? const Icon(Icons.image, color: kPurple)
              : Image.network(
                  p.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: kPurple),
                ),
        ),
        title: Text(p.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(formatPrice(p.price),
            style: const TextStyle(color: kPurple)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            if (await _confirmDelete(p)) _delete(p);
          },
        ),
      ),
    );
  }
}
