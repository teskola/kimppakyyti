import 'package:flutter_test/flutter_test.dart';
import 'package:kimppakyyti/models/departure_time.dart';

void main() {
  group('Get dates', () {
    final min = DateTime(2023, 7, 20);
    final max = DateTime(2023, 7, 23);
    test('Min equals max', () {
      final dTime = DepartureTime(min, min);
      expect(dTime.dates, [min]);
    });
    test('Max greater than min', () {
      final dTime = DepartureTime(min, max);
      expect(dTime.dates,
          [min, DateTime(2023, 7, 21), DateTime(2023, 7, 22), max]);
    });
  });
}
