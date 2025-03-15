import 'package:flutter/material.dart';
import '../models/project.dart';
import '../utils/theme_colors.dart';
import '../utils/formatter_util.dart';
import '../utils/date_util.dart';

/// Projects tab for dashboard displaying list of projects
class ProjectsTab extends StatelessWidget {
  final List<Project> projects;
  
  const ProjectsTab({
    Key? key,
    required this.projects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectCard(context, project);
      },
    );
  }
  
  Widget _buildProjectCard(BuildContext context, Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          // Navigate to project details
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => AssetDetailScreen(projectId: project.id),
          //   ),
          // );
        },
        child: Padding(
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
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: AssetFlowColors.primary,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      FormatterUtil.formatCurrency(
                        project.investmentAmount,
                        currencyCode: project.currency,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                project.company,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16.0),
              // Project details in nice grid layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    Icons.calendar_today,
                    'Start Date',
                    DateUtil.formatShortDate(project.startDate),
                  ),
                  _buildInfoItem(
                    Icons.event,
                    'First Payment',
                    DateUtil.formatShortDate(project.firstPaymentDate),
                  ),
                  _buildInfoItem(
                    Icons.schedule,
                    'Duration',
                    FormatterUtil.formatDuration(project.projectLengthMonths),
                  ),
                ],
              ),
              // If there are fees, show them
              if (project.nonRefundableFee > 0 || project.refundableFee > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      if (project.nonRefundableFee > 0)
                        Expanded(
                          child: _buildInfoItem(
                            Icons.money_off,
                            'Non-Refundable Fee',
                            FormatterUtil.formatCurrency(
                              project.nonRefundableFee,
                              currencyCode: project.currency,
                            ),
                          ),
                        ),
                      if (project.refundableFee > 0)
                        Expanded(
                          child: _buildInfoItem(
                            Icons.account_balance_wallet,
                            'Refundable Fee',
                            FormatterUtil.formatCurrency(
                              project.refundableFee,
                              currencyCode: project.currency,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16.0,
              color: AssetFlowColors.textSecondary,
            ),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.0,
                color: AssetFlowColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}