import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/cart/domain/cart.dart';
import 'package:shopsphere/features/cart/presentation/cart_controller.dart';
import 'package:shopsphere/features/cart/presentation/cart_page.dart';

class EmptyCartRepository implements CartRepository {
  @override
  Future<List<CartItem>> load() async => [];
  @override
  Future<void> save(List<CartItem> items) async {}
  @override
  Future<Result<int>> placeOrder(int userId, List<CartItem> items) async =>
      const Success(1);
}

void main() {
  testWidgets('empty cart fits short landscape with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(650, 350));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = CartController(
      EmptyCartRepository(),
      const CalculateCartTotals(),
    );
    await controller.initialize();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: CartPage(),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Your bag is empty'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
