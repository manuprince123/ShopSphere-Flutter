import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory('screenshots/qa');
  await output.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      return bytes.length > 8 && bytes[0] == 137 && bytes[1] == 80;
    },
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      await Directory('docs').create(recursive: true);
      await File('docs/live-api-results.json').writeAsString(
        const JsonEncoder.withIndent(
          '  ',
        ).convert({'checks': data?['checks'], 'requests': data?['requests']}),
      );
    },
  );
}
