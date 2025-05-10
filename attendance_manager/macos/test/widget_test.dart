import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_manager/main.dart';
import 'package:attendance_manager/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen loads correctly', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the HomeScreen is displayed.
    expect(find.byType(HomeScreen), findsOneWidget);

    // Verify that the app bar title is correct.
    expect(find.text("Today's Schedule"), findsOneWidget);

    // Verify that the refresh button is present.
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}