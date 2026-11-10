import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:service_hub/app/app.dart';
import 'package:service_hub/design_system/app_colors.dart';

void main() {
  testWidgets('ServiceHub starts with its brand theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ServiceHubApp());

    expect(find.text('ServiceHub'), findsOneWidget);
    expect(find.text('Welcome to ServiceHub'), findsOneWidget);
    expect(
      find.text('Find trusted local services, products, and workshops.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme
          ?.colorScheme
          .primary,
      AppColors.primary,
    );
  });
}
