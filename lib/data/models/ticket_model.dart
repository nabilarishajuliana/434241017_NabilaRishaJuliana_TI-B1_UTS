class TicketModel {
  final String id;
  final String judul;
  final String deskripsi;
  final String status;
  final String userId;
  final String? assignedTo;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? userProfile;

  TicketModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.status,
    required this.userId,
    this.assignedTo,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.userProfile,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      judul: json['judul'],
      deskripsi: json['deskripsi'],
      status: json['status'],
      userId: json['user_id'],
      assignedTo: json['assigned_to'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userProfile: json['profiles'],
    );
  }
}