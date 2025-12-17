// This is a basic Flutter widget test for the Car Rental App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_rental_app/main.dart';

void main() {
  testWidgets('CarRentalApp widget test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CarRentalApp());

    // Verify that the app title is displayed (from MaterialApp configuration).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}