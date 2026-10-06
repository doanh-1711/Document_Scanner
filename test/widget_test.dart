import 'package:flutter_test/flutter_test.dart';
import 'package:doc_scanner/main.dart';

void main() {
  testWidgets('Document Scanner App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DocumentScannerApp());
    expect(find.text('Document Scanner'), findsOneWidget);
  });
}
