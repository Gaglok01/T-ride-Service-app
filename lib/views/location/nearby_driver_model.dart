class NearbyDriver {
  const NearbyDriver({
    required this.id,
    required this.name,
    required this.rating,
    required this.vehicle,
    required this.photo,
    required this.eta,
    required this.distance,
  });

  final int id;
  final String name;
  final String rating;
  final String? vehicle;
  final String? photo;
  final String eta;
  final String distance;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  static NearbyDriver fromJson(Map<String, dynamic> json) {
    return NearbyDriver(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      rating: json['rating']?.toString() ?? '0.0',
      vehicle: json['vehicle'] as String?,
      photo: json['photo'] as String?,
      eta: json['eta'] as String? ?? '',
      distance: json['distance']?.toString() ?? '',
    );
  }
}

