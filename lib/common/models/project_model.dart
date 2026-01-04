/// Model class to represent project/production house data
class ProjectData {
  final int vmId;
  final int productionTypeId;
  final String projectId;
  final String projectName;
  final String productionHouse;

  ProjectData({
    required this.vmId,
    required this.productionTypeId,
    required this.projectId,
    required this.projectName,
    required this.productionHouse,
  });

  /// Factory constructor to create ProjectData from JSON
  factory ProjectData.fromJson(Map<String, dynamic> json) {
    return ProjectData(
      vmId: json['vmId'] ?? json['vmid'] ?? 0,
      productionTypeId: json['productionTypeId'] ?? 0,
      projectId: json['projectId']?.toString() ?? '',
      projectName: json['projectName']?.toString() ?? '',
      productionHouse: json['productionHouse']?.toString() ?? '',
    );
  }

  /// Convert ProjectData to JSON
  Map<String, dynamic> toJson() {
    return {
      'vmId': vmId,
      'productionTypeId': productionTypeId,
      'projectId': projectId,
      'projectName': projectName,
      'productionHouse': productionHouse,
    };
  }

  @override
  String toString() {
    return 'ProjectData(vmId: $vmId, productionTypeId: $productionTypeId, projectId: $projectId, projectName: $projectName, productionHouse: $productionHouse)';
  }
}
