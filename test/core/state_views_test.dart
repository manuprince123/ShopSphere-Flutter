import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/widgets/state_views.dart';

void main() {
  Future<void> showShortViewport(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(600, 150));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, page) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: page!,
        ),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('error retry remains reachable in a short large-text viewport', (
    tester,
  ) async {
    var retried = false;
    await showShortViewport(
      tester,
      ErrorView(
        message: 'You appear to be offline. Check your connection and retry.',
        onRetry: () => retried = true,
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Try again'), 100);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('empty-state action remains reachable with large text', (
    tester,
  ) async {
    var acted = false;
    await showShortViewport(
      tester,
      EmptyView(
        title: 'Your bag is empty',
        message: 'Find something you love in the catalogue.',
        icon: Icons.shopping_bag_outlined,
        action: FilledButton(
          onPressed: () => acted = true,
          child: const Text('Explore products'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Explore products'), 100);
    await tester.tap(find.text('Explore products'));
    expect(acted, isTrue);
  });
}
