import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quicktask_vikunja/build_info.dart';
import 'package:quicktask_vikunja/ui/widgets/version_footer.dart';

void main() {
  testWidgets('VersionFooter renders v<appVersion>', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(bottomNavigationBar: VersionFooter()),
    ));

    expect(find.text('v$appVersion'), findsOneWidget);
  });
}
