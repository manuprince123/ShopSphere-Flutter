import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/state_views.dart';
import '../../products/presentation/catalog_page.dart';
import 'wishlist_controller.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key, required this.onProductTap});

  final ValueChanged<int> onProductTap;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Text(
            context.l10n.t('savedItems'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: !wishlist.loaded
              ? const Center(child: CircularProgressIndicator())
              : wishlist.products.isEmpty
              ? EmptyView(
                  icon: Icons.favorite_border_rounded,
                  title: context.l10n.t('emptyWishlist'),
                  message: context.l10n.t('emptyWishlistMessage'),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth < 500
                        ? 2
                        : constraints.maxWidth < 850
                        ? 3
                        : 4;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: wishlist.products.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 332,
                      ),
                      itemBuilder: (context, index) {
                        final product = wishlist.products[index];
                        return ProductCard(
                          product: product,
                          onTap: () => onProductTap(product.id),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
