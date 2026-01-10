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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Project',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.05,
          ),
        ),
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white,
          size: screenWidth * 0.065,
        ),
      ),
      body: Column(
        children: [
          // // Search bar
          // Padding(
          //   padding: EdgeInsets.all(screenWidth * 0.04),
          //   child: TextField(
          //     onChanged: _filterProjects,
          //     decoration: InputDecoration(
          //       hintText: 'Search by project name or production house...',
          //       prefixIcon: const Icon(Icons.search),
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(screenWidth * 0.02),
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
                          size: screenWidth * 0.16,
                          color: Colors.red.shade300,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        ElevatedButton.icon(
                          onPressed: _fetchData,
                          icon: Icon(
                            Icons.refresh,
                            size: screenWidth * 0.05,
                          ),
                          label: Text(
                            'Retry',
                            style: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.06,
                              vertical: screenHeight * 0.015,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.02,
                              ),
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
                          size: screenWidth * 0.16,
                          color: AppColors.primaryLight.withOpacity(0.5),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          searchQuery.isEmpty
                              ? 'No projects available'
                              : 'No projects found',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      elevation: 2,
      shadowColor: AppColors.primaryLight.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            border: Border(
              left: BorderSide(
                color: AppColors.primaryLight,
                width: screenWidth * 0.01,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.projectName,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  children: [
                    Icon(
                      Icons.domain,
                      size: screenWidth * 0.04,
                      color: AppColors.primaryLight,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: Text(
                        project.productionHouse,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: screenWidth * 0.035,
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