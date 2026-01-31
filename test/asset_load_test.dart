import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('can load items_master.json from rootBundle', () async {
    final json = await rootBundle.loadString('assets/game_data/items/items_master.json');
    expect(json, isNotEmpty);
    expect(json.contains('"items"'), isTrue);
  });
}

