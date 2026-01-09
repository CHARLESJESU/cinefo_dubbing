import 'package:cinefo_dubbing/Screen/home/approval_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../common/models/project_model.dart';
import '../../variables.dart';
import '../../Login/loginsqlitecode.dart';
import '../../Login/logindataapiservice.dart';
import '../../Route/RouteScreenfordubbingincharge.dart';
import '../../ApiCalls/apicall.dart';
import '../../colorcode/colorcode.dart';
import 'HomeScreen.dart';

/// Page to display list of projects/production houses from checkInchargeOrNot API
class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<ProjectData> _projects = [];
  late List<ProjectData> filteredProjects;
  String searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    filteredProjects = [];
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // First fetch login data from SQLite
      await fetchloginDataFromSqlite();
      print('✅ Login data loaded from SQLite');

      // Then fetch driver session to get projects
      if (vmid != null && vsid != null) {
        final response = await LoginApiService.fetchDriverSession(
          vmId: vmid!,
          vsid: vsid!,
        );

        if (response['success'] == true && response['body'] != null) {
          final bodyMap = jsonDecode(response['body']);

          if (bodyMap['message'] == 'Success' &&
              bodyMap['responseData'] != null) {
            final List<dynamic> responseData = bodyMap['responseData'];

            setState(() {
              _projects = responseData
                  .map((data) => ProjectData.fromJson(data))
                  .toList();
              filteredProjects = _projects;
              _isLoading = false;
            });

            print('✅ Loaded ${_projects.length} projects from API');
          } else {
            setState(() {
              _errorMessage = bodyMap['message'] ?? 'Failed to load projects';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage =
                response['errorMessage'] ?? 'Failed to load projects';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Missing session data. Please login again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching projects: $e');
      setState(() {
        _errorMessage = 'Error loading projects: $e';
        _isLoading = false;
      });
    }
  }

  void _filterProjects(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredProjects = _projects;
      } else {
        filteredProjects = _projects
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

    // Navigate to ApprovalScreen so it can display and trigger raiserequestapi
    try {
      final int parsedProjectId = int.tryParse(project.projectId) ?? 0;
      final Map<String, dynamic> callSheet = {
        'callSheetId': 0,
        'projectid': parsedProjectId,
      };

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApprovalScreen(parsedProjectId),
          ),
        );
      }
    } catch (e) {
      print('❌ Error navigating to ApprovalScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Project',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // // Search bar
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: TextField(
          //     onChanged: _filterProjects,
          //     decoration: InputDecoration(
          //       hintText: 'Search by project name or production house...',
          //       prefixIcon: const Icon(Icons.search),
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //       filled: true,
          //       fillColor: Colors.grey[100],
          //     ),
          //   ),
          // ),
          // // Project list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryLight,
                      ),
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredProjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppColors.primaryLight.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No projects available'
                              : 'No projects found',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: AppColors.primaryLight.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: AppColors.primaryLight, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.projectName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.domain, size: 16, color: AppColors.primaryLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        project.productionHouse,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.primaryLight.withOpacity(0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}