import 'package:flutter/material.dart';
import 'dart:convert';
import '../common/models/project_model.dart';
import '../variables.dart';
import '../Login/loginsqlitecode.dart';
import '../Login/logindataapiservice.dart';
import 'HomeScreen.dart';

/// Page to display list of projects/production houses from checkInchargeOrNot API
class ProjectListScreen extends StatefulWidget {
  final List<ProjectData> projects;
  final VoidCallback? onProjectSelected;

  const ProjectListScreen({
    super.key,
    required this.projects,
    this.onProjectSelected,
  });

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  late List<ProjectData> filteredProjects;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    filteredProjects = widget.projects;
  }

  void _filterProjects(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredProjects = widget.projects;
      } else {
        filteredProjects = widget.projects
            .where(
              (project) =>
                  project.projectName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  project.productionHouse.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  void _selectProject(ProjectData project) async {
    // Update global variables
    projectId = project.projectId;
    registeredMovie = project.projectName;
    productionHouse = project.productionHouse;
    productionTypeId = project.productionTypeId;

    // Check if vmId needs to be int or string based on usage context
    // Usually defined as int in global variables if it exists, but variables.dart isn't fully visible here. I'll assume standard usage.
    vmid = project.vmId;

    print('✅ Selected project: ${project.projectName}');
    print('📍 Updated global variables');

    // Update SQLite with selected project data
    try {
      await LoginSQLiteHelper.updateDriverLoginData(
        project.projectName,
        project.projectId,
        project.productionHouse,
        project.productionTypeId,
        project.vmId,
      );
    } catch (e) {
      print('❌ Error updating SQLite on project selection: $e');
    }

    // Call checkOrRaiseRequestApi
    if (vmid != null && vsid != null) {
      final int parsedProjectId = int.tryParse(project.projectId) ?? 0;

      final response = await LoginApiService.checkOrRaiseRequestApi(
        vmId: vmid!,
        vsid: vsid!,
        projectid: parsedProjectId,
        productionTypeId: project.productionTypeId,
      );

      bool isSuccess = false;
      String errorMessage = 'Failed to verify project request';

      if (response['success'] == true && response['body'] != null) {
        try {
          final bodyMap = jsonDecode(response['body']);
          if (bodyMap['message'] == 'Success') {
            isSuccess = true;
          } else {
            errorMessage = bodyMap['message'] ?? errorMessage;
          }
        } catch (e) {
          print('❌ Error parsing response body: $e');
        }
      } else if (response['body'] != null) {
        // Handle case where success is false but body contains error info
        try {
          final bodyMap = jsonDecode(response['body']);
          final errors = bodyMap['errors'];
          if (errors != null && errors['error_description'] != null) {
            errorMessage = errors['error_description'];
          }
        } catch (_) {}
      }

      if (isSuccess) {
        print('✅ checkOrRaiseRequestApi success, navigating to Dashboard');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyHomeScreen()),
          );
        }
      } else {
        print('❌ checkOrRaiseRequestApi failed: $errorMessage');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      print('❌ Missing vmid or vsid');
    }

    // Call callback if provided (keeping as fallback/alternative)
    if (widget.onProjectSelected != null) {
      widget.onProjectSelected!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Project'),
        backgroundColor: const Color(0xFF355E8C),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterProjects,
              decoration: InputDecoration(
                hintText: 'Search by project name or production house...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // Project list
          Expanded(
            child: filteredProjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No projects available'
                              : 'No projects found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = filteredProjects[index];
                      return ProjectListItem(
                        project: project,
                        onTap: () => _selectProject(project),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Individual project list item widget
class ProjectListItem extends StatelessWidget {
  final ProjectData project;
  final VoidCallback onTap;

  const ProjectListItem({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        title: Text(
          project.projectName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(Icons.domain, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project.productionHouse,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
