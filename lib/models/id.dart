class Id {
  final String driver;
  final String ride;
  Id({required this.driver, required this.ride});

  @override
  bool operator ==(covariant Id other) =>
      other.driver == driver && other.ride == ride;

  @override
  int get hashCode => Object.hash(driver, ride);
}
