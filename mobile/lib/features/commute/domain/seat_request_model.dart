/// CampusPool Seat Request Model
class SeatRequestModel {
  final String id;
  final String commuteId;
  final String? requesterId;
  final String status;
  final String? message;
  final DateTime createdAt;

  // Joined fields from commute
  final String? sourceLabel;
  final String? destLabel;
  final DateTime? departureTime;

  // Joined fields from user
  final String? requesterName;
  final String? requesterPic;
  final String? requesterPhone;
  final String? creatorName;
  final String? creatorPic;

  const SeatRequestModel({
    required this.id,
    required this.commuteId,
    this.requesterId,
    required this.status,
    this.message,
    required this.createdAt,
    this.sourceLabel,
    this.destLabel,
    this.departureTime,
    this.requesterName,
    this.requesterPic,
    this.requesterPhone,
    this.creatorName,
    this.creatorPic,
  });

  factory SeatRequestModel.fromJson(Map<String, dynamic> j) => SeatRequestModel(
    id: j['id'],
    commuteId: j['commute_id'],
    requesterId: j['requester_id'],
    status: j['status'],
    message: j['message'],
    createdAt: DateTime.parse(j['created_at']),
    sourceLabel: j['source_label'],
    destLabel: j['dest_label'],
    departureTime: j['departure_time'] != null
        ? DateTime.parse(j['departure_time'])
        : null,
    requesterName: j['full_name'],
    requesterPic: j['profile_pic_url'],
    requesterPhone: j['phone'],
    creatorName: j['creator_name'],
    creatorPic: j['creator_pic'],
  );
}
