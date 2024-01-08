class DepartureTime implements Comparable<DepartureTime> {
  DateTime? min;
  DateTime? max;
  DateTime? actual;

  DepartureTime(this.min, this.max, {this.actual});

  DateTime get minimum {
    return actual ?? min!;
  }

  DateTime get maximum {
    return actual ?? max!;
  }

  bool get isActive {
    return DateTime.now().compareTo(maximum.add(const Duration(days: 1))) < 0;
  }

  bool get isLate {
    return DateTime.now().compareTo(maximum) >= 0;
  }

  List<DateTime>? get dates {
    if (min != null && max != null) {
      final DateTime first = DateTime(min!.year, min!.month, min!.day);
      final DateTime last = DateTime(max!.year, max!.month, max!.day);
      DateTime current = first;
      List<DateTime> list = [current];
      while (last.isAfter(current)) {
        current = current.add(const Duration(days: 1));
        list.add(current);
      }
      return list;
    }
    return null;
  }

  Map<String, int?> toJson() => {
        'min': min?.millisecondsSinceEpoch,
        'max': max?.millisecondsSinceEpoch,
        'actual': actual?.millisecondsSinceEpoch
      };

  factory DepartureTime.fromJson(Map<Object?, Object?> json) {
    
    final min = DateTime.fromMillisecondsSinceEpoch(json['min'] as int);
    final max = DateTime.fromMillisecondsSinceEpoch(json['max'] as int);
    DateTime? actual;
    if (json.containsKey('actual')) {
      actual = DateTime.fromMillisecondsSinceEpoch(json['actual'] as int);
    }
    return DepartureTime(min, max, actual: actual);
  }

  @override
  int compareTo(DepartureTime other) {
    return minimum.compareTo(other.minimum);
  }
}
