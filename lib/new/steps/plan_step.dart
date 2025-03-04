import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../../models/plan.dart';
import '../../utils/theme_colors.dart';
import '../../utils/formatter_util.dart';

/// Second step of the investment wizard for managing investment plans
class PlanStep extends StatefulWidget {
  final String projectId;
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
  void initState() {
    super.initState();
    _logger.info('PlanStep initialized with ${widget.plans.length} plans');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step title
          Text(
            'Investment Plans',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AssetFlowColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Step description
          Text(
            'Add one or more investment plans for this project.',
            style: TextStyle(
              fontSize: 16,
              color: AssetFlowColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Add plan button
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
                ? _buildEmptyPlansMessage()
                : _buildPlansList(),
          ),
        ],
      ),
    );
  }

  /// Show a message when no plans are available
  Widget _buildEmptyPlansMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 64,
            color: AssetFlowColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Plans Added Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AssetFlowColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the "Add Plan" button to create your first investment plan.',
            style: TextStyle(
              fontSize: 16,
              color: AssetFlowColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build the list of plans
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
    final isSelected = plan.id == widget.selectedPlan?.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AssetFlowColors.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => widget.onPlanSelected(plan),
        borderRadius: BorderRadius.circular(12),
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
                      color: AssetFlowColors.getParticipationTypeColor(
                        plan.participationType.displayName,
                      ).withOpacity(0.1),
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
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AssetFlowColors.success.withOpacity(0.1),
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
                label: 'Payment Distribution',
                value: plan.paymentDistribution.displayName,
              ),
              if (plan.paymentDistribution != PaymentDistribution.exit)
                _buildPlanDetail(
                  label: 'Exit Interest',
                  value: '${plan.exitInterest.toStringAsFixed(2)}%',
                ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Radio button for selection
                  Row(
                    children: [
                      Radio<String>(
                        value: plan.id,
                        groupValue: widget.selectedPlan?.id ?? '',
                        onChanged: (_) => widget.onPlanSelected(plan),
                        activeColor: AssetFlowColors.primary,
                      ),
                      const Text('Select'),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditPlanDialog(plan),
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
      ),
    );
  }

  /// Build a plan detail row
  Widget _buildPlanDetail({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
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

  /// Show dialog to add a new plan
  void _showAddPlanDialog() {
    _logger.info('Add plan dialog requested');
    
    // Create a new plan with default values
    final newPlan = Plan.create(
      projectId: widget.projectId,
      participationType: ParticipationType.limitedPartner,
      minimalAmount: 10000,
      lengthMonths: widget.projectLength,
      annualInterest: 10.0,
      paymentDistribution: PaymentDistribution.quarterly,
      exitInterest: 5.0,
    );
    
    _showPlanDialog(
      title: 'Add Investment Plan',
      plan: newPlan,
      onSave: widget.onPlanAdded,
    );
  }

  /// Show dialog to edit an existing plan
  void _showEditPlanDialog(Plan plan) {
    _logger.info('Edit plan dialog requested for plan: ${plan.id}');
    
    _showPlanDialog(
      title: 'Edit Investment Plan',
      plan: plan,
      onSave: widget.onPlanUpdated,
    );
  }

  /// Show dialog for adding or editing a plan
  void _showPlanDialog({
    required String title,
    required Plan plan,
    required Function(Plan) onSave,
  }) {
    showDialog(
      context: context,
      builder: (context) => PlanFormDialog(
        title: title,
        plan: plan,
        projectLength: widget.projectLength,
        onSave: onSave,
      ),
    );
  }

  /// Confirm plan deletion
  void _confirmDeletePlan(Plan plan) {
    _logger.info('Delete plan confirmation requested: ${plan.id}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Are you sure you want to delete this ${plan.participationType.displayName} plan?',
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
              widget.onPlanDeleted(plan);
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
}

/// Dialog for adding or editing an investment plan
class PlanFormDialog extends StatefulWidget {
  final String title;
  final Plan plan;
  final int projectLength;
  final Function(Plan) onSave;

  const PlanFormDialog({
    super.key,
    required this.title,
    required this.plan,
    required this.projectLength,
    required this.onSave,
  });

  @override
  _PlanFormDialogState createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<PlanFormDialog> {
  static final Logger _logger = Logger('PlanFormDialog');
  final _formKey = GlobalKey<FormState>();
  
  late ParticipationType _participationType;
  late double _minimalAmount;
  late int _lengthMonths;
  late double _annualInterest;
  late PaymentDistribution _paymentDistribution;
  late double _exitInterest;

  @override
  void initState() {
    super.initState();
    _logger.info('PlanFormDialog initialized');
    
    // Initialize form values from the plan
    _participationType = widget.plan.participationType;
    _minimalAmount = widget.plan.minimalAmount;
    _lengthMonths = widget.plan.lengthMonths;
    _annualInterest = widget.plan.annualInterest;
    _paymentDistribution = widget.plan.paymentDistribution;
    _exitInterest = widget.plan.exitInterest;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Participation type dropdown
              DropdownButtonFormField<ParticipationType>(
                value: _participationType,
                decoration: const InputDecoration(
                  labelText: 'Participation Type',
                  border: OutlineInputBorder(),
                ),
                items: ParticipationType.values.map((type) {
                  return DropdownMenuItem<ParticipationType>(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _participationType = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a participation type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Minimal amount field
              TextFormField(
                initialValue: _minimalAmount.toString(),
                decoration: const InputDecoration(
                  labelText: 'Minimal Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the minimal amount';
                  }
                  
                  try {
                    final amount = double.parse(value);
                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  
                  return null;
                },
                onChanged: (value) {
                  try {
                    _minimalAmount = double.parse(value);
                  } catch (e) {
                    // Handle parsing error
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Length field
              TextFormField(
                initialValue: _lengthMonths.toString(),
                decoration: InputDecoration(
                  labelText: 'Length (months)',
                  border: const OutlineInputBorder(),
                  helperText: 'Default from project: ${widget.projectLength} months',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the length';
                  }
                  
                  try {
                    final months = int.parse(value);
                    if (months <= 0) {
                      return 'Length must be greater than 0';
                    }
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  
                  return null;
                },
                onChanged: (value) {
                  try {
                    _lengthMonths = int.parse(value);
                  } catch (e) {
                    // Handle parsing error
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Annual interest field
              TextFormField(
                initialValue: _annualInterest.toString(),
                decoration: const InputDecoration(
                  labelText: 'Annual Interest (%)',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the annual interest';
                  }
                  
                  try {
                    final interest = double.parse(value);
                    if (interest < 0) {
                      return 'Interest cannot be negative';
                    }
                    if (interest > 100) {
                      return 'Interest cannot exceed 100%';
                    }
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  
                  return null;
                },
                onChanged: (value) {
                  try {
                    _annualInterest = double.parse(value);
                  } catch (e) {
                    // Handle parsing error
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Payment distribution dropdown
              DropdownButtonFormField<PaymentDistribution>(
                value: _paymentDistribution,
                decoration: const InputDecoration(
                  labelText: 'Payment Distribution',
                  border: OutlineInputBorder(),
                ),
                items: PaymentDistribution.values.map((type) {
                  return DropdownMenuItem<PaymentDistribution>(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _paymentDistribution = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a payment distribution';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Exit interest field (only for non-exit distributions)
              if (_paymentDistribution != PaymentDistribution.exit)
                TextFormField(
                  initialValue: _exitInterest.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Exit Interest (%)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                    helperText: 'Additional interest paid at project exit',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the exit interest';
                    }
                    
                    try {
                      final interest = double.parse(value);
                      if (interest < 0) {
                        return 'Interest cannot be negative';
                      }
                      if (interest > 100) {
                        return 'Interest cannot exceed 100%';
                      }
                    } catch (e) {
                      return 'Please enter a valid number';
                    }
                    
                    return null;
                  },
                  onChanged: (value) {
                    try {
                      _exitInterest = double.parse(value);
                    } catch (e) {
                      // Handle parsing error
                    }
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _savePlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: AssetFlowColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  /// Save the plan and close the dialog
  void _savePlan() {
    if (_formKey.currentState?.validate() ?? false) {
      _logger.info('Saving plan');
      
      // Create updated plan with form values
      final updatedPlan = widget.plan.copyWith(
        participationType: _participationType,
        minimalAmount: _minimalAmount,
        lengthMonths: _lengthMonths,
        annualInterest: _annualInterest,
        paymentDistribution: _paymentDistribution,
        exitInterest: _exitInterest,
      );
      
      widget.onSave(updatedPlan);
      Navigator.of(context).pop();
    }
  }
}