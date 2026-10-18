import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../cart/presentation/cart_controller.dart';
import '../cart/presentation/cart_page.dart';
import '../products/presentation/catalog_page.dart';
import '../products/presentation/product_detail_page.dart';
import '../profile/presentation/profile_page.dart';
import '../wishlist/presentation/wishlist_page.dart';

class ShopShell extends StatefulWidget {
  const ShopShell({super.key});
  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  int tab = 0;
  int? selectedProductId;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final expanded = width > 1024;
    final count = context.select<CartController, int>((cart) => cart.count);
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.grid_view_outlined),
        selectedIcon: const Icon(Icons.grid_view_rounded),
        label: context.l10n.t('explore'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.favorite_border_rounded),
        selectedIcon: const Icon(Icons.favorite_rounded),
        label: context.l10n.t('saved'),
      ),
      NavigationDestination(
        icon: CartIcon(count: count),
        label: context.l10n.t('cart'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline_rounded),
        selectedIcon: const Icon(Icons.person_rounded),
        label: context.l10n.t('profile'),
      ),
    ];

    Widget page;
    switch (tab) {
      case 0:
        page = expanded
            ? Row(
                children: [
                  Expanded(
                    child: CatalogPage(
                      onProductTap: (id) =>
                          setState(() => selectedProductId = id),
                      listMode: true,
                    ),
                  ),
                  Container(
                    width: 450,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      border: const Border(
                        left: BorderSide(color: Color(0xFFE6EAE4)),
                      ),
                    ),
                    child: selectedProductId == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.touch_app_outlined,
                                  size: 48,
                                  color: AppTheme.jade,
                                ),
                                const SizedBox(height: 12),
                                Text(context.l10n.t('selectProduct')),
                              ],
                            ),
                          )
                        : ProductDetailContent(
                            key: ValueKey(selectedProductId),
                            productId: selectedProductId!,
                          ),
                  ),
                ],
              )
            : CatalogPage(
                onProductTap: (id) => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ProductDetailPage(productId: id),
                  ),
                ),
              );
        break;
      case 1:
        page = WishlistPage(
          onProductTap: (id) => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailPage(productId: id),
            ),
          ),
        );
        break;
      case 2:
        page = const CartPage();
        break;
      default:
        page = const ProfilePage();
    }

    return Scaffold(
      body: SafeArea(
        child: compact
            ? page
            : Row(
                children: [
                  NavigationRail(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainer,
                    selectedIndex: tab,
                    onDestinationSelected: (index) =>
                        setState(() => tab = index),
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: AppTheme.jade,
                        size: 32,
                      ),
                    ),
                    destinations: [
                      NavigationRailDestination(
                        icon: const Icon(Icons.grid_view_outlined),
                        selectedIcon: const Icon(Icons.grid_view_rounded),
                        label: Text(context.l10n.t('explore')),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.favorite_border_rounded),
                        selectedIcon: const Icon(Icons.favorite_rounded),
                        label: Text(context.l10n.t('saved')),
                      ),
                      NavigationRailDestination(
                        icon: CartIcon(count: count),
                        label: Text(context.l10n.t('cart')),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.person_outline_rounded),
                        selectedIcon: const Icon(Icons.person_rounded),
                        label: Text(context.l10n.t('profile')),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: page),
                ],
              ),
      ),
      bottomNavigationBar: compact
          ? NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (index) => setState(() => tab = index),
              destinations: destinations,
            )
          : null,
    );
  }
}

class CartIcon extends StatelessWidget {
  const CartIcon({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: count > 0,
    label: Text('$count'),
    child: const Icon(Icons.shopping_bag_outlined),
  );
}
