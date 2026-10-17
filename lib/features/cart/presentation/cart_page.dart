import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/cart.dart';
import 'cart_controller.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final compactHeight = MediaQuery.sizeOf(context).height < 520;
    if (compactHeight) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Text(
              'Your bag',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          if (!cart.loaded)
            const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (cart.loaded && cart.items.isEmpty)
            const SizedBox(
              height: 250,
              child: EmptyView(
                icon: Icons.shopping_bag_outlined,
                title: 'Your bag is empty',
                message: 'Find something you love in Explore.',
              ),
            ),
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CartRow(item: item),
            ),
          if (cart.items.isNotEmpty) _Summary(cart: cart),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Text(
            'Your bag',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: !cart.loaded
              ? const Center(child: CircularProgressIndicator())
              : cart.items.isEmpty
              ? const EmptyView(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your bag is empty',
                  message: 'Find something you love in Explore.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) =>
                      _CartRow(item: cart.items[index]),
                ),
        ),
        if (cart.items.isNotEmpty) _Summary(cart: cart),
      ],
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});
  final CartItem item;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CachedNetworkImage(
              imageUrl: item.product.thumbnail,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) =>
                  const Icon(Icons.image_not_supported_outlined),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.product.salePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.jade,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Decrease quantity',
                      onPressed: () => context.read<CartController>().update(
                        item.product.id,
                        item.quantity - 1,
                      ),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      tooltip: 'Increase quantity',
                      onPressed: item.quantity < item.product.stock
                          ? () => context.read<CartController>().update(
                              item.product.id,
                              item.quantity + 1,
                            )
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Remove item',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => context.read<CartController>().update(
                        item.product.id,
                        0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart});
  final CartController cart;
  @override
  Widget build(BuildContext context) {
    final totals = cart.totals;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _totalRow('Subtotal', totals.subtotal),
              const SizedBox(height: 6),
              _totalRow('Discount', -totals.discount),
              const Divider(height: 22),
              _totalRow('Grand total', totals.grandTotal, bold: true),
              if (cart.checkoutFailure != null) ...[
                const SizedBox(height: 8),
                Text(
                  cart.checkoutFailure!.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: cart.checkoutStatus == CheckoutStatus.processing
                      ? null
                      : () async {
                          final userId = context
                              .read<AuthController>()
                              .user
                              ?.id;
                          if (userId == null) return;
                          final success = await context
                              .read<CartController>()
                              .placeOrder(userId);
                          if (success && context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    OrderSuccessPage(orderId: cart.orderId),
                              ),
                            );
                          }
                        },
                  child: cart.checkoutStatus == CheckoutStatus.processing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Place order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool bold = false}) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
      ),
      Text(
        '${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: bold ? 19 : 14,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: bold ? AppTheme.jade : AppTheme.ink,
        ),
      ),
    ],
  );
}

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key, this.orderId});
  final int? orderId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order confirmation')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xFFE0F1E8),
              child: Icon(Icons.check_rounded, size: 46, color: AppTheme.jade),
            ),
            const SizedBox(height: 22),
            Text(
              'Order placed!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your simulated order ${orderId == null ? '' : '#$orderId '}was received. Happy shopping!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue shopping'),
            ),
          ],
        ),
      ),
    ),
  );
}
