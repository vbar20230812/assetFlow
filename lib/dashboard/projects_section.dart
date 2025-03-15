import 'package:flutter/material.dart';
import '../models/project.dart';
import '../utils/theme_colors.dart';
import '../utils/formatter_util.dart';
import '../utils/date_util.dart';

/// Projects section of the dashboard
class ProjectsSection extends StatelessWidget {
  final List<Project> projects;

  const ProjectsSection({
    Key? key,
    required this.projects,
  }) : super(key: key);

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
            const Text(
              'Your Projects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            ...projects.map((project) => _buildProjectListItem(context, project)).toList(),
          ],
        ),
      ),
    );
  }

  // Project list item
  Widget _buildProjectListItem(BuildContext context, Project project) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          // Navigate to project details
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => AssetDetailScreen(projectId: project.id),
          //   ),
          // );
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
            ],
          ),
        ),
      ),
    );
  }
}