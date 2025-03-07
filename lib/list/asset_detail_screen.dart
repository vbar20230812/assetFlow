import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/project.dart';
import '../models/plan.dart';
import '../services/database_service.dart';
import '../utils/theme_colors.dart';
import '../utils/date_util.dart';
import '../utils/formatter_util.dart';
import '../widgets/asset_flow_loader.dart';
import '../widgets/asset_flow_loading_widget.dart';

/// Screen that displays detailed information about a single asset/investment
class AssetDetailScreen extends StatefulWidget {
  final String projectId;

  const AssetDetailScreen({super.key, required this.projectId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  static final Logger _logger = Logger('AssetDetailScreen');
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  late Project _project;
  List<Plan> _plans = [];

  @override
  void initState() {
    super.initState();
    _logger.info('AssetDetailScreen initialized for project: ${widget.projectId}');
    _loadProjectData();
  }

  /// Load project and plans data
  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _project = await _databaseService.getProject(widget.projectId);

      // Listen for plans updates
      _databaseService.getProjectPlans(widget.projectId).listen((plans) {
        if (mounted) {
          setState(() {
            _plans = plans;
            _isLoading = false;
          });
        }
      }, onError: (error) {
        _logger.severe('Error loading plans: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading plans: $error')),
          );
        }
      });
    } catch (e) {
      _logger.severe('Error loading project: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading project: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? const Text('Investment Details')
            : Text(_project.name),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editProject,
            tooltip: 'Edit',
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _confirmDeleteProject,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: AssetFlowLoadingWidget(
        isLoading: _isLoading,
        loadingText: 'Loading investment details...',
        child: _isLoading
            ? const SizedBox.shrink() // Will be covered by loading overlay
            : _buildProjectDetails(),
      ),
    );
  }

  /// Build the project details content
  Widget _buildProjectDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project overview section
          _buildProjectOverview(),
          
          const Divider(height: 32),
          
          // Plans section
          _buildPlansSection(),
        ],
      ),
    );
  }

  /// Build the project overview section
  Widget _buildProjectOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AssetFlowColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project name and company
          Text(
            _project.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AssetFlowColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.business,
                size: 16,
                color: AssetFlowColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                _project.company,
                style: const TextStyle(
                  fontSize: 16,
                  color: AssetFlowColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Project details
          _buildDetailItem(
            icon: Icons.calendar_today,
            label: 'Project Length',
            value: '${_project.projectLengthMonths} months',
          ),
          _buildDetailItem(
            icon: Icons.date_range,
            label: 'Created On',
            value: DateUtil.formatLongDate(_project.createdAt),
          ),
          _buildDetailItem(
            icon: Icons.update,
            label: 'Last Updated',
            value: DateUtil.formatLongDate(_project.updatedAt),
          ),
        ],
      ),
    );
  }

  /// Build a detail item with icon, label, and value
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AssetFlowColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AssetFlowColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AssetFlowColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the plans section
  Widget _buildPlansSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Investment Plans',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AssetFlowColors.textPrimary,
                ),
              ),
              // Add plan button
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _addPlan,
                tooltip: 'Add Plan',
                color: AssetFlowColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Plans list
          _plans.isEmpty
              ? _buildEmptyPlansMessage()
              : Column(
                  children: _plans.map((plan) => _buildPlanCard(plan)).toList(),
                ),
        ],
      ),
    );
  }

  /// Build a message when no plans are available
  Widget _buildEmptyPlansMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: AssetFlowColors.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          const Text(
            'No investment plans yet',
            style: TextStyle(
              fontSize: 16,
              color: AssetFlowColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addPlan,
            icon: const Icon(Icons.add),
            label: const Text('Add a Plan'),
            style: TextButton.styleFrom(
              foregroundColor: AssetFlowColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a card for a single plan
  Widget _buildPlanCard(Plan plan) {
    String paymentSchedule = '';
    switch (plan.paymentDistribution) {
      case PaymentDistribution.quarterly:
        paymentSchedule = 'Quarterly payments';
        break;
      case PaymentDistribution.halfYearly:
        paymentSchedule = 'Half-yearly payments';
        break;
      case PaymentDistribution.annual:
        paymentSchedule = 'Annual payments';
        break;
      case PaymentDistribution.exit:
        paymentSchedule = 'Payment at exit';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: plan.isSelected
              ? AssetFlowColors.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan type and selected indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(
                      AssetFlowColors.getParticipationTypeColor(
                        plan.participationType.displayName,
                      ).red,
                      AssetFlowColors.getParticipationTypeColor(
                        plan.participationType.displayName,
                      ).green,
                      AssetFlowColors.getParticipationTypeColor(
                        plan.participationType.displayName,
                      ).blue,
                      0.1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plan.participationType.displayName,
                    style: TextStyle(
                      color: AssetFlowColors.getParticipationTypeColor(
                        plan.participationType.displayName,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (plan.isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(
                        AssetFlowColors.success.red,
                        AssetFlowColors.success.green,
                        AssetFlowColors.success.blue,
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AssetFlowColors.success,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Selected',
                          style: TextStyle(
                            color: AssetFlowColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Plan details
            _buildPlanDetail(
              label: 'Minimum Investment',
              value: FormatterUtil.formatCurrency(plan.minimalAmount),
            ),
            _buildPlanDetail(
              label: 'Annual Interest Rate',
              value: '${plan.annualInterest.toStringAsFixed(2)}%',
            ),
            _buildPlanDetail(
              label: 'Length',
              value: '${plan.lengthMonths} months',
            ),
            _buildPlanDetail(
              label: 'Payment Schedule',
              value: paymentSchedule,
            ),
            if (plan.paymentDistribution != PaymentDistribution.exit)
              _buildPlanDetail(
                label: 'Exit Interest',
                value: '${plan.exitInterest.toStringAsFixed(2)}%',
              ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Select button
                TextButton.icon(
                  onPressed: plan.isSelected
                      ? null
                      : () => _selectPlan(plan),
                  icon: const Icon(Icons.check),
                  label: const Text('Select'),
                  style: TextButton.styleFrom(
                    foregroundColor: plan.isSelected
                        ? AssetFlowColors.textDisabled
                        : AssetFlowColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPlan(plan),
                  tooltip: 'Edit Plan',
                  color: AssetFlowColors.textSecondary,
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeletePlan(plan),
                  tooltip: 'Delete Plan',
                  color: AssetFlowColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a plan detail item with label and value
  Widget _buildPlanDetail({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AssetFlowColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AssetFlowColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Edit the project
  void _editProject() {
    _logger.info('Edit project button pressed: ${widget.projectId}');
    // TODO: Navigate to edit project screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit project feature coming soon')),
    );
  }

  /// Confirm project deletion
  void _confirmDeleteProject() {
    _logger.info('Delete project confirmation requested: ${widget.projectId}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment'),
        content: Text(
          'Are you sure you want to delete "${_project.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProject();
            },
            style: TextButton.styleFrom(
              foregroundColor: AssetFlowColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Delete the project
  Future<void> _deleteProject() async {
    _logger.info('Deleting project: ${widget.projectId}');
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.deleteProject(widget.projectId);
      _logger.info('Project deleted successfully');
      
      if (mounted) {
        Navigator.of(context).pop(); // Return to list screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment deleted successfully')),
        );
      }
    } catch (e) {
      _logger.severe('Error deleting project: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting project: $e')),
        );
      }
    }
  }

  /// Add a new plan
  void _addPlan() {
    _logger.info('Add plan button pressed');
    // TODO: Navigate to add plan screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add plan feature coming soon')),
    );
  }

  /// Edit a plan
  void _editPlan(Plan plan) {
    _logger.info('Edit plan button pressed: ${plan.id}');
    // TODO: Navigate to edit plan screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit plan feature coming soon')),
    );
  }

  /// Select a plan
  Future<void> _selectPlan(Plan plan) async {
    _logger.info('Select plan button pressed: ${plan.id}');
    setState(() {
      _isLoading = true;
    });

    try {
      // Update all plans to be not selected
      for (final p in _plans) {
        if (p.isSelected) {
          await _databaseService.updatePlan(
            _project.id,
            p.id,
            {'isSelected': false},
          );
        }
      }

      // Set the selected plan
      await _databaseService.updatePlan(
        _project.id,
        plan.id,
        {'isSelected': true},
      );

      _logger.info('Plan selected successfully');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan selected successfully')),
        );
      }
    } catch (e) {
      _logger.severe('Error selecting plan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting plan: $e')),
        );
      }
    }
  }

  /// Confirm plan deletion
  void _confirmDeletePlan(Plan plan) {
    _logger.info('Delete plan confirmation requested: ${plan.id}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Are you sure you want to delete this ${plan.participationType.displayName} plan? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePlan(plan);
            },
            style: TextButton.styleFrom(
              foregroundColor: AssetFlowColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Delete a plan
  Future<void> _deletePlan(Plan plan) async {
    _logger.info('Deleting plan: ${plan.id}');
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.deletePlan(_project.id, plan.id);
      _logger.info('Plan deleted successfully');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan deleted successfully')),
        );
      }
    } catch (e) {
      _logger.severe('Error deleting plan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting plan: $e')),
        );
      }
    }
  }
}