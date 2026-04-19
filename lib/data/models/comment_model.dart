class CommentModel {
  final String id;
  final String ticketId;
  final String userId;
  final String isi;
  final DateTime createdAt;
  final Map<String, dynamic>? userProfile;

  CommentModel({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.isi,
    required this.createdAt,
    this.userProfile,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      ticketId: json['ticket_id'],
      userId: json['user_id'],
      isi: json['isi'],
      createdAt: DateTime.parse(json['created_at']),
      userProfile: json['profiles'],
    );
  }
}