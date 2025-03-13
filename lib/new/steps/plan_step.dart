import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../models/plan.dart';
import '../../utils/theme_colors.dart';
import '../../utils/formatter_util.dart';
import '../../list/plan_form_dialog.dart';

import '../../models/project.dart';

/// Widget for the Plan step in the add investment wizard
class PlanStep extends StatefulWidget {
  final String projectId;
  final Project project;
  final int projectLength;
  final List<Plan> plans;
  final Plan? selectedPlan;
  final Function(Plan) onPlanAdded;
  final Function(Plan) onPlanUpdated;
  final Function(Plan) onPlanDeleted;
  final Function(Plan) onPlanSelected;

  const PlanStep({
    super.key,
    required this.projectId,
    required this.project,
    required this.projectLength,
    required this.plans,
    required this.selectedPlan,
    required this.onPlanAdded,
    required this.onPlanUpdated,
    required this.onPlanDeleted,
    required this.onPlanSelected,
  });

  @override
  _PlanStepState createState() => _PlanStepState();
}

class _PlanStepState extends State<PlanStep> {
  static final Logger _logger = Logger('PlanStep');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Investment Plans',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AssetFlowColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Add or select investment plans for this project',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AssetFlowColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Add Plan button
          ElevatedButton.icon(
            onPressed: _showAddPlanDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AssetFlowColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Plans list
          Expanded(
            child: widget.plans.isEmpty
                ? _buildEmptyState()
                : _buildPlansList(),
          ),
        ],
      ),
    );
  }

  /// Build the empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: AssetFlowColors.textSecondary.withOpacity(0.3),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'No Investment Plans',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AssetFlowColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Add your first investment plan to continue',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AssetFlowColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build the plans list
  Widget _buildPlansList() {
    return ListView.builder(
      itemCount: widget.plans.length,
      itemBuilder: (context, index) {
        final plan = widget.plans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  /// Build a card for a single plan
  Widget _buildPlanCard(Plan plan) {
    final isSelected = widget.selectedPlan?.id == plan.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? AssetFlowColors.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => widget.onPlanSelected(plan),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AssetFlowColors.getParticipationTypeColor(
                    plan.participationTypeName,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  plan.participationTypeName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AssetFlowColors.getParticipationTypeColor(
                      plan.participationTypeName,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Plan name and options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Plan name
                  Expanded(
                    child: Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AssetFlowColors.success,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Selected indicator
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AssetFlowColors.success,
                      size: 24,
                    ),
                  
                  // Edit and delete options
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showEditPlanDialog(plan),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outlined, size: 20),
                        onPressed: () => _confirmDeletePlan(plan),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Plan details
              Column(
                children: [
                  // Interest rate
                  _buildDetailRow(
                    'Interest Rate:',
                    '${(plan.interestRate * 100).toStringAsFixed(1)}%',
                  ),
                  
                  // Minimal investment
                  _buildDetailRow(
                    'Minimal Investment:',
                    FormatterUtil.formatCurrency(plan.minimalAmount),
                  ),
                  
                  // Payment distribution
                  _buildDetailRow(
                    'Payment Distribution:',
                    plan.paymentDistributionName,
                  ),
                  
                  // Estimated payments (if applicable)
                  if (plan.paymentDistribution != PaymentDistribution.exit)
                    _buildDetailRow(
                      'Estimated Payments:',
                      _getEstimatedPayments(plan),
                    ),
                ],
              ),
              
              // Description (if available)
              if (plan.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  plan.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AssetFlowColors.textSecondary,
                  ),
                ),
              ],
              
              // Selection indicator and button
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  width: double.infinity,
                  child: const Text(
                    'Selected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AssetFlowColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => widget.onPlanSelected(plan),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AssetFlowColors.primary,
                      side: const BorderSide(color: AssetFlowColors.primary),
                    ),
                    child: const Text('Select This Plan'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a detail row with label and value
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AssetFlowColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AssetFlowColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate the estimated number of payments based on payment distribution
  String _getEstimatedPayments(Plan plan) {
    int paymentsPerYear;
    
    switch (plan.paymentDistribution) {
      case PaymentDistribution.monthly:
        paymentsPerYear = 12;
        break;
      case PaymentDistribution.quarterly:
        paymentsPerYear = 4;
        break;
      case PaymentDistribution.semiannual:
        paymentsPerYear = 2;
        break;
      case PaymentDistribution.annual:
        paymentsPerYear = 1;
        break;
      case PaymentDistribution.exit:
        return 'At exit only';
    }
    
    final projectYears = widget.projectLength / 12;
    final totalPayments = (projectYears * paymentsPerYear).ceil();
    
    return '$totalPayments payment${totalPayments == 1 ? '' : 's'}';
  }

  /// Show the dialog to add a new plan
  void _showAddPlanDialog() {
    _logger.info('Showing add plan dialog');
    
    // Create a new plan with default values
    final newPlan = Plan.create(
      projectId: widget.projectId,
      name: '', // Empty name will auto-generate based on type and rate
      participationType: ParticipationType.limitedPartner,
      annualInterest: 7.5, // 7.5%
      minimalAmount: 25000,
      paymentDistribution: PaymentDistribution.quarterly,
      lengthMonths: widget.projectLength,
    );
    
    _showPlanDialog(
      plan: newPlan,
      onSave: widget.onPlanAdded,
    );
  }

  /// Show the dialog to edit an existing plan
  void _showEditPlanDialog(Plan plan) {
    _logger.info('Showing edit plan dialog');
    
    _showPlanDialog(
      plan: plan,
      onSave: widget.onPlanUpdated,
    );
  }

  /// Show the plan form dialog
  void _showPlanDialog({
    required Plan plan,
    required Function(Plan) onSave,
  }) {
    showDialog(
        context: context,
        builder: (context) => PlanFormDialog(
          title: plan.id.isEmpty ? 'Add Plan' : 'Edit Plan',
          plan: plan,
          project: widget.project,
          projectLength: widget.projectLength,
          onSave: onSave,
        ),
    );
  }

  /// Show confirmation dialog before deleting a plan
  void _confirmDeletePlan(Plan plan) {
    _logger.info('Showing delete plan confirmation');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AssetFlowColors.error,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onPlanDeleted(plan);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}