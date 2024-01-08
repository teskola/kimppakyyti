import 'package:flutter_test/flutter_test.dart';
import 'package:kimppakyyti/models/id.dart';

void main() {
  final id1 = Id(driver: 'driver', ride: 'ride');
  final id2 = Id(driver: 'driver', ride: 'ride');
  final id3 = Id(driver: 'driver', ride: 'Ride');
  test('equal', () => expect(id1 == id2, true));
  test('not equal', () => expect(id1 == id3, false));
}
