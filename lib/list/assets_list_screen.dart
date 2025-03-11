import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/auth_service.dart';
import '../services/database_service.dart';
import '../models/project.dart';
import '../utils/theme_colors.dart';
import '../utils/date_util.dart';
import '../widgets/asset_flow_loader.dart';
import 'asset_detail_screen.dart';
import 'empty_assets_screen.dart';
import '../new/add_investment_screen.dart';

/// Screen that displays all user assets/investments
class AssetsListScreen extends StatefulWidget {
  const AssetsListScreen({super.key});

  @override
  _AssetsListScreenState createState() => _AssetsListScreenState();
}

class _AssetsListScreenState extends State<AssetsListScreen> {
  static final Logger _logger = Logger('AssetsListScreen');
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _logger.info('AssetsListScreen initialized');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Investments'),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmSignOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      // Use StreamBuilder to listen for changes in projects
      body: StreamBuilder<List<Project>>(
        stream: _databaseService.getUserProjects(),
        builder: (context, snapshot) {
          // Show loading while waiting for data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: AssetFlowLoader(
                size: 60,
                primaryColor: Theme.of(context).primaryColor,
              ),
            );
          }

          // Handle error state
          if (snapshot.hasError) {
            _logger.severe('Error fetching projects: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AssetFlowColors.error,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading investments',
                    style: TextStyle(
                      fontSize: 18,
                      color: AssetFlowColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        // Refresh the state to trigger a new fetch
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Handle empty state
          final projects = snapshot.data ?? [];
          if (projects.isEmpty) {
            return const EmptyAssetsScreen();
          }

          // Display list of projects
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                // Force refresh
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return _buildProjectCard(context, project);
              },
            ),
          );
        },
      ),
      // FAB to add new investment
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _logger.info('Add investment button pressed');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInvestmentScreen()),
          );
        },
        backgroundColor: AssetFlowColors.primary,
        tooltip: 'Add Investment',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Build a card for a single project
  Widget _buildProjectCard(BuildContext context, Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _logger.info('Project card tapped: ${project.id}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssetDetailScreen(projectId: project.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project name
              Text(
                project.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AssetFlowColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              // Company name
              Row(
                children: [
                  const Icon(
                    Icons.business,
                    size: 16,
                    color: AssetFlowColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    project.company,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AssetFlowColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Project length
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AssetFlowColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${project.projectLengthMonths} months',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AssetFlowColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Date created
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AssetFlowColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Created: ${DateUtil.formatDate(project.createdAt)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AssetFlowColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // View details button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    _logger.info('View details button pressed: ${project.id}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetDetailScreen(projectId: project.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: AssetFlowColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirm sign out with dialog
  void _confirmSignOut() {
    _logger.info('Sign out confirmation requested');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  /// Sign out the current user
  Future<void> _signOut() async {
    _logger.info('Signing out user');
    try {
      await _authService.signOut();
      // Navigation will be handled by the AuthWrapper
    } catch (e) {
      _logger.severe('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }
}