import 'package:flutter_test/flutter_test.dart';
import 'package:kimppakyyti/utilities/map_utils.dart';

void main() {
  group('Distance between coordinates', () {
    test(
        'Positive distance',
        () =>
            {expect(MapUtils.getDistance(0.0, 0.0, 30.0, 60.0).round(), 7154)});
    test('Zero distance', () => {
      expect(MapUtils.getDistance(10.0, -5.0, 10.0, -5.0).round(), 0)
    }
    );
  });
}
