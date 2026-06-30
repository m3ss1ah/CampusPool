/// CampusPool Commute Model
class CommuteModel {
  final String id;
  final String creatorId;
  final String? creatorName;
  final String? creatorPic;
  final String sourceLabel;
  final double sourceLat;
  final double sourceLng;
  final String destLabel;
  final double destLat;
  final double destLng;
  final DateTime departureTime;
  final int totalSeats;
  final int availableSeats;
  final String? vehicleType;
  final String? notes;
  final String status;
  final double? distanceMeters;
  final DateTime createdAt;

  // Detail-only fields
  final Map<String, dynamic>? creator;
  final List<Map<String, dynamic>>? participants;
  final String? myRequestStatus;
  final int? pendingRequests;

  const CommuteModel({
    required this.id,
    required this.creatorId,
    this.creatorName,
    this.creatorPic,
    required this.sourceLabel,
    required this.sourceLat,
    required this.sourceLng,
    required this.destLabel,
    required this.destLat,
    required this.destLng,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    this.vehicleType,
    this.notes,
    required this.status,
    this.distanceMeters,
    required this.createdAt,
    this.creator,
    this.participants,
    this.myRequestStatus,
    this.pendingRequests,
  });

  factory CommuteModel.fromJson(Map<String, dynamic> j) => CommuteModel(
    id: j['id'],
    creatorId: j['creator_id'],
    creatorName: j['creator_name'],
    creatorPic: j['creator_pic'],
    sourceLabel: j['source_label'],
    sourceLat: (j['source_lat'] as num).toDouble(),
    sourceLng: (j['source_lng'] as num).toDouble(),
    destLabel: j['dest_label'],
    destLat: (j['dest_lat'] as num).toDouble(),
    destLng: (j['dest_lng'] as num).toDouble(),
    departureTime: DateTime.parse(j['departure_time']),
    totalSeats: j['total_seats'],
    availableSeats: j['available_seats'],
    vehicleType: j['vehicle_type'],
    notes: j['notes'],
    status: j['status'],
    distanceMeters: j['distance_meters'] != null
        ? (j['distance_meters'] as num).toDouble()
        : null,
    createdAt: DateTime.parse(j['created_at']),
    creator: j['creator'] != null
        ? Map<String, dynamic>.from(j['creator'])
        : null,
    participants: j['participants'] != null
        ? (j['participants'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : null,
    myRequestStatus: j['my_request_status'],
    pendingRequests: j['pending_requests'] != null
        ? int.tryParse(j['pending_requests'].toString())
        : null,
  );

  /// Required for Hive caching
  Map<String, dynamic> toJson() => {
    'id': id,
    'creator_id': creatorId,
    'creator_name': creatorName,
    'creator_pic': creatorPic,
    'source_label': sourceLabel,
    'source_lat': sourceLat,
    'source_lng': sourceLng,
    'dest_label': destLabel,
    'dest_lat': destLat,
    'dest_lng': destLng,
    'departure_time': departureTime.toIso8601String(),
    'total_seats': totalSeats,
    'available_seats': availableSeats,
    'vehicle_type': vehicleType,
    'notes': notes,
    'status': status,
    'distance_meters': distanceMeters,
    'created_at': createdAt.toIso8601String(),
  };
}
