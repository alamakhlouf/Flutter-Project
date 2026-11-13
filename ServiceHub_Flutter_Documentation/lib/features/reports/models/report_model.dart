class ReportModel {
  const ReportModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporterId,
    this.reporterName,
    this.targetTitle,
    this.description = '',
  });

  final String id;
  final String? reporterId;
  final String? reporterName;
  final String targetType;
  final String targetId;
  final String? targetTitle;
  final String reason;
  final String description;
  final String status;
  final DateTime? createdAt;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final targetType = json['targetType'];
    final targetId = json['targetId'];
    final reason = json['reason'];
    final status = json['status'];
    if (id == null ||
        targetType == null ||
        targetId == null ||
        reason == null ||
        status == null) {
      throw const FormatException('Incomplete report payload');
    }

    final reporterIdRaw = json['reporterId'] ?? json['reporter_id'];
    final reporterNameRaw =
        json['reporterName'] ?? json['reporterFullName'] ?? json['reporter'];
    final targetTitleRaw =
        json['targetTitle'] ?? json['targetName'] ?? json['targetLabel'];

    return ReportModel(
      id: id.toString(),
      reporterId: reporterIdRaw?.toString(),
      reporterName: reporterNameRaw?.toString(),
      targetType: targetType.toString(),
      targetId: targetId.toString(),
      targetTitle: targetTitleRaw?.toString(),
      reason: reason.toString(),
      description: json['description']?.toString() ?? '',
      status: status.toString(),
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
