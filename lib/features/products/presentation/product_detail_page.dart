import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/presentation/cart_controller.dart';
import '../domain/product.dart';
import 'product_controller.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});
  final int productId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Product details')),
    body: ProductDetailContent(productId: productId),
  );
}

class ProductDetailContent extends StatelessWidget {
  const ProductDetailContent({super.key, required this.productId});
  final int productId;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => sl<ProductController>()..load(productId),
    child: Consumer<ProductController>(
      builder: (context, controller, _) {
        return switch (controller.status) {
          ProductStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ProductStatus.failure => ErrorView(
            icon: controller.failure?.kind.name == 'notFound'
                ? Icons.inventory_2_outlined
                : Icons.wifi_off_rounded,
            title: controller.failure?.kind.name == 'notFound'
                ? 'Product not found'
                : 'Could not load product',
            message: controller.failure!.message,
            onRetry: () => controller.load(productId),
          ),
          ProductStatus.ready => _ProductDetailBody(
            product: controller.product!,
          ),
        };
      },
    ),
  );
}

class _ProductDetailBody extends StatefulWidget {
  const _ProductDetailBody({required this.product});
  final Product product;
  @override
  State<_ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends State<_ProductDetailBody> {
  int imageIndex = 0;
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images.isEmpty
        ? [product.thumbnail]
        : product.images;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        AspectRatio(
          aspectRatio: 1.18,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: const Color(0xFFF0F3ED),
              child: PageView.builder(
                itemCount: images.length,
                onPageChanged: (index) => setState(() => imageIndex = index),
                itemBuilder: (_, index) => CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == imageIndex ? 22 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == imageIndex
                          ? AppTheme.jade
                          : const Color(0xFFCDD8D0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (product.brand?.isNotEmpty == true)
          Text(
            product.brand!.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppTheme.jade,
              fontSize: 11,
            ),
          ),
        const SizedBox(height: 6),
        Text(product.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFE9A63B), size: 20),
            Text(
              ' ${product.rating.toStringAsFixed(1)}  ·  ${product.reviews.length} reviews',
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(
              '\$${product.salePrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.jade,
              ),
            ),
            if (product.discountPercentage > 0) ...[
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Color(0xFF82908A),
                ),
              ),
              Text(
                '${product.discountPercentage.round()}% off',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.coral,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          product.stock > 0 ? '${product.stock} in stock' : 'Out of stock',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: product.stock > 0
                ? AppTheme.jade
                : Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 22),
        Text('About this item', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(product.description),
        const SizedBox(height: 28),
        Row(
          children: [
            _quantityButton(
              Icons.remove,
              'Decrease quantity',
              quantity > 1 ? () => setState(() => quantity--) : null,
            ),
            SizedBox(
              width: 42,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _quantityButton(
              Icons.add,
              'Increase quantity',
              quantity < product.stock
                  ? () => setState(() => quantity++)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: FilledButton.icon(
                onPressed: product.stock <= 0
                    ? null
                    : () async {
                        await context.read<CartController>().add(
                          product,
                          quantity,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$quantity × ${product.title} added to cart',
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('Add to cart'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text('Customer reviews', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (product.reviews.isEmpty) const Text('No reviews yet.'),
        for (final review in product.reviews)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.reviewerName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '★ ${review.rating}',
                        style: const TextStyle(color: Color(0xFFAB741D)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.comment),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _quantityButton(
    IconData icon,
    String label,
    VoidCallback? onPressed,
  ) => IconButton.outlined(
    tooltip: label,
    onPressed: onPressed,
    icon: Icon(icon),
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
  );
}
