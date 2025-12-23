import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_kit_example/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Network Kit Example App Smoke Test', (WidgetTester tester) async {
    // 1. Setup mock storage for example app
    SharedPreferences.setMockInitialValues({});

    // 2. Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // 3. Verify initial state
    expect(find.textContaining('System Initialized'), findsOneWidget);
    expect(find.text('FETCH DATA'), findsOneWidget);

    // 4. Tap Fetch Data
    await tester.tap(find.byType(ElevatedButton));
    
    // 5. Let it settle (network client has async calls)
    await tester.pumpAndSettle();

    // 6. Verify success or failure appears in logs
    // Given we are hitting a real API in example/lib/main:
    // This will either show SUCCESS (if network) or OFFLINE (if no network)
    expect(
      find.byWidgetPredicate((widget) => 
        widget is Text && (widget.data!.contains('SUCCESS') || widget.data!.contains('OFFLINE'))), 
      findsOneWidget
    );
  });
}
