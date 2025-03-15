import 'package:flutter/material.dart';
import '../models/project.dart';
import '../utils/theme_colors.dart';
import '../utils/formatter_util.dart';
import '../utils/date_util.dart';
import '../services/database_service.dart';
import '../list/edit_project_screen.dart';
import '../list/asset_detail_screen.dart';

/// Projects section of the dashboard with edit, delete, and archive functionality
class ProjectsSection extends StatefulWidget {
  final List<Project> projects;

  const ProjectsSection({
    Key? key,
    required this.projects,
  }) : super(key: key);

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  final DatabaseService _databaseService = DatabaseService();
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Projects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Project'),
                  onPressed: () => _addNewProject(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AssetFlowColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            ...widget.projects.map((project) => _buildProjectListItem(context, project)).toList(),
          ],
        ),
      ),
    );
  }

  // Project list item with action buttons
  Widget _buildProjectListItem(BuildContext context, Project project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          // Navigate to project details
          _navigateToProjectDetails(context, project);
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    FormatterUtil.formatCurrency(
                      project.investmentAmount, 
                      currencyCode: project.currency
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AssetFlowColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Text(
                project.company,
                style: const TextStyle(
                  color: AssetFlowColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AssetFlowColors.textSecondary,
                  ),
                  const SizedBox(width: 4.0),
                  Flexible(
                    child: Text(
                      'Started: ${DateUtil.formatShortDate(project.startDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AssetFlowColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: AssetFlowColors.textSecondary,
                  ),
                  const SizedBox(width: 4.0),
                  Flexible(
                    child: Text(
                      'Duration: ${FormatterUtil.formatDuration(project.projectLengthMonths)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AssetFlowColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // Action buttons row
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit button
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: Colors.blue,
                    onPressed: () => _navigateToEditProject(context, project),
                  ),
                  const SizedBox(width: 8.0),
                  
                  // Archive/Unarchive button
                  _buildActionButton(
                    icon: project.isArchived ? Icons.unarchive : Icons.archive,
                    label: project.isArchived ? 'Unarchive' : 'Archive',
                    color: Colors.amber,
                    onPressed: () => _toggleArchiveStatus(project),
                  ),
                  const SizedBox(width: 8.0),
                  
                  // Delete button
                  _buildActionButton(
                    icon: Icons.delete,
                    label: 'Delete',
                    color: Colors.red,
                    onPressed: () => _confirmDelete(context, project),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper to build action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle archive status
  Future<void> _toggleArchiveStatus(Project project) async {
    try {
      if (project.isArchived) {
        await _databaseService.unarchiveProject(project.id);
      } else {
        await _databaseService.archiveProject(project.id);
      }
      // No need to refresh manually as StreamBuilder will handle it
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Delete project with confirmation
  void _confirmDelete(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _databaseService.deleteProject(project.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Project deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting project: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Navigate to edit project screen
  void _navigateToEditProject(BuildContext context, Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProjectScreen(project: project),
      ),
    );
  }
  
  // Navigate to project details
  void _navigateToProjectDetails(BuildContext context, Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetDetailScreen(projectId: project.id),
      ),
    );
  }
  
  // Add new project
  void _addNewProject(BuildContext context) {
    // Navigate to appropriate screen to add a new project
    // This would typically be your project creation flow
    // e.g., Navigator.pushNamed(context, '/add_project');
  }
}